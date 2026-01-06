#!/usr/bin/env python3
"""
ClickHouse MergeTree 表引擎演示
MergeTree是ClickHouse的原生表引擎，专为OLAP工作负载设计
"""

import chdb
from chdb import dbapi
import os

# 设置数据目录(chdb会自动创建目录)
chdb_DIR = "./master.chdb"


def create_mergetree_table(client):
    print("1. 创建MergeTree表:")
    client.execute("""CREATE TABLE IF NOT EXISTS example_mergetree_table (id UInt32,name String,date Date,value Float64,category String) 
                   ENGINE = MergeTree() PARTITION BY toYYYYMM(date) ORDER BY (date, id) SETTINGS index_granularity = 8192""")
    print()


def insert_mergetree_table(client):
    print("2. 插入示例数据:")
    sample_data = [
        (1, 'Product A', '2023-01-15', 100.5, 'Electronics'),
        (2, 'Product B', '2023-01-16', 250.0, 'Clothing'),
        (3, 'Product C', '2023-02-01', 75.25, 'Books'),
        (4, 'Product D', '2023-02-10', 300.0, 'Electronics'),
        (5, 'Product E', '2023-03-05', 120.75, 'Sports')
    ]
    for record in sample_data:
        client.execute(
            "INSERT INTO example_mergetree_table VALUES (%s, %s, %s, %s, %s)", record)
    print()


def query_all_data(client):
    print("3. 查询所有数据:")
    client.execute("SELECT * FROM example_mergetree_table ORDER BY date")
    for row in client.fetchall():
        print(
            f"   ID: {row[0]}, Name: {row[1]}, Date: {row[2]}, Value: {row[3]}, Category: {row[4]}")
    print()


def query_with_cond(client):
    print("4. 条件查询 (2023年1月数据):")
    client.execute(
        "SELECT * FROM example_mergetree_table WHERE toYYYYMM(date) = 202301")
    for row in client.fetchall():
        print(
            f"   ID: {row[0]}, Name: {row[1]}, Date: {row[2]}, Value: {row[3]}")
    print()


def query_aggregated(client):
    print("5. 聚合查询 (GroupBy):")
    client.execute("""SELECT category, count(*) as count, sum(value) as total_value
        FROM example_mergetree_table GROUP BY category ORDER BY total_value DESC""")
    for row in client.fetchall():
        print(f"   Category: {row[0]}, Count: {row[1]}, Total Value: {row[2]}")
    print()


def create_summing_table(client):
    """主键是 (date, category)，相同主键的行会被聚合，SummingMergeTree(revenue)即revenue是聚合(求和)列"""
    print("6. 创建SummingMergeTree表 (自动聚合):")
    client.execute("""
        CREATE TABLE IF NOT EXISTS example_summing_table (date Date,category String,quantity UInt32,revenue Float64) 
        ENGINE = SummingMergeTree(revenue) PARTITION BY toYYYYMM(date) ORDER BY (date, category)""")
    print()


def insert_summing_table(client):
    print("7. 插入聚合数据:")
    agg_data = [
        ('2023-01-15', 'Electronics', 10, 1000.0),
        ('2023-01-15', 'Electronics', 5, 500.0),  # 这条记录将与上一条聚合
        ('2023-01-16', 'Clothing', 8, 400.0),
        ('2023-02-01', 'Books', 15, 750.0)
    ]
    for record in agg_data:
        client.execute(
            "INSERT INTO example_summing_table VALUES (%s, %s, %s, %s)", record)
    print()


def query_summing_table(client):
    print("8. 查询SummingMergeTree表:")
    # 自动聚合发生时机：
    # 1. 后台自动合并：ClickHouse会在后台自动合并数据部分(part)
    # 2. 数据插入后：当数据被插入到同一个分区时，可能触发合并
    # 3. 定期合并：系统会定期合并小的数据部分
    # 4. OPTIMIZE命令：可以手动触发合并（仅用于演示或特殊需求）
    # 5. 无需每次都主动触发：生产环境中合并是自动进行的

    # ⚠ 注意：由于数据刚插入，后台合并尚未发生，所以主动触发(优化)一下
    client.execute("OPTIMIZE TABLE example_summing_table FINAL")
    client.execute(
        "SELECT * FROM example_summing_table ORDER BY date, category")
    for row in client.fetchall():
        print(
            f"   Date: {row[0]}, Category: {row[1]}, Quantity: {row[2]}, Revenue: {row[3]}")
    print()


def create_replacing_table(client):
    print("9. 创建ReplacingMergeTree表 (去重):")
    client.execute("""
        CREATE TABLE IF NOT EXISTS example_replacing_table (id UInt32,version UInt32,name String,updated_date DateTime DEFAULT now()) 
        ENGINE = ReplacingMergeTree(version) ORDER BY id""")
    print()


def insert_replacing_table(client):
    print("10. 插入重复数据 (用于演示去重):")
    dup_data = [
        (1, 1, 'Old Name', '2023-01-01 00:00:00'),
        (1, 2, 'New Name', '2023-01-02 00:00:00'),  # 这条记录版本更高(数值)，会替换上一条
        (2, 1, 'Another Product', '2023-01-01 00:00:00')
    ]

    for record in dup_data:
        client.execute(
            "INSERT INTO example_replacing_table VALUES (%s, %s, %s, %s)", record)
    print()


def query_replacing_table(client):
    print("11. 查询ReplacingMergeTree表 (去重后):")
    client.execute("OPTIMIZE TABLE example_replacing_table FINAL")  # 主动触动优化
    client.execute("SELECT * FROM example_replacing_table ORDER BY id")
    for row in client.fetchall():
        print(f"   ID: {row[0]}, Version: {row[1]}, Name: {row[2]}")
    print()


def show_table_info(client):
    print("12. 表信息:")
    client.execute("SHOW TABLES")
    for table in client.fetchall():
        print(f"   - {table[0]}")
    print()


def show_partition_info(client):
    print("13. 分区信息:")
    client.execute("""SELECT partition, name, rows, bytes_on_disk FROM system.parts 
        WHERE table = 'example_mergetree_table' ORDER BY partition""")
    print("   分区\t\t\t分名称\t\t\t行数\t\t磁盘")
    for part in client.fetchall():
        print(
            f"   Partition: {part[0]},   Name: {part[1]},     Rows: {part[2]},     Size: {part[3]} bytes")
    print()


def cleanup_demo_data(client):
    print("14. 清理演示数据:")
    # client.execute("DROP TABLE IF EXISTS example_mergetree_table")
    # client.execute("DROP TABLE IF EXISTS example_summing_table")
    client.execute("DROP TABLE IF EXISTS example_replacing_table")


if __name__ == "__main__":
    try:
        conn = dbapi.connect(chdb_DIR)
        client = conn.cursor()
        print("================================ 合并树 ================================")
        create_mergetree_table(client)
        insert_mergetree_table(client)
        query_all_data(client)
        query_with_cond(client)
        query_aggregated(client)

        print("================================ 求和树 ================================")
        create_summing_table(client)
        insert_summing_table(client)
        query_summing_table(client)

        print("================================ 替换树 ================================")
        create_replacing_table(client)
        insert_replacing_table(client)
        query_replacing_table(client)

        print("================================ 元数据 ================================")
        show_table_info(client)
        show_partition_info(client)
        cleanup_demo_data(client)

        print("================================ 生产篇 ================================")

        # 15. 使用TTL进行数据生命周期管理
        print("15. 稀疏处理 - TTL数据生命周期管理:")
        client.execute("""CREATE TABLE IF NOT EXISTS ttl_demo_table (
            id UInt32,
            name String,
            date Date,
            value Float64
        ) ENGINE = MergeTree()
        ORDER BY (date, id)
        TTL date + INTERVAL 30 DAY  -- 30天后自动删除数据
        SETTINGS index_granularity = 8192""")

        # 插入TTL测试数据
        ttl_data = [
            (1, 'TTL Data 1', '2023-01-01', 100.0),
            (2, 'TTL Data 2', '2025-12-31', 200.0)  # 这个日期较新，不会立即删除
        ]
        for record in ttl_data:
            client.execute(
                "INSERT INTO ttl_demo_table VALUES (%s, %s, %s, %s)", record)

        print("   TTL表创建成功，数据将在指定时间后自动删除")
        print()

        # 16. 过期删除 - 演示TTL查询
        print("16. 过期删除 - TTL数据查询:")
        client.execute("SELECT * FROM ttl_demo_table ORDER BY date")
        for row in client.fetchall():
            print(
                f"   ID: {row[0]}, Name: {row[1]}, Date: {row[2]}, Value: {row[3]}")
        print()

        # 17. 数据库操作 - 库大小分析
        print("17. 数据库操作 - 库大小分析:")
        client.execute("""SELECT 
            table,
            formatReadableSize(sum(bytes_on_disk)) AS size,
            sum(rows) AS rows,
            count() AS parts
        FROM system.parts 
        WHERE active AND database = 'default'
        GROUP BY table
        ORDER BY sum(bytes_on_disk) DESC""")
        for row in client.fetchall():
            print(
                f"   表名: {row[0]}, 大小: {row[1]}, 行数: {row[2]}, 分区数: {row[3]}")
        print()

        # 18. Parquet导入导出功能
        print("18. Parquet导入导出功能:")
        # 导出数据到Parquet文件
        parquet_path = os.path.join(chdb_DIR, "exported_data.parquet")
        if os.path.exists(parquet_path):
            os.remove(parquet_path)

        client.execute(
            f"INSERT INTO FUNCTION file('{parquet_path}', Parquet)\n        SELECT * FROM example_mergetree_table")
        print(f"   数据已导出到: {parquet_path}")

        # 从Parquet文件读取数据
        client.execute(
            f"SELECT * FROM file('{parquet_path}', Parquet) LIMIT 3")
        print("   从Parquet文件读取的数据:")
        for row in client.fetchall():
            print(f"   {row}")
        print()

        # TinyLog引擎说明与演示
        print("19. TinyLog引擎演示:")
        # TinyLog是ClickHouse的一个简单表引擎，适用于不需要复杂查询的场景
        # 特点：无主键、无索引、无分区，写入速度快，适合临时数据或日志数据
        client.execute("""CREATE TABLE IF NOT EXISTS tinylog_demo (
            id UInt32,
            name String,
            timestamp DateTime
        ) ENGINE = TinyLog""")

        # 插入TinyLog测试数据
        tinylog_data = [
            (1, 'TinyLog Record 1', '2024-01-01 10:00:00'),
            (2, 'TinyLog Record 2', '2024-01-01 11:00:00')
        ]
        for record in tinylog_data:
            client.execute(
                "INSERT INTO tinylog_demo VALUES (%s, %s, %s)", record)

        # 查询TinyLog表
        client.execute("SELECT * FROM tinylog_demo")
        for row in client.fetchall():
            print(f"   TinyLog数据: ID={row[0]}, Name={row[1]}, Time={row[2]}")
        print()

        # 获取列名 + 转换为字典格式
        print("20. 获取列名并转换为字典格式:")
        client.execute("SELECT * FROM example_mergetree_table LIMIT 3")
        col_names = [desc[0] for desc in client.description]  # 获取列名
        rows = client.fetchall()
        result = [dict(zip(col_names, row)) for row in rows]  # 将每行转换为字典

        for row in result:
            print(f"   字典格式数据: {row}")
        print()

        # 稀疏处理（假如一个表有一万条数据，等距间隔抽离出100条，用于图表展示，schdb怎么处理？或者建议先查询出1万条数据，再在内存计算？给出最优方案与代码示例）

        # 最优方案：使用ClickHouse的LIMIT + OFFSET实现等距采样
        # 方案1: 使用MOD函数进行等距采样（推荐）
        print("21. 稀疏处理 - 等距采样用于图表展示:")

        # 首先创建一个包含大量数据的测试表
        client.execute("""CREATE TABLE IF NOT EXISTS sparse_demo_table (
            id UInt32,
            value Float64,
            timestamp DateTime
        ) ENGINE = MergeTree() ORDER BY id""")

        # 插入10000条测试数据
        print("   正在插入10000条测试数据...")
        batch_size = 1000
        for batch in range(0, 10000, batch_size):
            values = []
            for i in range(batch, min(batch + batch_size, 10000)):
                values.append(f"({i}, {i * 0.5}, '2024-01-01 00:00:00')")
            if values:
                client.execute(
                    f"INSERT INTO sparse_demo_table (id, value, timestamp) VALUES {','.join(values)}")

        print("   数据插入完成")

        # 方法1: MOD函数等距采样（最优方案）
        print("\n   方法1 - MOD函数等距采样（推荐）:")
        sampling_rate = 100  # 从10000条中抽取100条，采样率1%
        client.execute(f"""
            SELECT id, value, timestamp 
            FROM sparse_demo_table 
            WHERE id % {int(10000/sampling_rate)} = 0 
            ORDER BY id 
            LIMIT {sampling_rate}
        """)

        sampled_data = client.fetchall()
        print(f"   抽样结果: 共获得 {len(sampled_data)} 条数据")
        for i, row in enumerate(sampled_data[:5]):  # 只显示前5条
            print(f"     样本{i+1}: ID={row[0]}, Value={row[1]}, Time={row[2]}")
        if len(sampled_data) > 5:
            print(f"     ... 还有 {len(sampled_data) - 5} 条数据")

        # 方法2: 使用ROW_NUMBER()窗口函数
        print("\n   方法2 - ROW_NUMBER()窗口函数采样:")
        client.execute(f"""
            SELECT id, value, timestamp FROM (
                SELECT id, value, timestamp, 
                       ROW_NUMBER() OVER (ORDER BY id) as rn,
                       COUNT(*) OVER () as total_count
                FROM sparse_demo_table
            ) WHERE rn % CAST(total_count / {sampling_rate} AS Int) = 1
            ORDER BY id
            LIMIT {sampling_rate}
        """)

        window_sampled = client.fetchall()
        print(f"   窗口函数采样结果: 共获得 {len(window_sampled)} 条数据")

        # 方法3: 内存中采样（不推荐大数据量）
        print("\n   方法3 - 内存采样对比:")
        client.execute(
            "SELECT id, value, timestamp FROM sparse_demo_table ORDER BY id")
        all_data = client.fetchall()

        # 在内存中等距采样
        step = len(all_data) // sampling_rate
        memory_sampled = [all_data[i]
                          for i in range(0, len(all_data), step)][:sampling_rate]
        print(f"   内存采样结果: 共获得 {len(memory_sampled)} 条数据")

        # 性能对比和建议
        print("\n   性能分析和最佳实践建议:")
        print("   ✓ 推荐使用方法1 (MOD函数): 在数据库层面完成采样，性能最优")
        print("   ✓ 避免方法3 (内存采样): 对于大数据集会造成内存压力和网络传输开销")
        print("   ✓ 可以结合WHERE条件先过滤数据，再进行采样")
        print("   ✓ 对于实时图表展示，建议采样率控制在1%-5%之间")

        # 清理测试表
        # client.execute("DROP TABLE IF EXISTS sparse_demo_table")
        print("\n   测试完成，已清理临时表")
    except Exception as e:
        print(f"错误: {e}")
