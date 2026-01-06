#!/usr/bin/env python3
"""
chdb 通用辅助类库
包含 ChdbPool 连接池和 ChdbManager 表管理器
"""

import chdb
from chdb import dbapi
import os
import time
from contextlib import contextmanager
from typing import List, Tuple, Optional
import threading
import queue
import logging

# 自定义日志格式化器


class ColoredFormatter(logging.Formatter):
    """为不同日志级别添加不同图标和颜色的格式化器"""

    # 定义不同日志级别的图标
    level_icons = {
        logging.DEBUG: "🔍",       # 调试图标
        logging.INFO: "ℹ️ ",       # 消息图标
        logging.WARNING: "⚠️ ",    # 警告图标
        logging.ERROR: "❌",       # 错误图标
        logging.CRITICAL: "🚨"     # 危险图标
    }

    def format(self, record):
        # 根据日志级别获取对应图标
        icon = self.level_icons.get(record.levelno, "📝")  # 默认图标
        # 在日志消息前添加图标
        record.levelname_with_icon = f"{icon}"
        return super().format(record)

# 配置自定义日志格式


def setup_logging():
    """设置带图标的日志格式"""
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    # 检查是否已有处理器，避免重复添加
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = ColoredFormatter(
            #
            fmt='%(levelname_with_icon)s %(asctime)s %(levelname)s %(name)s %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)


# 设置日志
setup_logging()

logger = logging.getLogger(__name__)


class ChdbPool:
    """chdb 连接池管理类，用于生产环境的连接复用"""

    def __init__(self, db_path: str, max_connections: int = 10, timeout: int = 30):
        """
        初始化连接池
        
        Args:
            db_path: 数据库路径
            max_connections: 最大连接数
            timeout: 获取连接超时时间(秒)
        """
        self.db_path = db_path
        self.max_connections = max_connections
        self.timeout = timeout
        self.pool = queue.Queue(maxsize=max_connections)
        self.lock = threading.Lock()
        self.active_connections = 0

        # 预创建连接
        self._initialize_pool()

    def _initialize_pool(self):
        """初始化连接池"""
        for _ in range(self.max_connections):
            try:
                conn = self._create_connection()
                self.pool.put(conn)
            except Exception as e:
                logger.error(f"Failed to initialize connection pool: {e}")

    def _create_connection(self):
        """创建新的数据库连接"""
        conn = dbapi.connect(self.db_path)
        return conn

    @contextmanager
    def get_connection(self):
        """获取连接的上下文管理器"""
        conn = None
        try:
            try:
                # 尝试从池中获取连接
                conn = self.pool.get(timeout=self.timeout)
            except queue.Empty:
                with self.lock:
                    if self.active_connections < self.max_connections:
                        conn = self._create_connection()
                        self.active_connections += 1
                    else:
                        # 如果已达到最大连接数，等待可用连接
                        conn = self.pool.get(timeout=self.timeout)

            # 测试连接是否有效
            if not self._is_connection_valid(conn):
                conn = self._create_connection()

            yield conn

        except Exception as e:
            logger.error(f"Connection management error: {e}")
            raise
        finally:
            if conn:
                try:
                    # 将连接返回池中
                    self.pool.put(conn, timeout=1)
                except queue.Full:
                    # 如果池已满，关闭连接
                    conn.close()
                    with self.lock:
                        self.active_connections -= 1

    def _is_connection_valid(self, conn):
        """检查连接是否有效"""
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            return True
        except:
            return False


class ChdbManager:
    """chdb 表管理器，封装通用的表操作方法"""

    def __init__(self, db_path: str):
        """
        初始化管理器
        
        Args:
            db_path: 数据库路径
        """
        self.db_path = db_path
        self.pool = ChdbPool(db_path)

    def execute(self, query: str, params: Optional[Tuple] = None) -> List[Tuple]:
        """
        执行查询操作
        
        Args:
            query: SQL查询语句
            params: 查询参数
            
        Returns:
            查询结果列表
        """
        with self.pool.get_connection() as conn:
            cursor = conn.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)

            # 对于SELECT查询，返回结果
            if query.strip().upper().startswith('SELECT'):
                return cursor.fetchall()
            return []

    def insert_batch(self, table_name: str, columns: str, data: List[Tuple]) -> bool:
        """
        执行批量插入
        
        Args:
            table_name: 表名
            columns: 列名字符串，如 "id, name, value"
            data: 数据列表，每个元素是一个元组
            
        Returns:
            是否成功
        """
        if not data:
            logger.warning("No data to insert")
            return True

        placeholders = ', '.join(['?' for _ in columns.split(',')])
        query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"

        with self.pool.get_connection() as conn:
            cursor = conn.cursor()
            try:
                cursor.executemany(query, data)
                conn.commit()  # 显式提交事务
                logger.info(
                    f"Batch insert successful, total records: {len(data)}")
                return True
            except Exception as e:
                logger.error(f"Batch insert failed: {e}")
                conn.rollback()  # 回滚事务
                return False

    def insert(self, query: str, params: Tuple) -> bool:
        """
        执行单条插入
        
        Args:
            query: SQL插入语句
            params: 参数元组
            
        Returns:
            是否成功
        """
        with self.pool.get_connection() as conn:
            cursor = conn.cursor()
            try:
                cursor.execute(query, params)
                conn.commit()  # 显式提交事务
                return True
            except Exception as e:
                logger.error(f"Insert failed: {e}")
                conn.rollback()  # 回滚事务
                return False


def chdb_check(manager: ChdbManager) -> bool:
    """测试数据库连接"""
    try:
        result = manager.execute("SELECT 1")
        return len(result) > 0
    except Exception as e:
        return False
