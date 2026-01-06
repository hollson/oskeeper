#!/usr/bin/env python3

from chdb_helper import ChdbManager, logger
import os
import time
from contextlib import contextmanager
from typing import List, Tuple, Optional


def create_mergetree_table(manager: ChdbManager):
    print("1. 创建MergeTree表")
    manager.execute("""CREATE TABLE IF NOT EXISTS example_mergetree_table (id UInt32,name String,date Date,value Float64,category String) 
                   ENGINE = MergeTree() PARTITION BY toYYYYMM(date) ORDER BY (date, id) SETTINGS index_granularity = 8192""")
    print()


def insert_mergetree_table(manager: ChdbManager):
    print("2. 插入示例数据:")
    sample_data = [
        (1, 'Product A', '2023-01-15', 100.5, 'Electronics'),
        (2, 'Product B', '2023-01-16', 250.0, 'Clothing'),
        (3, 'Product C', '2023-02-01', 75.25, 'Books'),
        (4, 'Product D', '2023-02-10', 300.0, 'Electronics'),
        (5, 'Product E', '2023-03-05', 120.75, 'Sports')
    ]
    success = manager.insert_batch(
        "example_mergetree_table",
        "id, name, date, value, category",
        sample_data
    )
    if success:
        print("批量插入成功")
    else:
        print("批量插入失败")
    print()


def query_all_data(manager: ChdbManager):
    print("3. 查询所有数据:")
    results = manager.execute(
        "SELECT * FROM example_mergetree_table ORDER BY date")
    for row in results:
        print(
            f"   ID: {row[0]}, Name: {row[1]}, Date: {row[2]}, Value: {row[3]}, Category: {row[4]}")
    print()


def query_with_cond(manager: ChdbManager):
    print("4. 条件查询 (2023年1月数据):")
    results = manager.execute(
        "SELECT * FROM example_mergetree_table WHERE toYYYYMM(date) = 202301")
    for row in results:
        print(
            f"   ID: {row[0]}, Name: {row[1]}, Date: {row[2]}, Value: {row[3]}")
    print()


def query_aggregated(manager: ChdbManager):
    print("5. 聚合查询 (GroupBy):")
    results = manager.execute("""SELECT category, count(*) as count, sum(value) as total_value
        FROM example_mergetree_table GROUP BY category ORDER BY total_value DESC""")
    for row in results:
        print(f"   Category: {row[0]}, Count: {row[1]}, Total Value: {row[2]}")
    print()


def create_summing_table(manager: ChdbManager):
    """主键是 (date, category)，相同主键的行会被聚合，SummingMergeTree(revenue)即revenue是聚合(求和)列"""
    print("6. 创建SummingMergeTree表 (自动聚合):")
    manager.execute("""
        CREATE TABLE IF NOT EXISTS example_summing_table (date Date,category String,quantity UInt32,revenue Float64) 
        ENGINE = SummingMergeTree(revenue) PARTITION BY toYYYYMM(date) ORDER BY (date, category)""")
    print()


def insert_summing_table(manager: ChdbManager):
    print("7. 插入聚合数据:")
    agg_data = [
        ('2023-01-15', 'Electronics', 10, 1000.0),
        ('2023-01-15', 'Electronics', 5, 500.0),  # 这条记录将与上一条聚合
        ('2023-01-16', 'Clothing', 8, 400.0),
        ('2023-02-01', 'Books', 15, 750.0)
    ]
    success = manager.insert_batch(
        "example_summing_table",
        "date, category, quantity, revenue",
        agg_data
    )
    if success:
        print("批量插入成功")
    else:
        print("批量插入失败")
    print()


def query_summing_table(manager: ChdbManager):
    print("8. 查询SummingMergeTree表:")
    # SummingMergeTree聚合时机说明：
    # • 事务提交后：数据commit时可能触发合并
    # • 后台自动合并：ClickHouse引擎定期自动合并数据片段
    # • 定时调度合并：系统按计划合并小型数据部分
    # • 手动OPTIMIZE：如：manager.execute("OPTIMIZE TABLE example_summing_table FINAL")
    results = manager.execute(
        "SELECT * FROM example_summing_table ORDER BY date, category")
    for row in results:
        print(
            f"   Date: {row[0]}, Category: {row[1]}, Quantity: {row[2]}, Revenue: {row[3]}")
    print()


def create_replacing_table(manager: ChdbManager):
    # ReplacingMergeTree去重依据：
    # ORDER BY定义的排序键完全相同的记录中，version值更大的记录会覆盖version值更小的记录。
    # 如果version是字符串，则按字典序比较，字典序更大的字符串版本会覆盖较小的
    print("9. 创建ReplacingMergeTree表 (去重):")
    manager.execute("""
        CREATE TABLE IF NOT EXISTS example_replacing_table (id UInt32,version UInt32,name String,updated_date DateTime DEFAULT now()) 
        ENGINE = ReplacingMergeTree(version) ORDER BY id""")
    print()


def insert_replacing_table(manager: ChdbManager):
    print("10. 插入重复数据 (用于演示去重):")
    dup_data = [
        (1, 1, 'Old Name', '2023-01-01 00:00:00'),
        (1, 2, 'New Name', '2023-01-02 00:00:00'),  # 这条记录版本更高(数值)，会替换上一条
        (2, 1, 'Another Product', '2023-01-01 00:00:00')
    ]

    success = manager.insert_batch(
        "example_replacing_table",
        "id, version, name, updated_date",
        dup_data
    )
    if success:
        print("批量插入成功")
    else:
        print("批量插入失败")
    print()


def query_replacing_table(manager: ChdbManager):
    print("11. 查询ReplacingMergeTree表 (去重后):")
    results = manager.execute(
        "SELECT * FROM example_replacing_table ORDER BY id")
    for row in results:
        print(f"   ID: {row[0]}, Version: {row[1]}, Name: {row[2]}")
    print()


def show_table_info(manager: ChdbManager):
    print("12. 表信息:")
    results = manager.execute("SHOW TABLES")
    for table in results:
        print(f"   - {table[0]}")
    print()


def show_partition_info(manager: ChdbManager):
    print("13. 分区信息:")
    results = manager.execute("""SELECT partition, name, rows, bytes_on_disk FROM system.parts 
        WHERE table = 'example_mergetree_table' ORDER BY partition""")
    print("   分区\t\t\t分名称\t\t\t行数\t\t磁盘大小")
    for part in results:
        print(
            f"   Partition: {part[0]} \tName: {part[1]} \tRows: {part[2]} \tSize: {part[3]} bytes")
    print()


def cleanup_demo_data(manager: ChdbManager):
    print("14. 清理表和数据")
    # manager.execute("DROP TABLE IF EXISTS example_mergetree_table")
    # manager.execute("DROP TABLE IF EXISTS example_summing_table")
    manager.execute("DROP TABLE IF EXISTS example_replacing_table")


if __name__ == "__main__":
    try:
        manager = ChdbManager("./master.chdb")
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

    except Exception as e:
        print(f"错误: {e}")

    print("================================ 日志测试 ================================")
    logger.debug("this is a debug")
    logger.info("this is a info")
    logger.warning("this is a warning")
    logger.error("this is a error")
    logger.fatal("this is a fatal")
