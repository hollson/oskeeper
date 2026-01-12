"""
性能测试模块
测试DuckDB在大数据量下的性能表现
"""

import duckdb
import pandas as pd
import time
from tqdm import tqdm
import os

def performance_insert_test(conn, row_counts=[1000, 5000, 10000]):
    """测试不同数据量的插入性能"""
    print("\n⚡ 插入性能测试")
    
    results = []
    for row_count in row_counts:
        print(f"测试插入 {row_count} 行数据...")
        
        # 生成测试数据
        import random
        from datetime import datetime, timedelta
        
        data = {
            "id": list(range(1, row_count + 1)),
            "name": [f"User_{i}" for i in range(1, row_count + 1)],
            "value": [random.uniform(1, 1000) for _ in range(row_count)],
            "category": [random.choice(['A', 'B', 'C', 'D']) for _ in range(row_count)],
            "date": [(datetime.now() - timedelta(days=random.randint(0, 365))).strftime('%Y-%m-%d') for _ in range(row_count)]
        }
        
        df = pd.DataFrame(data)
        
        # 测试插入时间
        start_time = time.time()
        conn.execute(f"CREATE OR REPLACE TABLE test_table_{row_count} AS SELECT * FROM df")
        insert_time = time.time() - start_time
        
        results.append({
            'rows': row_count,
            'insert_time': round(insert_time, 4),
            'rows_per_second': int(row_count / insert_time) if insert_time > 0 else 0
        })
        
        print(f"  插入 {row_count} 行用时: {insert_time:.4f} 秒, 速度: {results[-1]['rows_per_second']} 行/秒")
    
    return results

def performance_query_test(conn, row_counts=[1000, 5000, 10000]):
    """测试不同数据量的查询性能"""
    print("\n🔍 查询性能测试")
    
    results = []
    for row_count in row_counts:
        table_name = f"test_table_{row_count}"
        if conn.execute(f"SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '{table_name}'").fetchone()[0] == 0:
            continue  # 跳过不存在的表
            
        print(f"测试查询 {row_count} 行数据...")
        
        # 简单查询测试
        start_time = time.time()
        simple_result = conn.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()[0]
        simple_time = time.time() - start_time
        
        # 聚合查询测试
        start_time = time.time()
        agg_result = conn.execute(f"""
            SELECT category, COUNT(*) as count, AVG(value) as avg_value
            FROM {table_name}
            GROUP BY category
        """).fetchall()
        agg_time = time.time() - start_time
        
        # 过滤查询测试
        start_time = time.time()
        filter_result = conn.execute(f"""
            SELECT * FROM {table_name}
            WHERE value > 500
            ORDER BY value DESC
        """).fetchall()
        filter_time = time.time() - start_time
        
        results.append({
            'rows': row_count,
            'simple_query_time': round(simple_time, 4),
            'aggregate_query_time': round(agg_time, 4),
            'filter_query_time': round(filter_time, 4)
        })
        
        print(f"  简单查询用时: {simple_time:.4f}s")
        print(f"  聚合查询用时: {agg_time:.4f}s") 
        print(f"  过滤查询用时: {filter_time:.4f}s")
    
    return results

def performance_large_dataset_test():
    """大数据集性能测试"""
    print("\n📊 大数据集性能测试")
    
    # 连接到数据库
    conn = duckdb.connect("hello_duckdb.duckdb")
    
    # 生成大数据集
    print("生成大数据集 (100,000 行)...")
    import random
    from datetime import datetime, timedelta
    
    large_data = {
        "user_id": [f"user_{random.randint(1, 5000)}" for _ in range(100000)],
        "product_id": [f"prod_{random.randint(1, 1000)}" for _ in range(100000)],
        "category": [random.choice(['Electronics', 'Clothing', 'Home', 'Food', 'Books']) for _ in range(100000)],
        "price": [round(random.uniform(10, 500), 2) for _ in range(100000)],
        "quantity": [random.randint(1, 5) for _ in range(100000)],
        "date": [(datetime.now() - timedelta(days=random.randint(0, 365))).strftime('%Y-%m-%d') for _ in range(100000)]
    }
    
    large_df = pd.DataFrame(large_data)
    
    # 测试批量插入性能
    print("测试批量插入性能...")
    start_time = time.time()
    conn.execute("CREATE OR REPLACE TABLE large_test_table AS SELECT * FROM large_df")
    insert_time = time.time() - start_time
    
    print(f"插入 100,000 行数据用时: {insert_time:.4f} 秒, 速度: {int(100000/insert_time)} 行/秒")
    
    # 测试复杂查询性能
    print("\n测试复杂查询性能...")
    
    # 聚合查询
    start_time = time.time()
    agg_result = conn.execute("""
        SELECT 
            category,
            COUNT(*) as order_count,
            SUM(price * quantity) as total_revenue,
            AVG(price) as avg_price
        FROM large_test_table
        GROUP BY category
        ORDER BY total_revenue DESC
    """).df()
    agg_time = time.time() - start_time
    
    print(f"复杂聚合查询用时: {agg_time:.4f} 秒")
    print("聚合结果预览:")
    print(agg_result)
    
    # 连接查询
    start_time = time.time()
    join_result = conn.execute("""
        SELECT 
            ltt.category,
            COUNT(DISTINCT ltt.user_id) as unique_users,
            AVG(ltt.price) as avg_price
        FROM large_test_table ltt
        GROUP BY ltt.category
        HAVING COUNT(DISTINCT ltt.user_id) > 100
        ORDER BY unique_users DESC
    """).df()
    join_time = time.time() - start_time
    
    print(f"连接查询用时: {join_time:.4f} 秒")
    print("连接查询结果预览:")
    print(join_result.head())
    
    # 测试更新性能
    print("\n测试更新性能...")
    start_time = time.time()
    conn.execute("""
        UPDATE large_test_table
        SET price = price * 1.1
        WHERE category = 'Electronics'
    """)
    update_time = time.time() - start_time
    
    print(f"更新电子产品价格用时: {update_time:.4f} 秒")
    
    # 测试删除性能
    print("\n测试删除性能...")
    start_time = time.time()
    conn.execute("""
        DELETE FROM large_test_table
        WHERE date < '2023-06-01'
    """)
    delete_time = time.time() - start_time
    
    remaining_count = conn.execute("SELECT COUNT(*) FROM large_test_table").fetchone()[0]
    print(f"删除历史数据用时: {delete_time:.4f} 秒, 剩余记录数: {remaining_count}")
    
    # 关闭连接
    conn.close()
    
    return {
        'insert_time': insert_time,
        'agg_query_time': agg_time,
        'join_query_time': join_time,
        'update_time': update_time,
        'delete_time': delete_time
    }

def performance_comparison_test():
    """性能对比测试 - DuckDB vs Pandas"""
    print("\n⚖️ DuckDB vs Pandas 性能对比测试")
    
    import random
    from datetime import datetime, timedelta
    
    # 生成测试数据
    print("生成测试数据集 (50,000 行)...")
    test_data = {
        "user_id": [f"user_{random.randint(1, 1000)}" for _ in range(50000)],
        "category": [random.choice(['A', 'B', 'C', 'D', 'E']) for _ in range(50000)],
        "value": [random.uniform(1, 100) for _ in range(50000)],
        "quantity": [random.randint(1, 10) for _ in range(50000)]
    }
    
    df = pd.DataFrame(test_data)
    
    # DuckDB 测试
    print("使用 DuckDB 进行聚合操作...")
    conn = duckdb.connect()
    conn.execute("CREATE TABLE test_data AS SELECT * FROM df")
    
    start_time = time.time()
    duckdb_result = conn.execute("""
        SELECT 
            category,
            COUNT(*) as count,
            AVG(value) as avg_value,
            SUM(value * quantity) as total_value
        FROM test_data
        GROUP BY category
        ORDER BY total_value DESC
    """).df()
    duckdb_time = time.time() - start_time
    
    print(f"DuckDB 聚合用时: {duckdb_time:.4f} 秒")
    
    # Pandas 测试
    print("使用 Pandas 进行相同聚合操作...")
    start_time = time.time()
    pandas_result = df.groupby('category').agg({
        'user_id': 'count',
        'value': 'mean',
        'quantity': lambda x: (df.loc[x.index, 'value'] * x).sum()
    }).reset_index()
    pandas_result.columns = ['category', 'count', 'avg_value', 'total_value']
    pandas_result = pandas_result.sort_values('total_value', ascending=False)
    pandas_time = time.time() - start_time
    
    print(f"Pandas 聚合用时: {pandas_time:.4f} 秒")
    
    # 性能对比
    speedup = pandas_time / duckdb_time if duckdb_time > 0 else float('inf')
    print(f"DuckDB 比 Pandas 快 {speedup:.2f} 倍")
    
    # 显示结果
    print("\nDuckDB 结果:")
    print(duckdb_result)
    print("\nPandas 结果:")
    print(pandas_result)
    
    # 关闭连接
    conn.close()
    
    return {
        'duckdb_time': duckdb_time,
        'pandas_time': pandas_time,
        'speedup': speedup
    }

def performance_full_test():
    """完整性能测试"""
    print("\n🚀 完整性能测试")
    print("=" * 50)
    
    # 执行各项性能测试
    print("开始大数据集性能测试...")
    large_test_results = performance_large_dataset_test()
    
    print("\n开始性能对比测试...")
    comparison_results = performance_comparison_test()
    
    # 汇总结果
    print("\n📋 性能测试汇总:")
    print(f"大数据集插入性能: {large_test_results['insert_time']:.4f} 秒")
    print(f"复杂聚合查询性能: {large_test_results['agg_query_time']:.4f} 秒")
    print(f"连接查询性能: {large_test_results['join_query_time']:.4f} 秒")
    print(f"更新操作性能: {large_test_results['update_time']:.4f} 秒")
    print(f"删除操作性能: {large_test_results['delete_time']:.4f} 秒")
    print(f"DuckDB vs Pandas 速度提升: {comparison_results['speedup']:.2f} 倍")
    
    print("\n✅ 性能测试完成")

if __name__ == "__main__":
    performance_full_test()