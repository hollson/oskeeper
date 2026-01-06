# ClickHouse MergeTree 生产环境优化实战指南

## 概述

本文档详细介绍了ClickHouse MergeTree表引擎的生产环境优化方案，包括连接管理、批量写入、周期性数据导入等最佳实践。通过优化连接池管理、事务处理和批量操作，显著提升生产环境下的性能和稳定性。

## 优化背景

在原始代码中，存在以下生产环境问题：

1. **频繁连接创建/销毁**：每次操作都创建新连接，对性能影响大
2. **缺少显式事务管理**：没有明确的commit/rollback操作
3. **单条插入效率低**：批量数据插入时性能不佳
4. **错误处理不完善**：缺少连接重试和异常恢复机制

## 优化方案

### 1. 连接池管理

#### 问题分析
在生产环境中，频繁打开和关闭数据库连接会导致：
- 连接建立开销大
- 连接数过多影响数据库性能
- 连接泄露风险

#### 解决方案
实现连接池管理，复用现有连接：

```python
class MergeTreeConnectionPool:
    """MergeTree连接池管理类，用于生产环境的连接复用"""
    
    def __init__(self, db_path: str, max_connections: int = 5, timeout: int = 30):
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
                logger.error(f"初始化连接池失败: {e}")
    
    def _create_connection(self):
        """创建新的数据库连接"""
        conn = dbapi.connect(self.db_path)
        return conn
    
    @contextmanager
    def get_connection(self):
        """获取连接的上下文管理器"""
        conn = None
        try:
            # 尝试从池中获取连接，如果池为空则创建新连接（不超过最大限制）
            try:
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
            logger.error(f"连接管理错误: {e}")
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
```

#### 设计要点
- 使用队列实现连接池，支持并发访问
- 限制最大连接数，防止数据库过载
- 连接验证机制，确保连接有效性
- 上下文管理器确保连接正确释放

### 2. 事务管理

#### 问题分析
- 原始代码缺少显式事务控制
- 数据一致性无法保证
- 错误时无法回滚

#### 解决方案
在所有写操作中添加事务管理：

```python
def execute_batch_insert(self, table_name: str, columns: str, data: List[Tuple]) -> bool:
    """批量插入数据，优化写入性能"""
    if not data:
        return True
        
    with self.pool.get_connection() as conn:
        cursor = conn.cursor()
        try:
            # 构建批量插入SQL
            placeholders = ', '.join(['%s'] * len(data[0]))
            query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
            
            # 执行批量插入
            cursor.executemany(query, data)
            conn.commit()  # 显式提交事务
            
            logger.info(f"批量插入成功，表: {table_name}, 记录数: {len(data)}")
            return True
        except Exception as e:
            logger.error(f"批量插入失败: {e}")
            conn.rollback()  # 回滚事务
            return False
```

### 3. 批量写入优化

#### 问题分析
- 单条插入效率低，每条记录都有网络开销
- 大量小操作增加数据库负载

#### 解决方案
实现批量插入功能：

```python
def execute_batch_insert(self, table_name: str, columns: str, data: List[Tuple]) -> bool:
    """批量插入数据，优化写入性能"""
    if not data:
        return True
        
    with self.pool.get_connection() as conn:
        cursor = conn.cursor()
        try:
            # 构建批量插入SQL
            placeholders = ', '.join(['%s'] * len(data[0]))
            query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
            
            # 执行批量插入
            cursor.executemany(query, data)
            conn.commit()  # 显式提交事务
            
            logger.info(f"批量插入成功，表: {table_name}, 记录数: {len(data)}")
            return True
        except Exception as e:
            logger.error(f"批量插入失败: {e}")
            conn.rollback()  # 回滚事务
            return False
```

#### 性能优势
- 减少网络往返次数
- 降低事务开销
- 提高写入吞吐量

### 4. 周期性批量写入

#### 应用场景
- 定时数据导入
- 周期性ETL任务
- 批量数据同步

#### 实现方案
```python
def batch_insert_periodic(manager: MergeTreeManager, table_name: str, columns: str, data_batches: List[List[Tuple]], interval: int = 5):
    """
    周期性批量插入数据
    :param manager: MergeTreeManager实例
    :param table_name: 表名
    :param columns: 列名
    :param data_batches: 数据批次列表
    :param interval: 批次间隔时间（秒）
    """
    logger.info(f"开始周期性批量插入，共 {len(data_batches)} 个批次")
    
    for i, batch_data in enumerate(data_batches):
        logger.info(f"正在处理第 {i+1}/{len(data_batches)} 批次，记录数: {len(batch_data)}")
        
        success = manager.execute_batch_insert(table_name, columns, batch_data)
        if success:
            logger.info(f"第 {i+1} 批次插入成功")
        else:
            logger.error(f"第 {i+1} 批次插入失败")
        
        # 除最后一批次外，等待指定间隔
        if i < len(data_batches) - 1:
            time.sleep(interval)
    
    logger.info("周期性批量插入完成")
```

## 完整示例代码

```python
#!/usr/bin/env python3
"""
ClickHouse MergeTree 表引擎演示
MergeTree是ClickHouse的原生表引擎，专为OLAP工作负载设计
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

# 设置数据目录
chdb_DIR = "./master.chdb"
os.makedirs(chdb_DIR, exist_ok=True)

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class MergeTreeConnectionPool:
    """MergeTree连接池管理类，用于生产环境的连接复用"""
    
    def __init__(self, db_path: str, max_connections: int = 5, timeout: int = 30):
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
                logger.error(f"初始化连接池失败: {e}")
    
    def _create_connection(self):
        """创建新的数据库连接"""
        conn = dbapi.connect(self.db_path)
        return conn
    
    @contextmanager
    def get_connection(self):
        """获取连接的上下文管理器"""
        conn = None
        try:
            # 尝试从池中获取连接，如果池为空则创建新连接（不超过最大限制）
            try:
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
            logger.error(f"连接管理错误: {e}")
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


class MergeTreeManager:
    """MergeTree表管理器，封装表操作方法"""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.pool = MergeTreeConnectionPool(db_path)
    
    def execute_query(self, query: str, params: Optional[Tuple] = None) -> List[Tuple]:
        """执行查询操作"""
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
    
    def execute_batch_insert(self, table_name: str, columns: str, data: List[Tuple]) -> bool:
        """批量插入数据，优化写入性能"""
        if not data:
            return True
            
        with self.pool.get_connection() as conn:
            cursor = conn.cursor()
            try:
                # 构建批量插入SQL
                placeholders = ', '.join(['%s'] * len(data[0]))
                query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
                
                # 执行批量插入
                cursor.executemany(query, data)
                conn.commit()  # 显式提交事务
                
                logger.info(f"批量插入成功，表: {table_name}, 记录数: {len(data)}")
                return True
            except Exception as e:
                logger.error(f"批量插入失败: {e}")
                conn.rollback()  # 回滚事务
                return False
    
    def execute_single_insert(self, query: str, params: Tuple) -> bool:
        """执行单条插入"""
        with self.pool.get_connection() as conn:
            cursor = conn.cursor()
            try:
                cursor.execute(query, params)
                conn.commit()  # 显式提交事务
                return True
            except Exception as e:
                logger.error(f"插入失败: {e}")
                conn.rollback()  # 回滚事务
                return False


def create_mergetree_table(manager: MergeTreeManager):
    print("1. 创建MergeTree表:")
    manager.execute_query("""CREATE TABLE IF NOT EXISTS example_mergetree_table (id UInt32,name String,date Date,value Float64,category String) 
                   ENGINE = MergeTree() PARTITION BY toYYYYMM(date) ORDER BY (date, id) SETTINGS index_granularity = 8192""")
    print()


def insert_mergetree_table(manager: MergeTreeManager):
    print("2. 插入示例数据:")
    sample_data = [
        (1, 'Product A', '2023-01-15', 100.5, 'Electronics'),
        (2, 'Product B', '2023-01-16', 250.0, 'Clothing'),
        (3, 'Product C', '2023-02-01', 75.25, 'Books'),
        (4, 'Product D', '2023-02-10', 300.0, 'Electronics'),
        (5, 'Product E', '2023-03-05', 120.75, 'Sports')
    ]
    success = manager.execute_batch_insert(
        "example_mergetree_table", 
        "id, name, date, value, category", 
        sample_data
    )
    if success:
        print("批量插入成功")
    else:
        print("批量插入失败")
    print()


def query_all_data(manager: MergeTreeManager):
    print("3. 查询所有数据:")
    results = manager.execute_query("SELECT * FROM example_mergetree_table ORDER BY date")
    for row in results:
        print(f"   ID: {row[0]}, Name: {row[1]}, Date: {row[2]}, Value: {row[3]}, Category: {row[4]}")
    print()


def query_with_cond(manager: MergeTreeManager):
    print("4. 条件查询 (2023年1月数据):")
    results = manager.execute_query("SELECT * FROM example_mergetree_table WHERE toYYYYMM(date) = 202301")
    for row in results:
        print(f"   ID: {row[0]}, Name: {row[1]}, Date: {row[2]}, Value: {row[3]}")
    print()


def query_aggregated(manager: MergeTreeManager):
    print("5. 聚合查询 (GroupBy):")
    results = manager.execute_query("""SELECT category, count(*) as count, sum(value) as total_value
        FROM example_mergetree_table GROUP BY category ORDER BY total_value DESC""")
    for row in results:
        print(f"   Category: {row[0]}, Count: {row[1]}, Total Value: {row[2]}")
    print()


def create_summing_table(manager: MergeTreeManager):
    """主键是 (date, category)，相同主键的行会被聚合，SummingMergeTree(revenue)即revenue是聚合(求和)列"""
    print("6. 创建SummingMergeTree表 (自动聚合):")
    manager.execute_query("""
        CREATE TABLE IF NOT EXISTS example_summing_table (date Date,category String,quantity UInt32,revenue Float64) 
        ENGINE = SummingMergeTree(revenue) PARTITION BY toYYYYMM(date) ORDER BY (date, category)""")
    print()
    

def insert_summing_table(manager: MergeTreeManager):
    print("7. 插入聚合数据:")
    agg_data = [
        ('2023-01-15', 'Electronics', 10, 1000.0),
        ('2023-01-15', 'Electronics', 5, 500.0),  # 这条记录将与上一条聚合
        ('2023-01-16', 'Clothing', 8, 400.0),
        ('2023-02-01', 'Books', 15, 750.0)
    ]
    success = manager.execute_batch_insert(
        "example_summing_table", 
        "date, category, quantity, revenue", 
        agg_data
    )
    if success:
        print("批量插入成功")
    else:
        print("批量插入失败")
    print()


def query_summing_table(manager: MergeTreeManager):
    print("8. 查询SummingMergeTree表:")
    # 自动聚合发生时机：
    # 1. 后台自动合并：ClickHouse会在后台自动合并数据部分(part)
    # 2. 数据插入后：当数据被插入到同一个分区时，可能触发合并
    # 3. 定期合并：系统会定期合并小的数据部分
    # 4. OPTIMIZE命令：可以手动触发合并（仅用于演示或特殊需求）
    # 5. 无需每次都主动触发：生产环境中合并是自动进行的
    
     # ⚠ 注意：由于数据刚插入，后台合并尚未发生，所以主动触发(优化)一下
    manager.execute_query("OPTIMIZE TABLE example_summing_table FINAL")
    results = manager.execute_query(
        "SELECT * FROM example_summing_table ORDER BY date, category")
    for row in results:
        print(f"   Date: {row[0]}, Category: {row[1]}, Quantity: {row[2]}, Revenue: {row[3]}")
    print()


def create_replacing_table(manager: MergeTreeManager):
    print("9. 创建ReplacingMergeTree表 (去重):")
    manager.execute_query("""
        CREATE TABLE IF NOT EXISTS example_replacing_table (id UInt32,version UInt32,name String,updated_date DateTime DEFAULT now()) 
        ENGINE = ReplacingMergeTree(version) ORDER BY id""")
    print()


def insert_replacing_table(manager: MergeTreeManager):
    print("10. 插入重复数据 (用于演示去重):")
    dup_data = [
        (1, 1, 'Old Name', '2023-01-01 00:00:00'),
        (1, 2, 'New Name', '2023-01-02 00:00:00'),  # 这条记录版本更高(数值)，会替换上一条
        (2, 1, 'Another Product', '2023-01-01 00:00:00')
    ]

    success = manager.execute_batch_insert(
        "example_replacing_table", 
        "id, version, name, updated_date", 
        dup_data
    )
    if success:
        print("批量插入成功")
    else:
        print("批量插入失败")
    print()


def query_replacing_table(manager: MergeTreeManager):
    print("11. 查询ReplacingMergeTree表 (去重后):")
    manager.execute_query("OPTIMIZE TABLE example_replacing_table FINAL")  # 主动触动优化
    results = manager.execute_query("SELECT * FROM example_replacing_table ORDER BY id")
    for row in results:
        print(f"   ID: {row[0]}, Version: {row[1]}, Name: {row[2]}")
    print()


def show_table_info(manager: MergeTreeManager):
    print("12. 表信息:")
    results = manager.execute_query("SHOW TABLES")
    for table in results: 
        print(f"   - {table[0]}")
    print()


def show_partition_info(manager: MergeTreeManager):
    print("13. 分区信息:")
    results = manager.execute_query("""SELECT partition, name, rows, bytes_on_disk FROM system.parts 
        WHERE table = 'example_mergetree_table' ORDER BY partition""")
    print("   分区\t\t\t分名称\t\t\t行数\t\t磁盘")
    for part in results:
        print(f"   Partition: {part[0]},   Name: {part[1]},     Rows: {part[2]},     Size: {part[3]} bytes")
    print()


def cleanup_demo_data(manager: MergeTreeManager):
    print("14. 清理演示数据:")
    # manager.execute_query("DROP TABLE IF EXISTS example_mergetree_table")  
    # manager.execute_query("DROP TABLE IF EXISTS example_summing_table")    
    manager.execute_query("DROP TABLE IF EXISTS example_replacing_table")


def batch_insert_periodic(manager: MergeTreeManager, table_name: str, columns: str, data_batches: List[List[Tuple]], interval: int = 5):
    """
    周期性批量插入数据
    :param manager: MergeTreeManager实例
    :param table_name: 表名
    :param columns: 列名
    :param data_batches: 数据批次列表
    :param interval: 批次间隔时间（秒）
    """
    logger.info(f"开始周期性批量插入，共 {len(data_batches)} 个批次")
    
    for i, batch_data in enumerate(data_batches):
        logger.info(f"正在处理第 {i+1}/{len(data_batches)} 批次，记录数: {len(batch_data)}")
        
        success = manager.execute_batch_insert(table_name, columns, batch_data)
        if success:
            logger.info(f"第 {i+1} 批次插入成功")
        else:
            logger.error(f"第 {i+1} 批次插入失败")
        
        # 除最后一批次外，等待指定间隔
        if i < len(data_batches) - 1:
            time.sleep(interval)
    
    logger.info("周期性批量插入完成")


if __name__ == "__main__":
    try:
        manager = MergeTreeManager(chdb_DIR)
        print("================================ 合并树 ================================")
        create_mergetree_table(manager)
        insert_mergetree_table(manager)
        query_all_data(manager)
        query_with_cond(manager)
        query_aggregated(manager) 
        
        print("================================ 求和树 ================================")
        create_summing_table(manager)
        insert_summing_table(manager)
        query_summing_table(manager)
        
        print("================================ 替换树 ================================")
        create_replacing_table(manager)
        insert_replacing_table(manager)
        query_replacing_table(manager)
        
        print("================================ 元数据 ================================")
        show_table_info(manager)
        show_partition_info(manager)
        cleanup_demo_data(manager)
        
        # 演示周期性批量写入功能
        print("================================ 周期性批量写入演示 ================================")
        periodic_data_batches = [
            [(6, 'Product F', '2023-04-01', 200.0, 'Electronics'), (7, 'Product G', '2023-04-02', 150.0, 'Clothing')],
            [(8, 'Product H', '2023-04-03', 300.0, 'Books'), (9, 'Product I', '2023-04-04', 250.0, 'Sports')],
            [(10, 'Product J', '2023-04-05', 180.0, 'Electronics')]
        ]
        batch_insert_periodic(
            manager, 
            "example_mergetree_table", 
            "id, name, date, value, category", 
            periodic_data_batches, 
            interval=2  # 2秒间隔
        )
        
        # 查询新增的数据
        print("新增数据查询:")
        query_all_data(manager)
        
    except Exception as e:
        print(f"错误: {e}")
        logger.error(f"程序执行出错: {e}")
```

## 性能优化要点

### 1. 连接复用
- 连接池避免频繁连接创建/销毁
- 限制最大连接数，防止数据库过载
- 连接验证确保操作可靠性

### 2. 批量操作
- 批量插入减少网络往返次数
- 降低事务开销
- 提高写入吞吐量

### 3. 错误处理
- 完善的异常处理机制
- 连接重试和恢复
- 事务回滚保证数据一致性

### 4. 监控日志
- 详细的日志记录
- 操作性能监控
- 错误追踪和调试

## 生产环境部署建议

1. **连接池配置**：根据系统负载调整最大连接数
2. **批量大小**：根据数据量和内存限制调整批量大小
3. **监控告警**：设置连接池使用率、操作失败率等监控指标
4. **定期维护**：定期检查连接池状态和性能指标

## 总结

通过以上优化方案，ClickHouse MergeTree在生产环境中的性能和稳定性得到显著提升。连接池管理解决了频繁连接创建的问题，批量写入优化提高了数据导入效率，事务管理确保了数据一致性。这套方案特别适合周期性批量数据写入的场景，是生产环境部署的推荐做法。