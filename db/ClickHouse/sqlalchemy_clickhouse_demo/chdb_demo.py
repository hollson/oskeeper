#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
chdb演示程序
展示如何使用chdb（ClickHouse-local）作为本地文件数据库进行基本的增删改查操作
"""

import os
import sys
import chdb
import logging
from datetime import datetime

# 配置日志
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def test_chdb_connection():
    """测试chdb连接"""
    try:
        # 创建内存连接并执行简单查询
        conn = chdb.connect(':memory:')
        cur = conn.cursor()
        cur.execute("SELECT 'Hello, chdb!' as greeting")
        result = cur.fetchall()
        logger.info(f"chdb连接测试成功: {result[0][0]}")
        return True
    except Exception as e:
        logger.error(f"chdb连接测试失败: {e}")
        return False


def demonstrate_basic_operations():
    """演示chdb的基本操作：创建表、插入、查询、更新、删除"""
    logger.info("=" * 60)
    logger.info("开始演示chdb基本操作")
    logger.info("=" * 60)

    # 创建内存连接
    conn = chdb.connect(':memory:')
    cur = conn.cursor()

    # 1. 创建表 - 演示创建一个用户表
    logger.info("\n1. 创建表...")
    try:
        create_table_query = """
        CREATE TABLE users (
            id UInt32,
            username String,
            email String,
            age UInt8,
            created_at DateTime,
            is_active UInt8
        ) ENGINE=Memory
        """
        cur.execute(create_table_query)
        logger.info("✓ 用户表创建成功")
    except Exception as e:
        logger.error(f"创建表失败: {e}")
        return

    # 2. 插入数据 - 演示批量插入
    logger.info("\n2. 插入数据...")
    try:
        # 使用VALUES插入
        insert_query = """
        INSERT INTO users VALUES
        (1, 'alice', 'alice@example.com', 25, '2023-01-01 10:00:00', 1),
        (2, 'bob', 'bob@example.com', 30, '2023-01-02 11:00:00', 1),
        (3, 'charlie', 'charlie@example.com', 35, '2023-01-03 12:00:00', 0)
        """
        cur.execute(insert_query)
        logger.info("✓ 数据插入成功")
    except Exception as e:
        logger.error(f"插入数据失败: {e}")
        return

    # 3. 查询数据 - 演示不同类型的查询
    logger.info("\n3. 查询数据...")
    try:
        # 基本查询
        cur.execute("SELECT * FROM users")
        results = cur.fetchall()
        logger.info("全部用户数据:")
        for row in results:
            logger.info(f"  {row}")

        # 条件查询
        cur.execute("SELECT username, email FROM users WHERE age > 25")
        results = cur.fetchall()
        logger.info("年龄大于25岁的用户:")
        for row in results:
            logger.info(f"  {row}")

        # 聚合查询
        cur.execute(
            "SELECT COUNT(*) as count, AVG(age) as avg_age FROM users WHERE is_active = 1")
        results = cur.fetchall()
        logger.info(f"活跃用户统计: 数量={results[0][0]}, 平均年龄={results[0][1]}")
    except Exception as e:
        logger.error(f"查询数据失败: {e}")
        return

    # 4. 更新数据 - 演示更新操作
    logger.info("\n4. 更新数据...")
    try:
        # 更新特定记录
        update_query = "ALTER TABLE users UPDATE is_active = 1 WHERE username = 'charlie'"
        # 注意：ClickHouse中的UPDATE操作需要MergeTree引擎，Memory引擎不支持ALTER UPDATE
        # 所以我们演示一个替代方法，创建新表并插入更新后的数据
        cur.execute("SELECT * FROM users WHERE username = 'charlie'")
        charlie_data = cur.fetchall()[0]

        # 删除原记录并插入更新后的记录
        # 这个在Memory引擎中也不支持
        cur.execute("DELETE FROM users WHERE username = 'charlie'")
        # 所以我们重新插入所有数据，其中charlie的is_active改为1
        cur.execute(
            "INSERT INTO users VALUES (3, 'charlie', 'charlie@example.com', 35, '2023-01-03 12:00:00', 1)")
        logger.info("✓ 数据更新演示（由于Memory引擎限制，实际使用不同方法）")
    except Exception as e:
        logger.warning(f"更新操作演示（受引擎限制）: {e}")

    # 5. 删除数据 - 演示删除操作
    logger.info("\n5. 删除数据...")
    try:
        # 由于Memory引擎不支持DELETE，我们演示另一种方式
        # 创建一个新表，不包含要删除的记录
        cur.execute("""
        CREATE TABLE temp_users AS users 
        WHERE username != 'bob'
        """)
        cur.execute("SELECT * FROM temp_users")
        remaining_users = cur.fetchall()
        logger.info("删除bob后剩余用户:")
        for row in remaining_users:
            logger.info(f"  {row}")
    except Exception as e:
        logger.warning(f"删除操作演示（受引擎限制）: {e}")

    logger.info("\n" + "=" * 60)
    logger.info("基本操作演示完成")
    logger.info("=" * 60)


def demonstrate_time_series_features():
    """演示ClickHouse的时间序列特性"""
    logger.info("\n" + "=" * 60)
    logger.info("演示ClickHouse时间序列特性")
    logger.info("=" * 60)

    conn = chdb.connect(':memory:')
    cur = conn.cursor()

    # 创建一个时间序列数据表
    create_ts_table = """
    CREATE TABLE sensor_data (
        id UInt64,
        sensor_id String,
        temperature Float32,
        humidity Float32,
        timestamp DateTime
    ) ENGINE=Memory
    """
    cur.execute(create_ts_table)
    logger.info("✓ 时间序列表创建成功")

    # 插入时间序列数据
    insert_data = """
    INSERT INTO sensor_data VALUES
    (1, 'sensor_001', 23.5, 45.2, '2023-01-01 10:00:00'),
    (2, 'sensor_001', 23.7, 44.8, '2023-01-01 11:00:00'),
    (3, 'sensor_001', 24.1, 44.5, '2023-01-01 12:00:00'),
    (4, 'sensor_002', 22.8, 46.1, '2023-01-01 10:00:00'),
    (5, 'sensor_002', 23.0, 45.9, '2023-01-01 11:00:00'),
    (6, 'sensor_002', 23.2, 45.7, '2023-01-01 12:00:00')
    """
    cur.execute(insert_data)
    logger.info("✓ 时间序列数据插入成功")

    # 查询时间序列数据
    logger.info("\n时间序列数据查询:")
    cur.execute("SELECT * FROM sensor_data ORDER BY timestamp")
    results = cur.fetchall()
    for row in results:
        logger.info(f"  {row}")

    # 时间序列聚合查询
    logger.info("\n按传感器统计:")
    cur.execute("""
    SELECT 
        sensor_id,
        AVG(temperature) as avg_temp,
        MIN(temperature) as min_temp,
        MAX(temperature) as max_temp,
        AVG(humidity) as avg_humidity
    FROM sensor_data 
    GROUP BY sensor_id
    """)
    results = cur.fetchall()
    for row in results:
        logger.info(
            f"  传感器 {row[0]}: 平均温度={row[1]:.2f}, 最低温度={row[2]:.2f}, 最高温度={row[3]:.2f}, 平均湿度={row[4]:.2f}")

    # 按时间窗口聚合
    logger.info("\n按小时统计温度:")
    cur.execute("""
    SELECT 
        toHour(timestamp) as hour,
        AVG(temperature) as avg_temp
    FROM sensor_data 
    GROUP BY toHour(timestamp)
    ORDER BY hour
    """)
    results = cur.fetchall()
    for row in results:
        logger.info(f"  {row[0]}时: 平均温度={row[1]:.2f}")

    logger.info("\n" + "=" * 60)
    logger.info("时间序列特性演示完成")
    logger.info("=" * 60)


def demonstrate_file_based_operations():
    """演示基于文件的操作（如果系统支持）"""
    logger.info("\n" + "=" * 60)
    logger.info("演示基于文件的操作")
    logger.info("=" * 60)

    # 创建临时目录
    temp_dir = "./temp_chdb_demo"
    os.makedirs(temp_dir, exist_ok=True)

    try:
        # 使用chdb连接到文件
        db_file = os.path.join(temp_dir, "demo.db")
        conn = chdb.connect(db_file)
        cur = conn.cursor()

        # 创建表
        cur.execute("""
        CREATE TABLE file_users (
            id UInt32,
            name String,
            value Float32
        ) ENGINE=MergeTree()
        ORDER BY id
        """)
        logger.info("✓ 文件数据库表创建成功")

        # 插入数据
        cur.execute(
            "INSERT INTO file_users VALUES (1, 'file_user_1', 100.5), (2, 'file_user_2', 200.8)")
        logger.info("✓ 数据插入到文件数据库成功")

        # 查询数据
        cur.execute("SELECT * FROM file_users")
        results = cur.fetchall()
        logger.info("从文件数据库查询的数据:")
        for row in results:
            logger.info(f"  {row}")

        conn.close()
        logger.info(f"✓ 数据已保存到文件: {db_file}")

    except Exception as e:
        logger.warning(f"文件操作演示失败（可能需要特定权限或配置）: {e}")
    finally:
        # 清理临时目录
        import shutil
        if os.path.exists(temp_dir):
            try:
                shutil.rmtree(temp_dir)
            except:
                pass


def main():
    """主函数"""
    logger.info("chdb演示程序")
    logger.info("此程序演示如何使用chdb（ClickHouse-local）作为本地文件数据库")

    # 检查chdb是否可用
    if not test_chdb_connection():
        logger.error("chdb不可用，请确保已安装chdb模块: pip install chdb")
        logger.info("注意：chdb仅支持macOS和Linux系统")
        return

    logger.info(f"当前系统: {sys.platform}")
    logger.info(
        f"chdb版本: {chdb.__version__ if hasattr(chdb, '__version__') else 'unknown'}")

    # 演示基本操作
    demonstrate_basic_operations()

    # 演示时间序列特性
    demonstrate_time_series_features()

    # 演示基于文件的操作
    demonstrate_file_based_operations()

    logger.info("\n" + "=" * 60)
    logger.info("chdb演示程序执行完成")
    logger.info("总结:")
    logger.info("- chdb提供了类似SQLite的本地ClickHouse体验")
    logger.info("- 支持完整的SQL查询功能")
    logger.info("- 特别适合时间序列数据处理")
    logger.info("- 可以用作嵌入式数据库或临时数据处理工具")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
