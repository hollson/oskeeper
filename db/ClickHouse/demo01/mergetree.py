#!/usr/bin/env python3
"""
ClickHouse MergeTree 表引擎演示
MergeTree是ClickHouse的原生表引擎，专为OLAP工作负载设计
"""

import chdb
from chdb import dbapi
import os

# 设置数据目录
chdb_DIR = "./master.chdb"
os.makedirs(chdb_DIR, exist_ok=True)


def demo_mergetree_operations():
    # 连接到chdb
    conn = dbapi.connect(chdb_DIR)
    client = conn.cursor()

    print("=== ClickHouse MergeTree 演示 ===\n")

    # 1. 创建基础MergeTree表
    print("1. 创建基础MergeTree表:")
    client.execute("""
        CREATE TABLE IF NOT EXISTS example_mergetree (
            id UInt32,
            name String,
            date Date,
            value Float64,
            category String
        ) ENGINE = MergeTree()
        PARTITION BY toYYYYMM(date)
        ORDER BY (date, id)
        SETTINGS index_granularity = 8192
    """)
    print("✓ 创建基础MergeTree表成功\n")

    # 2. 插入数据
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
            "INSERT INTO example_mergetree VALUES (%s, %s, %s, %s, %s)", record)
    print(f"✓ 插入 {len(sample_data)} 条记录\n")

    # 3. 查询数据
    print("3. 查询数据:")
    client.execute("SELECT * FROM example_mergetree ORDER BY date")
    for row in client.fetchall():
        print(
            f"   ID: {row[0]}, Name: {row[1]}, Date: {row[2]}, Value: {row[3]}, Category: {row[4]}")
    print()

    # 4. 分区查询
    print("4. 分区查询 (2023年1月数据):")
    client.execute(
        "SELECT * FROM example_mergetree WHERE toYYYYMM(date) = 202301")
    for row in client.fetchall():
        print(
            f"   ID: {row[0]}, Name: {row[1]}, Date: {row[2]}, Value: {row[3]}")
    print()

    # 5. 聚合查询
    print("5. 聚合查询 (按类别统计):")
    client.execute("""
        SELECT category, count(*) as count, sum(value) as total_value
        FROM example_mergetree
        GROUP BY category
        ORDER BY total_value DESC
    """)
    for row in client.fetchall():
        print(f"   Category: {row[0]}, Count: {row[1]}, Total Value: {row[2]}")
    print()

    # 6. 创建SummingMergeTree表
    print("6. 创建SummingMergeTree表 (自动聚合):")
    client.execute("""
        CREATE TABLE IF NOT EXISTS example_summing_mergetree (
            date Date,
            category String,
            quantity UInt32,
            revenue Float64
        ) ENGINE = SummingMergeTree(revenue)
        PARTITION BY toYYYYMM(date)
        ORDER BY (date, category)
    """)
    print("✓ 创建SummingMergeTree表成功\n")

    # 7. 插入聚合数据
    print("7. 插入聚合数据:")
    agg_data = [
        ('2023-01-15', 'Electronics', 10, 1000.0),
        ('2023-01-15', 'Electronics', 5, 500.0),  # 这条记录将与上一条聚合
        ('2023-01-16', 'Clothing', 8, 400.0),
        ('2023-02-01', 'Books', 15, 750.0)
    ]

    for record in agg_data:
        client.execute(
            "INSERT INTO example_summing_mergetree VALUES (%s, %s, %s, %s)", record)
    print(f"✓ 插入 {len(agg_data)} 条聚合记录\n")

    # 8. 查询聚合表
    print("8. 查询SummingMergeTree表:")
    client.execute(
        "SELECT * FROM example_summing_mergetree ORDER BY date, category")
    for row in client.fetchall():
        print(
            f"   Date: {row[0]}, Category: {row[1]}, Quantity: {row[2]}, Revenue: {row[3]}")
    print()

    # 9. 创建ReplacingMergeTree表
    print("9. 创建ReplacingMergeTree表 (去重):")
    client.execute("""
        CREATE TABLE IF NOT EXISTS example_replacing_mergetree (
            id UInt32,
            version UInt32,
            name String,
            updated_date DateTime DEFAULT now()
        ) ENGINE = ReplacingMergeTree(version)
        ORDER BY id
    """)
    print("✓ 创建ReplacingMergeTree表成功\n")

    # 10. 插入重复数据
    print("10. 插入重复数据 (用于演示去重):")
    dup_data = [
        (1, 1, 'Old Name', '2023-01-01 00:00:00'),
        (1, 2, 'New Name', '2023-01-02 00:00:00'),  # 这条记录版本更高，会替换上一条
        (2, 1, 'Another Product', '2023-01-01 00:00:00')
    ]

    for record in dup_data:
        client.execute(
            "INSERT INTO example_replacing_mergetree VALUES (%s, %s, %s, %s)", record)
    print(f"✓ 插入 {len(dup_data)} 条重复记录\n")

    # 11. 查询去重表
    print("11. 查询ReplacingMergeTree表 (去重后):")
    client.execute("SELECT * FROM example_replacing_mergetree ORDER BY id")
    for row in client.fetchall():
        print(f"   ID: {row[0]}, Version: {row[1]}, Name: {row[2]}")
    print()

    # 12. 数据更新 (通过插入新版本)
    print("12. 更新数据 (插入新版本):")
    update_data = [(1, 3, 'Updated Name', '2023-01-03 00:00:00')]
    for record in update_data:
        client.execute(
            "INSERT INTO example_replacing_mergetree VALUES (%s, %s, %s, %s)", record)
    print("✓ 插入更新记录\n")

    # 13. 查询更新后的数据
    print("13. 查询更新后的ReplacingMergeTree表:")
    client.execute("SELECT * FROM example_replacing_mergetree ORDER BY id")
    for row in client.fetchall():
        print(f"   ID: {row[0]}, Version: {row[1]}, Name: {row[2]}")
    print()

    # 14. 显示表信息
    print("14. 表信息:")
    client.execute("SHOW TABLES")
    print("   当前数据库中的表:")
    for table in client.fetchall():
        print(f"   - {table[0]}")
    print()

    # 15. 显示分区信息
    print("15. 分区信息:")
    client.execute("""
        SELECT partition, name, rows, bytes_on_disk
        FROM system.parts 
        WHERE table = 'example_mergetree' 
        ORDER BY partition
    """)
    for part in client.fetchall():
        print(
            f"   Partition: {part[0]}, Table: {part[1]}, Rows: {part[2]}, Size: {part[3]} bytes")
    print()

    # 清理演示数据
    print("16. 清理演示数据:")
    client.execute("DROP TABLE IF EXISTS example_mergetree")
    client.execute("DROP TABLE IF EXISTS example_summing_mergetree")
    client.execute("DROP TABLE IF EXISTS example_replacing_mergetree")
    print("✓ 演示数据清理完成\n")

    print("=== MergeTree 演示结束 ===")


if __name__ == "__main__":
    try:
        demo_mergetree_operations()
    except Exception as e:
        print(f"错误: {e}")
        print("使用chdb，无需运行ClickHouse服务")
