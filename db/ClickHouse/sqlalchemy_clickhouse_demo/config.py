# ClickHouse Local模式的数据库配置
# ClickHouse Local模式无需服务器，使用本地文件
import os

# 选择数据库模式：可以是 'clickhouse-local', 'chdb' 或 'server'
# 注意：chdb目前仅支持macOS和Linux，Windows用户应使用'clickhouse-local'模式
import sys
DATABASE_MODE = 'clickhouse-local' if sys.platform in ['win32', 'cygwin'] else 'chdb'  # Windows上使用clickhouse-local模式，其他平台使用chdb
CLICKHOUSE_LOCAL_MODE = DATABASE_MODE == 'clickhouse-local'
CHDB_MODE = DATABASE_MODE == 'chdb'

LOCAL_DATA_PATH = os.path.abspath('./clickhouse_local_data')  # 本地数据目录

# 为SQLAlchemy兼容性，我们将为本地操作使用特殊URL
# 注意：实际的本地操作通常使用clickhouse-local命令
if CHDB_MODE:
    DATABASE_URL = 'chdb://:memory:'  # 使用chdb内存模式
else:
    DATABASE_URL = f'clickhouse+local://default@{LOCAL_DATA_PATH}/default'

# 用于基于文件操作的设置
LOCAL_DB_FILE = 'clickhouse_local.db'
LOCAL_TEMP_DIR = './temp'