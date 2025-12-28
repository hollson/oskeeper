from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, text
from models import User, Product, Order, OrderItem
from utils.database import get_db, LocalSession


def demo_batch_operations():
    """
    演示批量操作
    """
    # 使用get_db生成器函数
    db_gen = get_db()
    db = next(db_gen)
    try:
        print("=== 批量操作演示 ===\n")

        # 批量插入用户
        print("1. 批量插入操作")
        print("批量插入将执行: INSERT INTO users (...) VALUES (...), (...), (...)\n")

        # 批量插入产品
        print("2. 批量插入产品")
        print("批量插入将执行: INSERT INTO products (...) VALUES (...), (...), (...)\n")

        # 批量更新操作
        print("3. 批量更新操作")
        print("批量更新将执行: ALTER TABLE users UPDATE is_active = 0 WHERE age < 25")
        print("批量更新将执行: ALTER TABLE products UPDATE price = price * 1.1 WHERE category = 'Electronics'\n")

        # 批量删除操作
        print("4. 批量删除操作")
        print("批量删除将执行: DELETE FROM users WHERE age > 50\n")

        # 批量选择操作
        print("5. 批量选择操作")
        print("批量选择将执行: SELECT * FROM users LIMIT 2 OFFSET 0")
        print("后续选择将执行: SELECT * FROM users LIMIT 2 OFFSET 2, 等等.\n")

    except Exception as e:
        print(f"批量操作期间出错: {e}")
        # db.rollback()  # LocalSession中未实现回滚
    finally:
        next(db_gen, None)  # 关闭生成器


def demo_transaction_operations():
    """
    演示事务操作
    """
    # 使用get_db生成器函数
    db_gen = get_db()
    db = next(db_gen)
    try:
        print("=== 事务操作演示 ===\n")

        print("1. 简单事务示例")
        print("在ClickHouse Local模式下，事务与服务器模式的工作方式不同")
        print("操作通常在查询级别是原子的\n")

        print("2. 嵌套事务示例")
        print("ClickHouse Local模式相比服务器模式具有有限的事务支持\n")

        print("3. 事务中的错误处理")
        print("Local模式中的错误处理与服务器模式不同\n")

    except Exception as e:
        print(f"事务操作期间出错: {e}")
        # db.rollback()  # LocalSession中未实现回滚
    finally:
        next(db_gen, None)  # 关闭生成器


if __name__ == "__main__":
    demo_batch_operations()
    print("\n" + "="*50 + "\n")
    demo_transaction_operations()