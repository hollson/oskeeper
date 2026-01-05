#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试chdb文件数据库功能的脚本
验证项目的基本功能是否正常工作
"""

import os
import sys
from utils.database import test_connection, create_tables, drop_tables
from models.user import User
from utils.database import get_db
from config import LOCAL_DATA_PATH


def test_basic_functionality():
    """测试基本功能"""
    print("测试chdb文件数据库基本功能...")

    # 测试连接
    print("\n1. 测试数据库连接...")
    if test_connection():
        print("✓ 数据库连接正常")
    else:
        print("✗ 数据库连接失败")
        return False

    # 测试表创建
    print("\n2. 测试表创建...")
    try:
        create_tables()
        print("✓ 表创建成功")
    except Exception as e:
        print(f"✗ 表创建失败: {e}")
        return False

    # 测试数据操作
    print("\n3. 测试数据操作...")
    try:
        # 获取数据库会话
        for db in get_db():
            # 添加一个用户
            user = User()
            user.username = "test_user"
            user.email = "test@example.com"
            user.first_name = "Test"
            user.last_name = "User"
            user.age = 30

            db.add(user)
            print("✓ 数据插入成功")

            # 查询用户
            users = db.query(User).all()
            print(f"✓ 查询成功，找到 {len(users)} 个用户")

            if users:
                first_user = db.query(User).first()
                # 由于chdb返回的是元组，我们直接打印第一个结果
                print(f"✓ 获取第一个用户记录: {first_user}")

            break  # 退出生成器
        print("✓ 数据操作测试完成")
    except Exception as e:
        print(f"✗ 数据操作失败: {e}")
        import traceback
        traceback.print_exc()
        return False

    # 验证数据文件是否创建
    print("\n4. 验证数据文件...")
    db_file = os.path.join(LOCAL_DATA_PATH, "master.chdb")
    if os.path.exists(db_file):
        file_size = os.path.getsize(db_file)
        print(f"✓ 数据库文件已创建: {db_file}, 大小: {file_size} 字节")
    else:
        print(f"✗ 数据库文件未找到: {db_file}")
        return False

    print("\n✓ 所有功能测试通过！")
    return True


def main():
    """主函数"""
    print("chdb文件数据库功能验证")
    print("=" * 40)

    success = test_basic_functionality()

    if success:
        print("\n✓ 项目功能验证成功！")
        print(f"数据存储在: {LOCAL_DATA_PATH}")
    else:
        print("\n✗ 项目功能验证失败！")
        sys.exit(1)


if __name__ == "__main__":
    main()
