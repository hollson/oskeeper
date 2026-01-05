# ClickHouse Local模式的数据库配置
# ClickHouse Local模式无需服务器，使用本地文件
import os

# 选择数据库模式：固定使用 'chdb' 模式以支持文件数据库功能
import sys
DATABASE_MODE = 'chdb'  # 固定使用chdb模式以支持文件数据库
CLICKHOUSE_LOCAL_MODE = False  # 不再使用clickhouse-local命令行模式
CHDB_MODE = DATABASE_MODE == 'chdb'

LOCAL_DATA_PATH = os.path.abspath('.')  # 本地数据目录

# 为SQLAlchemy兼容性，我们将为本地操作使用特殊URL
# 现在专门使用chdb的文件数据库模式
if CHDB_MODE:
    # 使用文件数据库路径，而不是内存模式
    DATABASE_URL = f'chdb:///{os.path.join(LOCAL_DATA_PATH, "master.chdb")}'
else:
    DATABASE_URL = f'clickhouse+local://default@{LOCAL_DATA_PATH}/default'

# 用于基于文件操作的设置
LOCAL_DB_FILE = os.path.join(LOCAL_DATA_PATH, 'master.chdb')
LOCAL_TEMP_DIR = os.path.join(LOCAL_DATA_PATH, 'temp')

# 确保临时目录存在
os.makedirs(LOCAL_TEMP_DIR, exist_ok=True)

# 确保主数据库文件目录存在
os.makedirs(os.path.dirname(LOCAL_DB_FILE), exist_ok=True)
