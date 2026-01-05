import chdb
from chdb import dbapi
import os
import sys
import argparse

# ========== 1. 类SQLite：指定固定文件目录（替代SQLite单文件） ==========
# 自定义数据目录（持久化，重启后数据不丢失）
CHDB_DATA_DIR = "./master.chdb"
os.makedirs(CHDB_DATA_DIR, exist_ok=True)  # 创建目录（如果不存在）


def setup_database():
    """设置数据库表结构（仅创建表，不插入数据）"""
    # 建立连接
    conn = dbapi.connect(CHDB_DATA_DIR)
    cursor = conn.cursor()

    # 创建表
    create_sql = """
CREATE TABLE IF NOT EXISTS user_analytics (
    user_id UInt64,
    action String,
    event_time DateTime,
    pv UInt32
) ENGINE = ReplacingMergeTree  -- 生产级引擎（去重+排序）
ORDER BY (user_id, event_time)  -- 主键排序（优化查询）
SETTINGS index_granularity = 8192;  -- 索引粒度（默认即可）
"""
    cursor.execute(create_sql)

    # 关闭连接
    cursor.close()
    conn.close()

    print("数据库表结构创建完成")
    return None


def populate_sample_data():
    """插入示例数据"""
    conn = dbapi.connect(CHDB_DATA_DIR)
    cursor = conn.cursor()

    # 批量写入数据
    batch_data = [
        (1001, "click", "2024-05-01 10:00:00", 5),
        (1002, "view", "2024-05-01 10:01:00", 10),
        (1001, "click", "2024-05-01 10:02:00", 8),
    ]
    cursor.executemany(
        "INSERT INTO user_analytics VALUES (%s, %s, %s, %s)",
        batch_data
    )

    # 导出为Parquet文件
    parquet_path = os.path.join(CHDB_DATA_DIR, "user_analytics.parquet")
    # 先删除已存在的Parquet文件，避免追加错误
    if os.path.exists(parquet_path):
        os.remove(parquet_path)
    cursor.execute(f"""
    INSERT INTO FUNCTION file('{parquet_path}', Parquet)
    SELECT * FROM user_analytics;
""")

    # 关闭连接
    cursor.close()
    conn.close()

    print("示例数据插入完成")
    return parquet_path

# ========== 5. 高性能查询（类SQLite查询） ==========
# 示例1：基础聚合查询（chdb擅长的分析场景）


def query_aggregated_data():
    """聚合查询数据（类SQLite查询）"""
    conn = dbapi.connect(CHDB_DATA_DIR)
    cursor = conn.cursor()

    cursor.execute("""
    SELECT user_id, SUM(pv) as total_pv, COUNT(DISTINCT action) as action_count
    FROM user_analytics
    WHERE event_time >= '2024-05-01 00:00:00'
    GROUP BY user_id;
""")

    # 获取列名 + 转换为字典
    col_names = [desc[0] for desc in cursor.description]
    result = [dict(zip(col_names, row)) for row in cursor.fetchall()]
    print("聚合查询结果（类SQLite）：")
    for row in result:
        print(
            f"用户{row['user_id']}：总PV={row['total_pv']}，操作类型数={row['action_count']}")

    cursor.close()
    conn.close()

# 示例2：直接读取Parquet文件（无需建表，类SQLite直接读文件）


def query_parquet_data():
    """直接读取Parquet文件"""
    parquet_path = os.path.join(CHDB_DATA_DIR, "user_analytics.parquet")
    print("\n直接读取Parquet文件（生产级）：")

    # 使用dbapi连接查询Parquet文件，避免连接冲突
    conn = dbapi.connect(CHDB_DATA_DIR)
    cursor = conn.cursor()

    cursor.execute(
        f"SELECT * FROM file('{parquet_path}', Parquet) WHERE user_id = 1001")
    result = cursor.fetchall()
    col_names = [desc[0] for desc in cursor.description]
    print(f"列名: {col_names}")
    for row in result:
        print(row)

    cursor.close()
    conn.close()

# ========== 6. 关闭连接（类SQLite close） ==========


def verify_persistence():
    """重启后验证数据持久化"""
    print("\n重启后验证数据：")
    conn = dbapi.connect(CHDB_DATA_DIR)
    cursor = conn.cursor()
    cursor.execute("SELECT user_id, pv FROM user_analytics LIMIT 2;")
    print(cursor.fetchall())
    cursor.close()
    conn.close()


def show_help():
    """显示友好的帮助信息"""
    print('''ClickHouse数据库操作工具

操作选项 (不提供则显示此帮助):
  setup        创建数据库表结构（不插入数据）
  populate     插入示例数据
  aggregate    执行聚合查询
  parquet      查询Parquet文件
  persistence  验证数据持久化
  all          执行全部操作

使用示例:
  python main.py setup        # 创建数据库表结构
  python main.py populate     # 插入示例数据
  python main.py aggregate    # 执行聚合查询
  python main.py parquet      # 查询Parquet文件
  python main.py persistence  # 验证数据持久化
  python main.py all          # 执行全部操作
  python main.py              # 显示此帮助信息
    ''')


def main():
    # 创建解析器
    parser = argparse.ArgumentParser(
        prog='main.py', description='ClickHouse数据库操作工具')
    parser.add_argument('operation', nargs='?', default=None,
                        choices=['setup', 'populate', 'aggregate',
                                 'parquet', 'persistence', 'all'],
                        help='操作选项 (不提供则显示此帮助)')

    args = parser.parse_args()

    # 如果没有参数，显示帮助信息
    if args.operation is None:
        show_help()
        return

    if args.operation in ['all', 'setup']:
        print("设置数据库...")
        parquet_path = setup_database()

    if args.operation in ['all', 'populate']:
        print("插入示例数据...")
        parquet_path = populate_sample_data()

    if args.operation in ['all', 'aggregate']:
        query_aggregated_data()

    if args.operation in ['all', 'parquet']:
        query_parquet_data()

    if args.operation in ['all', 'persistence']:
        verify_persistence()


if __name__ == "__main__":
    main()
