"""
Hello DuckDB - 完整的DuckDB使用示例项目
主程序文件，演示基本连接和数据操作
"""

import duckdb
import os

def connect_to_db(db_path="hello_duckdb.duckdb"):
    """连接到DuckDB数据库"""
    print(f"连接到数据库: {db_path}")
    conn = duckdb.connect(db_path)
    return conn

def create_sample_table(conn):
    """创建示例销售表"""
    print("创建示例销售表...")
    conn.execute("""
        CREATE TABLE IF NOT EXISTS sales (
            order_id INTEGER,
            product VARCHAR,
            category VARCHAR,
            region VARCHAR,
            sales_amount DECIMAL(10,2),
            date DATE
        )
    """)
    
    # 插入示例数据
    conn.execute("""
        INSERT INTO sales VALUES 
        (1, 'Laptop', 'Electronics', 'East', 1200.00, '2023-01-15'),
        (2, 'Shirt', 'Clothing', 'West', 50.00, '2023-01-16'),
        (3, 'Headphones', 'Electronics', 'East', 150.00, '2023-01-17'),
        (4, 'Book', 'Education', 'North', 25.00, '2023-01-18'),
        (5, 'Phone', 'Electronics', 'South', 800.00, '2023-01-19')
    """)
    print("示例数据插入完成")

def basic_query_demo(conn):
    """基础查询演示"""
    print("\n=== 基础查询演示 ===")
    
    # 简单查询
    result = conn.execute("""
        SELECT region, SUM(sales_amount) as total_sales
        FROM sales
        GROUP BY region
        ORDER BY total_sales DESC
    """).df()
    print("各地区销售总额:")
    print(result)

def show_tables(conn):
    """显示数据库中的表"""
    print("\n=== 数据库中的表 ===")
    tables = conn.execute("SHOW TABLES").df()
    print(tables)

def main():
    print("🚀 Hello DuckDB - 基本操作演示")
    print("=" * 50)
    
    # 连接到数据库
    conn = connect_to_db()
    
    # 显示当前表
    show_tables(conn)
    
    # 创建示例表
    create_sample_table(conn)
    
    # 显示更新后的表
    show_tables(conn)
    
    # 执行基础查询演示
    basic_query_demo(conn)
    
    # 关闭连接
    conn.close()
    print("\n✅ 演示完成，数据库连接已关闭")

if __name__ == "__main__":
    main()