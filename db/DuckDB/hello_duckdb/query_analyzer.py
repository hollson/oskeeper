"""
查询分析模块
演示复杂查询、聚合分析、连接查询等高级功能
"""

import duckdb
import pandas as pd

def advanced_aggregation_query(conn):
    """高级聚合查询演示"""
    print("\n🔍 高级聚合查询演示")
    
    result = conn.execute("""
        SELECT 
            category,
            SUM(price * quantity) as total_sales,
            AVG(price) as avg_price,
            COUNT(*) as order_count,
            MIN(date) as first_sale,
            MAX(date) as last_sale
        FROM demo_large_sales
        GROUP BY category
        ORDER BY total_sales DESC
    """).df()
    
    print("各类别销售统计:")
    print(result)

def complex_filtering_query(conn):
    """复杂条件过滤查询"""
    print("\n🔍 复杂条件过滤查询")
    
    high_value_customers = conn.execute("""
        SELECT 
            user_id,
            SUM(price * quantity) as total_spent,
            COUNT(DISTINCT product) as unique_products,
            AVG(price) as avg_purchase
        FROM demo_large_sales
        GROUP BY user_id
        HAVING total_spent > 5000
        ORDER BY total_spent DESC
        LIMIT 10
    """).df()
    
    print("高价值客户 (消费超过5000):")
    print(high_value_customers)

def join_query_demo(conn):
    """连接查询演示"""
    print("\n🔍 连接查询演示")
    
    # 创建客户表
    conn.execute("""
        CREATE OR REPLACE TABLE customers AS 
        SELECT DISTINCT user_id, 
               CONCAT('Customer_', SUBSTRING(user_id, 6)) as customer_name
        FROM demo_large_sales
        LIMIT 50
    """)
    
    joined_result = conn.execute("""
        SELECT 
            c.customer_name,
            d.category,
            SUM(d.price * d.quantity) as total_spending
        FROM demo_large_sales d
        JOIN customers c ON d.user_id = c.user_id
        GROUP BY c.customer_name, d.category
        ORDER BY total_spending DESC
        LIMIT 20
    """).df()
    
    print("客户-类别消费详情 (前20):")
    print(joined_result)

def time_series_analysis(conn):
    """时间序列分析"""
    print("\n📅 时间序列分析")
    
    monthly_sales = conn.execute("""
        SELECT 
            strftime('%Y-%m', date::DATE) as month,
            SUM(price * quantity) as monthly_revenue,
            COUNT(*) as transaction_count,
            AVG(price * quantity) as avg_transaction_value
        FROM demo_large_sales
        GROUP BY strftime('%Y-%m', date::DATE)
        ORDER BY month
    """).df()
    
    print("月度销售趋势:")
    print(monthly_sales)

def top_products_analysis(conn):
    """热门产品分析"""
    print("\n🏆 热门产品分析")
    
    top_products = conn.execute("""
        SELECT 
            product,
            category,
            COUNT(*) as purchase_frequency,
            SUM(quantity) as total_quantity_sold,
            SUM(price * quantity) as total_revenue,
            AVG(price) as avg_price
        FROM demo_large_sales
        GROUP BY product, category
        ORDER BY total_revenue DESC
        LIMIT 10
    """).df()
    
    print("最畅销产品 (按收入):")
    print(top_products)

def regional_analysis(conn):
    """区域分析"""
    print("\n🌍 区域销售分析")
    
    regional_stats = conn.execute("""
        SELECT 
            region,
            COUNT(*) as transaction_count,
            SUM(price * quantity) as total_revenue,
            AVG(price * quantity) as avg_transaction_value,
            COUNT(DISTINCT user_id) as unique_customers
        FROM demo_large_sales
        GROUP BY region
        ORDER BY total_revenue DESC
    """).df()
    
    print("各区域销售统计:")
    print(regional_stats)

def demo_query_analysis():
    """演示查询分析功能"""
    print("\n🚀 查询分析演示")
    print("=" * 50)
    
    # 连接到数据库
    conn = duckdb.connect("hello_duckdb.duckdb")
    
    # 执行各种查询分析
    advanced_aggregation_query(conn)
    complex_filtering_query(conn)
    join_query_demo(conn)
    time_series_analysis(conn)
    top_products_analysis(conn)
    regional_analysis(conn)
    
    # 关闭连接
    conn.close()
    print("\n✅ 查询分析演示完成")

if __name__ == "__main__":
    demo_query_analysis()