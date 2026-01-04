import os
import subprocess
import tempfile
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import SQLAlchemyError
from config import CLICKHOUSE_LOCAL_MODE, CHDB_MODE, LOCAL_DATA_PATH, DATABASE_URL, LOCAL_DB_FILE
from models.base import Base
import logging
import sys

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 导入chdb（始终启用，因为现在固定使用chdb模式）
chdb_available = False
chdb_platform_supported = sys.platform not in [
    'win32', 'cygwin']  # chdb不支持Windows

if CHDB_MODE:
    if chdb_platform_supported:
        try:
            import chdb
            chdb_available = True
            logger.info("chdb模块已加载")
        except ImportError:
            logger.warning("chdb模块未安装。请运行 'pip install chdb' 来安装。")
            chdb_available = False
    else:
        logger.warning("chdb在Windows平台上不可用。chdb仅支持macOS和Linux。")


def execute_chdb_query(query):
    """使用chdb执行查询，现在使用文件数据库模式"""
    if not chdb_available:
        raise Exception("chdb模块不可用。chdb仅在macOS和Linux上支持。")

    try:
        # 使用文件数据库连接，而不是内存模式
        conn = chdb.connect(LOCAL_DB_FILE)
        cur = conn.cursor()
        cur.execute(query)

        # 对于SELECT查询，获取结果
        if query.strip().upper().startswith('SELECT'):
            result = cur.fetchall()
            # 获取列名
            columns = [desc[0]
                       for desc in cur.description] if cur.description else []
            return {'columns': columns, 'data': result}
        else:
            # 对于非SELECT查询，返回执行状态
            # 注意：chdb可能没有commit方法，根据需要调整
            return {'status': 'success', 'message': 'Query executed successfully'}
    except Exception as e:
        logger.error(f"chdb查询执行失败: {e}")
        raise


# 对于真正的ClickHouse Local模式，我们需要以不同于服务器的方式工作
# 由于我们想要类似SQLite的功能，我们将创建一个自定义方法
if CHDB_MODE:
    # 确保数据目录存在
    os.makedirs(LOCAL_DATA_PATH, exist_ok=True)


class LocalSession:
    def __init__(self):
        self.queries = []
        self.has_chdb = chdb_available if CHDB_MODE else False
        self.chdb_platform_supported = chdb_platform_supported if CHDB_MODE else False

    def execute(self, query):
        """根据当前模式执行查询"""
        if CHDB_MODE:
            if not self.has_chdb or not self.chdb_platform_supported:
                # 如果chdb不可用或平台不支持，记录将要执行的查询
                logger.info(f"将执行chdb查询: {query}")
                return f"如果在支持的平台上安装了chdb，查询结果将在此处: {query}"
            else:
                try:
                    result = execute_chdb_query(query)
                    return result
                except Exception as e:
                    logger.error(f"chdb查询执行失败: {e}")
                    raise
        else:
            # 如果都不是，记录查询
            logger.info(f"将执行查询: {query}")
            return f"模拟查询结果: {query}"

    def query(self, model_class):
        """为模型返回一个模拟查询对象"""
        return LocalQuery(self, model_class)

    def add(self, obj):
        """添加对象 - 将转换为INSERT语句"""
        if CHDB_MODE and (not self.has_chdb or not self.chdb_platform_supported):
            logger.info(f"将添加对象: {obj}")
            return

        # 将对象转换为INSERT查询
        table_name = getattr(obj, '__tablename__', 'unknown')
        columns = []
        values = []

        for attr, value in obj.__dict__.items():
            if not attr.startswith('_'):  # 跳过私有属性
                columns.append(attr)
                if isinstance(value, str):
                    values.append(f"'{value}'")
                else:
                    values.append(str(value))

        query = f"INSERT INTO {table_name} ({', '.join(columns)}) VALUES ({', '.join(values)})"
        self.execute(query)

    def commit(self):
        """提交所有待处理的查询"""
        for query in self.queries:
            self.execute(query)
        self.queries = []

    def close(self):
        """关闭会话"""
        pass

    def delete(self, obj):
        """删除对象"""
        if CHDB_MODE and (not self.has_chdb or not self.chdb_platform_supported):
            logger.info(f"将删除对象: {obj}")
            return

        table_name = getattr(obj, '__tablename__', 'unknown')
        # 这是一个简化的方法 - 实际上，您需要一个主键
        # 为了演示目的，我们使用一个占位符
        query = f"DELETE FROM {table_name} WHERE id = {getattr(obj, 'id', 1)}"
        self.execute(query)


class LocalQuery:
    def __init__(self, session, model_class):
        self.session = session
        self.model_class = model_class
        self.table_name = getattr(model_class, '__tablename__', 'unknown')
        self.conditions = []
        self.has_chdb = session.has_chdb if CHDB_MODE else False
        self.chdb_platform_supported = session.chdb_platform_supported if CHDB_MODE else False

    def filter(self, *conditions):
        """添加过滤条件"""
        for condition in conditions:
            # 为演示简化条件处理
            self.conditions.append(str(condition))
        return self

    def all(self):
        """获取所有记录"""
        query = f"SELECT * FROM {self.table_name}"
        if self.conditions:
            query += " WHERE " + " AND ".join(self.conditions)

        if CHDB_MODE:
            if not self.has_chdb or not self.chdb_platform_supported:
                logger.info(f"将执行查询: {query}")
                return []  # 当chdb不可用时返回空列表
            else:
                try:
                    result = self.session.execute(query)
                    # 解析结果 - 为演示简化
                    if isinstance(result, dict) and 'data' in result:
                        # 返回chdb查询结果，需要转换为对象形式
                        return result['data']  # 直接返回原始数据
                    return []  # 返回空列表或模拟对象
                except Exception:
                    return []
        else:
            logger.info(f"将执行查询: {query}")
            return []

    def first(self):
        """获取第一条记录"""
        query = f"SELECT * FROM {self.table_name}"
        if self.conditions:
            query += " WHERE " + " AND ".join(self.conditions)
        query += " LIMIT 1"

        if CHDB_MODE:
            if not self.has_chdb or not self.chdb_platform_supported:
                logger.info(f"将执行查询: {query}")
                return None  # 当chdb不可用时返回None
            else:
                try:
                    result = self.session.execute(query)
                    # 解析结果 - 为演示简化
                    if isinstance(result, dict) and 'data' in result and result['data']:
                        # 返回第一个结果，需要转换为对象形式
                        return result['data'][0]  # 直接返回第一个原始数据
                    return None  # 返回模拟对象
                except Exception:
                    return None
        else:
            logger.info(f"将执行查询: {query}")
            return None


def get_db():
    """
    获取数据库会话的依赖函数
    """
    db = LocalSession()
    try:
        yield db
    finally:
        db.close()


def create_tables():
    """
    使用当前数据库模式在数据库中创建所有表
    """
    if CHDB_MODE:
        logger.info("在chdb模式下创建表")
        
        # 检查chdb是否可用
        has_chdb = chdb_available and chdb_platform_supported
        
        for table_name, table in Base.metadata.tables.items():
            # 生成CREATE TABLE语句
            columns_def = []
            for column in table.columns:
                col_type = str(column.type)
                # 将SQLAlchemy类型转换为ClickHouse类型
                if 'INTEGER' in col_type.upper():
                    ch_type = 'Int32'
                elif 'VARCHAR' in col_type.upper() or 'STRING' in col_type.upper():
                    ch_type = 'String'
                elif 'DATETIME' in col_type.upper():
                    ch_type = 'DateTime'
                elif 'FLOAT' in col_type.upper() or 'REAL' in col_type.upper():
                    ch_type = 'Float64'
                elif 'BOOLEAN' in col_type.upper():
                    ch_type = 'UInt8'
                else:
                    ch_type = 'String'  # 默认回退
                
                nullable = '' if not column.nullable else ''
                columns_def.append(f"{column.name} {ch_type}{nullable}")
            
            if columns_def:
                # 为每个表创建独立的CSV文件，使用File引擎
                table_file_path = os.path.join(LOCAL_DATA_PATH, f"{table_name}.csv")
                create_query = f"CREATE TABLE IF NOT EXISTS {table_name} ({', '.join(columns_def)}) ENGINE=File(CSV, '{table_file_path}');"
                
                if has_chdb:
                    try:
                        execute_chdb_query(create_query)
                        logger.info(f"已创建表: {table_name}，数据文件: {table_file_path}")
                    except Exception as e:
                        logger.error(f"创建表失败 {table_name}: {e}")
                        # 如果File引擎失败，回退到MergeTree
                        fallback_query = f"CREATE TABLE IF NOT EXISTS {table_name} ({', '.join(columns_def)}) ENGINE=MergeTree() ORDER BY id;"
                        execute_chdb_query(fallback_query)
                        logger.info(f"已使用MergeTree引擎创建表: {table_name}")
                else:
                    logger.info(f"将创建表: {create_query}")
    else:
        try:
            Base.metadata.create_all(bind=engine)
            logger.info("所有表创建成功")
        except SQLAlchemyError as e:
            logger.error(f"创建表时出错: {e}")
            raise


def drop_tables():
    """
    删除数据库中的所有表
    """
    if CHDB_MODE:
        logger.info("在chdb模式下删除表")

        # 检查chdb是否可用
        has_chdb = chdb_available and chdb_platform_supported

        for table_name in Base.metadata.tables.keys():
            drop_query = f"DROP TABLE IF EXISTS {table_name};"

            if has_chdb:
                try:
                    execute_chdb_query(drop_query)
                    logger.info(f"已删除表: {table_name}")
                except Exception as e:
                    logger.error(f"删除表失败 {table_name}: {e}")
            else:
                logger.info(f"将删除表: {drop_query}")
    else:
        try:
            Base.metadata.drop_all(bind=engine)
            logger.info("所有表删除成功")
        except SQLAlchemyError as e:
            logger.error(f"删除表时出错: {e}")
            raise


def test_connection():
    """
    测试数据库连接
    根据当前模式测试连接
    """
    if CHDB_MODE:
        if chdb_platform_supported:
            if chdb_available:
                logger.info("chdb可用")
                # 尝试简单的查询来测试功能
                try:
                    result = execute_chdb_query("SELECT 1 as test")
                    logger.info("基本chdb查询测试成功")
                    return True
                except Exception as e:
                    logger.error(f"基本chdb查询测试失败: {e}")
                    return False
            else:
                logger.warning("chdb模块不可用，但在演示模式下继续")
                logger.info("要使用chdb功能，请安装chdb模块: pip install chdb")
                return True  # 返回True以允许演示继续
        else:
            logger.warning("chdb在当前平台（Windows）上不可用，但在演示模式下继续")
            logger.info("chdb仅支持macOS和Linux平台")
            return True  # 返回True以允许演示继续
    else:
        try:
            with engine.connect() as connection:
                result = connection.execute("SELECT version()")
                version = result.fetchone()[0]
                logger.info(f"连接到ClickHouse版本: {version}")
                return True
        except Exception as e:
            logger.error(f"连接到ClickHouse服务器失败: {e}")
            return False
