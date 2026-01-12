"""
数据处理模块
演示从文件加载数据、批量写入等操作
"""

import duckdb
import pandas as pd
import os

def load_from_csv(conn, csv_path):
    """从CSV文件加载数据到表"""
    print(f"从CSV文件加载数据: {csv_path}")
    
    # 检查文件是否存在
    if not os.path.exists(csv_path):
        print(f"文件不存在: {csv_path}")
        return False
    
    # 从CSV创建或替换表
    conn.execute(f"""
        CREATE OR REPLACE TABLE sales_from_csv AS 
        SELECT * FROM read_csv_auto('{csv_path}', header=True)
    """)
    
    # 获取记录数
    count = conn.execute("SELECT COUNT(*) FROM sales_from_csv").fetchone()[0]
    print(f"成功加载 {count} 条记录")
    return True

def load_from_parquet(conn, parquet_path):
    """从Parquet文件加载数据到表"""
    print(f"从Parquet文件加载数据: {parquet_path}")
    
    if not os.path.exists(parquet_path):
        print(f"文件不存在: {parquet_path}")
        return False
    
    conn.execute(f"""
        CREATE OR REPLACE TABLE sales_from_parquet AS 
        SELECT * FROM read_parquet('{parquet_path}')
    """)
    
    count = conn.execute("SELECT COUNT(*) FROM sales_from_parquet").fetchone()[0]
    print(f"成功加载 {count} 条记录")
    return True

def generate_large_dataset(rows=100000):
    """生成大数据集用于性能测试"""
    print(f"生成包含 {rows} 行的大数据集...")
    
    import random
    from datetime import datetime, timedelta
    import pandas as pd
    
    # 生成随机数据
    categories = ['Electronics', 'Clothing', 'Home', 'Food', 'Books']
    products = ['Laptop', 'Phone', 'Shirt', 'Desk', 'Apple', 'Novel', 'Headphones', 'Watch', 'Chair', 'Cookbook']
    regions = ['North', 'South', 'East', 'West', 'Central']
    
    data = {
        "user_id": [f"user_{random.randint(1, 1000)}" for _ in range(rows)],
        "product": [random.choice(products) for _ in range(rows)],
        "category": [random.choice(categories) for _ in range(rows)],
        "price": [round(random.uniform(10, 1000), 2) for _ in range(rows)],
        "quantity": [random.randint(1, 10) for _ in range(rows)],
        "region": [random.choice(regions) for _ in range(rows)],
        "date": [(datetime.now() - timedelta(days=random.randint(0, 365))).strftime('%Y-%m-%d') for _ in range(rows)]
    }
    
    df = pd.DataFrame(data)
    return df

def bulk_insert_from_dataframe(conn, df, table_name="large_sales"):
    """从DataFrame批量插入数据"""
    print(f"从DataFrame批量插入数据到表 {table_name}...")
    
    # 创建表并插入数据
    conn.execute(f"CREATE OR REPLACE TABLE {table_name} AS SELECT * FROM df")
    
    count = conn.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()[0]
    print(f"成功插入 {count} 条记录到表 {table_name}")
    return True

def create_sample_csv():
    """创建示例CSV文件"""
    sample_data = {
        "order_id": [101, 102, 103, 104, 105],
        "product": ["Tablet", "Jacket", "Blender", "Magazine", "Smartphone"],
        "category": ["Electronics", "Clothing", "Home", "Education", "Electronics"],
        "region": ["North", "South", "East", "West", "Central"],
        "sales_amount": [300.00, 85.00, 120.00, 15.00, 650.00],
        "date": ["2023-02-01", "2023-02-02", "2023-02-03", "2023-02-04", "2023-02-05"]
    }
    
    df = pd.DataFrame(sample_data)
    df.to_csv("data/sample_sales.csv", index=False)
    print("示例CSV文件已创建: data/sample_sales.csv")

def demo_data_processing():
    """演示数据处理功能"""
    print("\n🚀 数据处理演示")
    print("=" * 50)
    
    # 连接到数据库
    conn = duckdb.connect("hello_duckdb.duckdb")
    
    # 创建示例CSV文件
    create_sample_csv()
    
    # 从CSV加载数据
    load_from_csv(conn, "data/sample_sales.csv")
    
    # 显示从CSV加载的数据
    print("\n从CSV加载的数据:")
    result = conn.execute("SELECT * FROM sales_from_csv").df()
    print(result.head())
    
    # 生成并插入大数据集
    large_df = generate_large_dataset(10000)  # 生成1万条记录以节省时间
    bulk_insert_from_dataframe(conn, large_df, "demo_large_sales")
    
    # 显示大数据集的部分信息
    print(f"\n大数据集统计信息:")
    stats = conn.execute("""
        SELECT 
            COUNT(*) as total_records,
            AVG(price) as avg_price,
            MIN(price) as min_price,
            MAX(price) as max_price,
            SUM(price * quantity) as total_revenue
        FROM demo_large_sales
    """).df()
    print(stats)
    
    # 按类别分组统计
    print(f"\n按类别统计:")
    category_stats = conn.execute("""
        SELECT 
            category,
            COUNT(*) as record_count,
            AVG(price) as avg_price,
            SUM(price * quantity) as total_revenue
        FROM demo_large_sales
        GROUP BY category
        ORDER BY total_revenue DESC
    """).df()
    print(category_stats)
    
    # 关闭连接
    conn.close()
    print("\n✅ 数据处理演示完成")

if __name__ == "__main__":
    # 确保数据目录存在
    os.makedirs("data", exist_ok=True)
    demo_data_processing()