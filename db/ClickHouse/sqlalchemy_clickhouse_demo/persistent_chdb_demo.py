#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
持久化 chdb 演示程序
展示如何使用 chdb 将数据持久化到本地文件
"""

import chdb
import os
import tempfile
from datetime import datetime


def demonstrate_persistent_storage():
    """演示数据持久化存储"""
    print("=== 持久化存储演示 ===\n")

    # 创建临时目录用于存储数据
    temp_dir = tempfile.mkdtemp(prefix="chdb_persistent_demo_")
    print(f"使用临时目录: {temp_dir}")

    try:
        # 连接到持久化数据库文件
        db_path = os.path.join(temp_dir, "persistent.db")
        conn = chdb.connect(db_path)

        # 创建使用MergeTree引擎的表（支持持久化）
        print("1. 创建持久化表...")
        conn.query("""
            CREATE TABLE IF NOT EXISTS users (
                id UInt32,
                name String,
                email String,
                created_at DateTime
            ) ENGINE=MergeTree()
            ORDER BY id
        """)
        print("✓ 持久化表创建成功\n")

        # 插入数据
        print("2. 插入数据到持久化表...")
        conn.query(
            "INSERT INTO users VALUES (1, 'Alice', 'alice@example.com', '2023-01-01 10:00:00')")
        conn.query(
            "INSERT INTO users VALUES (2, 'Bob', 'bob@example.com', '2023-01-02 11:00:00')")
        conn.query(
            "INSERT INTO users VALUES (3, 'Charlie', 'charlie@example.com', '2023-01-03 12:00:00')")
        print("✓ 数据插入成功\n")

        # 查询数据
        print("3. 查询持久化数据...")
        result = conn.query("SELECT * FROM users ORDER BY id")
        print("持久化表中的数据:")
        print(result)
        print()

        # 验证数据是否真的持久化到文件
        print("4. 检查数据文件...")
        db_files = []
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = os.path.join(root, file)
                file_size = os.path.getsize(file_path)
                db_files.append((file_path, file_size))

        print("在数据库目录中找到的文件:")
        for file_path, size in db_files:
            print(f"  {file_path} - {size} bytes")
        print()

        # 关闭连接
        conn.close()

        # 重新打开连接并验证数据仍然存在
        print("5. 重新连接并验证数据持久性...")
        conn2 = chdb.connect(db_path)
        result2 = conn2.query("SELECT COUNT(*) as count FROM users")
        print(f"重新连接后，表中记录数: {result2}")

        # 查询所有数据
        result3 = conn2.query("SELECT * FROM users ORDER BY id")
        print("重新连接后查询到的数据:")
        print(result3)
        print()

        conn2.close()

        print(f"✓ 数据已持久化到: {db_path}")

    except Exception as e:
        print(f"持久化演示出错: {e}")
    finally:
        # 清理临时目录（可选，保留以便查看文件结构）
        import shutil
        try:
            shutil.rmtree(temp_dir)
            print(f"已清理临时目录: {temp_dir}")
        except:
            pass


def demonstrate_memory_vs_persistent():
    """对比Memory引擎和持久化引擎"""
    print("=== Memory引擎 vs 持久化引擎对比 ===\n")

    # Memory引擎演示
    print("1. Memory引擎 (非持久化):")
    conn_mem = chdb.connect()
    conn_mem.query("""
        CREATE TABLE mem_users (
            id UInt32,
            name String
        ) ENGINE=Memory
    """)
    conn_mem.query("INSERT INTO mem_users VALUES (1, 'MemoryUser')")
    result_mem = conn_mem.query("SELECT * FROM mem_users")
    print(f"   内存表数据: {result_mem}")
    conn_mem.close()
    print("   ✓ Memory引擎数据存储在内存中，连接关闭后数据丢失\n")

    # MergeTree引擎演示
    print("2. MergeTree引擎 (持久化):")
    temp_dir = tempfile.mkdtemp(prefix="chdb_merge_demo_")
    try:
        db_path = os.path.join(temp_dir, "mergedb.db")
        conn_merge = chdb.connect(db_path)
        conn_merge.query("""
            CREATE TABLE merge_users (
                id UInt32,
                name String
            ) ENGINE=MergeTree()
            ORDER BY id
        """)
        conn_merge.query("INSERT INTO merge_users VALUES (1, 'MergeUser')")
        result_merge = conn_merge.query("SELECT * FROM merge_users")
        print(f"   持久化表数据: {result_merge}")
        conn_merge.close()

        # 验证数据持久化
        conn_merge2 = chdb.connect(db_path)
        result_merge2 = conn_merge2.query("SELECT * FROM merge_users")
        print(f"   重新连接后数据: {result_merge2}")
        conn_merge2.close()
        print("   ✓ MergeTree引擎数据持久化到磁盘\n")

    except Exception as e:
        print(f"   错误: {e}")
    finally:
        import shutil
        try:
            shutil.rmtree(temp_dir)
        except:
            pass


def main():
    """主函数"""
    print("持久化 chdb 演示程序")
    print("此程序演示如何使用 chdb 进行数据持久化存储\n")

    # 演示持久化存储
    demonstrate_persistent_storage()

    print("\n" + "="*60 + "\n")

    # 对比Memory和持久化引擎
    demonstrate_memory_vs_persistent()

    print("\n=== 演示完成 ===")
    print("总结:")
    print("- Memory引擎: 数据存储在内存中，速度快但不持久化")
    print("- MergeTree引擎: 数据持久化到磁盘，适合需要数据持久化的场景")
    print("- chdb支持多种引擎，可根据需要选择合适的存储方式")


if __name__ == "__main__":
    main()
