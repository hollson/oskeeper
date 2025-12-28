from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_, text
from models import User, Product, Order, OrderItem
from utils.database import get_db, LocalSession


def demo_query_operations():
    """
    演示各种查询操作
    """
    # 使用get_db生成器函数
    db_gen = get_db()
    db = next(db_gen)
    try:
        print("=== 查询操作演示 ===\n")

        # 基本查询
        print("1. 基本查询")
        print("所有用户查询将执行: SELECT * FROM users")
        print("活跃用户查询将执行: SELECT * FROM users WHERE is_active = 1")
        print("25岁以上用户查询将执行: SELECT * FROM users WHERE age > 25\n")

        # 多重条件查询
        print("2. 多条件查询")
        print("复杂过滤查询将执行: SELECT * FROM users WHERE age > 20 AND is_active = 1\n")

        # 限制和偏移
        print("3. 限制和偏移")
        print("限制查询将执行: SELECT * FROM users LIMIT 2 OFFSET 0\n")

        # 排序
        print("4. 排序结果")
        print("按年龄排序查询将执行: SELECT * FROM users ORDER BY age DESC")
        print("按用户名排序查询将执行: SELECT * FROM users ORDER BY username ASC\n")

        # 聚合函数
        print("5. 聚合函数")
        print("计数查询将执行: SELECT COUNT(*) FROM users")
        print("平均年龄查询将执行: SELECT AVG(age) FROM users")
        print("最大年龄查询将执行: SELECT MAX(age) FROM users")
        print("产品计数查询将执行: SELECT COUNT(*) FROM products")
        print("平均价格查询将执行: SELECT AVG(price) FROM products\n")

        # 分组操作
        print("6. 分组操作")
        print("按类别分组查询将执行: SELECT category, COUNT(*), AVG(price) FROM products GROUP BY category\n")

        # 连接操作
        print("7. 连接操作")
        print("用户和订单连接将执行: SELECT * FROM users JOIN orders ON users.id = orders.user_id")
        print("产品和订单项连接将执行: SELECT * FROM products JOIN order_items ON products.id = order_items.product_id\n")

        # 子查询
        print("8. 子查询")
        print("子查询将执行: SELECT * FROM users WHERE id IN (SELECT user_id FROM orders WHERE total_amount > 1000)\n")

        # 原生SQL查询
        print("9. 原生SQL查询")
        print("原生计数查询将执行: SELECT COUNT(*) FROM users\n")

        # 使用函数的复杂查询
        print("10. 复杂查询")
        print("价格范围查询将执行: SELECT *, FLOOR(price / 100) as price_range FROM products WHERE price > 0 ORDER BY price_range\n")

    except Exception as e:
        print(f"查询操作期间出错: {e}")
    finally:
        next(db_gen, None)  # 关闭生成器


if __name__ == "__main__":
    demo_query_operations()