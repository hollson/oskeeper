# ClickHouse Local模式的数据库配置
# ClickHouse Local模式无需服务器，使用本地文件
import os

# 对于真正的ClickHouse Local模式，我们不连接到服务器
# 而是直接使用本地文件
CLICKHOUSE_LOCAL_MODE = True
LOCAL_DATA_PATH = os.path.abspath('./clickhouse_local_data')  # 本地数据目录

# 为SQLAlchemy兼容性，我们将为本地操作使用特殊URL
# 注意：实际的本地操作通常使用clickhouse-local命令
DATABASE_URL = f'clickhouse+local://default@{LOCAL_DATA_PATH}/default'

# 用于基于文件操作的设置
LOCAL_DB_FILE = 'clickhouse_local.db'
LOCAL_TEMP_DIR = './temp'