from sqlalchemy.orm import Session
from models import User, Product, Order, OrderItem
from utils.database import get_db, LocalSession
import uuid
from datetime import datetime


def create_user(db: LocalSession, username: str, email: str, first_name: str = None, last_name: str = None, age: int = None):
    """
    创建新用户
    """
    user = User(
        username=username,
        email=email,
        first_name=first_name,
        last_name=last_name,
        age=age
    )
    db.add(user)
    db.commit()
    # db.refresh(user)  # LocalSession中未实现
    return user


def get_user_by_id(db: LocalSession, user_id: int):
    """
    通过ID获取用户
    """
    # 这是演示的简化实现
    # 在实际实现中，您需要执行适当的查询
    try:
        result = db.execute(f"SELECT * FROM users WHERE id = {user_id} LIMIT 1")
        # 解析结果 - 演示简化
        return User()  # 返回模拟用户对象
    except:
        return None


def get_user_by_username(db: LocalSession, username: str):
    """
    通过用户名获取用户
    """
    try:
        result = db.execute(f"SELECT * FROM users WHERE username = '{username}' LIMIT 1")
        # 解析结果 - 演示简化
        return User()  # 返回模拟用户对象
    except:
        return None


def update_user(db: LocalSession, user_id: int, **kwargs):
    """
    更新用户
    """
    # 构建更新查询
    set_parts = []
    for key, value in kwargs.items():
        if isinstance(value, str):
            set_parts.append(f"{key} = '{value}'")
        else:
            set_parts.append(f"{key} = {value}")
    
    query = f"ALTER TABLE users UPDATE {', '.join(set_parts)} WHERE id = {user_id}"
    try:
        db.execute(query)
        return get_user_by_id(db, user_id)
    except:
        return None


def delete_user(db: LocalSession, user_id: int):
    """
    删除用户
    """
    try:
        db.execute(f"DELETE FROM users WHERE id = {user_id}")
        return True
    except:
        return False


def create_product(db: LocalSession, name: str, description: str = None, price: float = 0.0, stock_quantity: int = 0, category: str = None):
    """
    创建新产品
    """
    product = Product(
        name=name,
        description=description,
        price=price,
        stock_quantity=stock_quantity,
        category=category
    )
    db.add(product)
    db.commit()
    return product


def get_product_by_id(db: LocalSession, product_id: int):
    """
    通过ID获取产品
    """
    try:
        result = db.execute(f"SELECT * FROM products WHERE id = {product_id} LIMIT 1")
        # 解析结果 - 演示简化
        return Product()  # 返回模拟产品对象
    except:
        return None


def update_product(db: LocalSession, product_id: int, **kwargs):
    """
    更新产品
    """
    # 构建更新查询
    set_parts = []
    for key, value in kwargs.items():
        if isinstance(value, str):
            set_parts.append(f"{key} = '{value}'")
        else:
            set_parts.append(f"{key} = {value}")
    
    query = f"ALTER TABLE products UPDATE {', '.join(set_parts)} WHERE id = {product_id}"
    try:
        db.execute(query)
        return get_product_by_id(db, product_id)
    except:
        return None


def delete_product(db: LocalSession, product_id: int):
    """
    删除产品
    """
    try:
        db.execute(f"DELETE FROM products WHERE id = {product_id}")
        return True
    except:
        return False


def create_order(db: LocalSession, user_id: int, order_number: str, shipping_address: str = None):
    """
    创建新订单
    """
    order = Order(
        user_id=user_id,
        order_number=order_number,
        shipping_address=shipping_address
    )
    db.add(order)
    db.commit()
    return order


def get_order_by_id(db: LocalSession, order_id: int):
    """
    通过ID获取订单
    """
    try:
        result = db.execute(f"SELECT * FROM orders WHERE id = {order_id} LIMIT 1")
        # 解析结果 - 演示简化
        return Order()  # 返回模拟订单对象
    except:
        return None


def update_order(db: LocalSession, order_id: int, **kwargs):
    """
    更新订单
    """
    # 构建更新查询
    set_parts = []
    for key, value in kwargs.items():
        if isinstance(value, str):
            set_parts.append(f"{key} = '{value}'")
        else:
            set_parts.append(f"{key} = {value}")
    
    query = f"ALTER TABLE orders UPDATE {', '.join(set_parts)} WHERE id = {order_id}"
    try:
        db.execute(query)
        return get_order_by_id(db, order_id)
    except:
        return None


def delete_order(db: LocalSession, order_id: int):
    """
    删除订单
    """
    try:
        db.execute(f"DELETE FROM orders WHERE id = {order_id}")
        return True
    except:
        return False


def create_order_item(db: LocalSession, order_id: int, product_id: int, quantity: int, unit_price: float):
    """
    创建新订单项
    """
    order_item = OrderItem(
        order_id=order_id,
        product_id=product_id,
        quantity=quantity,
        unit_price=unit_price,
        total_price=quantity * unit_price
    )
    db.add(order_item)
    db.commit()
    return order_item


def demo_crud_operations():
    """
    演示CRUD操作
    """
    # 使用get_db生成器函数
    db_gen = get_db()
    db = next(db_gen)
    try:
        print("=== CRUD操作演示 ===\n")

        # 创建用户
        print("1. 创建用户...")
        # 注意：在实际实现中，我们需要以不同的方式处理对象创建
        # 为了演示目的，我们展示概念
        print("使用ClickHouse Local创建用户...")
        print("用户创建将执行: INSERT INTO users (...) VALUES (...)\n")

        # 创建产品
        print("2. 创建产品...")
        print("使用ClickHouse Local创建产品...")
        print("产品创建将执行: INSERT INTO products (...) VALUES (...)\n")

        # 读取操作
        print("3. 读取数据...")
        print("使用ClickHouse Local读取数据...")
        print("读取操作将执行: SELECT ... FROM ...\n")

        # 更新操作
        print("4. 更新数据...")
        print("使用ClickHouse Local更新数据...")
        print("更新操作将执行: ALTER TABLE ... UPDATE ...\n")

        # 创建订单和订单项
        print("5. 创建订单和订单项...")
        print("使用ClickHouse Local创建订单...")
        print("订单创建将执行: INSERT INTO orders (...) VALUES (...)\n")

    except Exception as e:
        print(f"CRUD操作期间出错: {e}")
        # db.rollback()  # LocalSession中未实现回滚
    finally:
        next(db_gen, None)  # 关闭生成器


if __name__ == "__main__":
    demo_crud_operations()