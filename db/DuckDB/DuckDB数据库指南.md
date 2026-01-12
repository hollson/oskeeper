# DuckDB 数据库指南

[TOC]



## 💾 一. DuckDB 介绍

**[DuckDB](https://duckdb.org/)** 是一个嵌入式的SQL OLAP数据库管理系统，专为分析工作负载而设计。它采用列式存储和向量化执行引擎，特别适合本地数据分析和大数据量处理。

**核心优势：**

- ⚡️ **高性能**：采用列式存储和向量化执行引擎，对聚合查询和过滤操作有卓越性能
- 💾 **零依赖**：单文件数据库，无需服务器进程，所有数据存储在一个文件中
- 📁 **多格式支持**：直接读取 CSV、Parquet、JSON 等文件格式，无需预处理
- 🔌 **生态集成**：与 Python、R、JavaScript 等语言无缝集成，支持 Pandas、Arrow 等库
- 📊 **分析优化**：针对分析型查询（OLAP）优化，适合数据科学和BI场景
- 🔄 **事务支持**：支持 ACID 事务，确保数据一致性



<br/>



## ⚙️ 二. 安装与配置

### 2.1 安装 DuckDB

```bash
pip install duckdb pandas plotly pyarrow tqdm  # 可选：pandas 用于数据处理，plotly 用于可视化
```

### 2.2 验证安装

```python
import duckdb
print(duckdb.__version__)  # 输出当前版本号
```

### 2.3 数据库客户端

- 推荐使用 VSCode 插件：**DBCODE**。




<br/>



## 📙 三. 基础操作

### 3.1 创建连接

```python
import duckdb

# 连接到内存数据库（临时）
conn = duckdb.connect()

# 连接到持久化数据库文件
conn = duckdb.connect("my_database.duckdb")

# 使用内存模式（不保存数据）
conn = duckdb.connect(":memory:")
```

### 3.2 基本操作

**创建表和插入数据**

```python
# 创建表
conn.execute("""
    CREATE TABLE sales (
        order_id INTEGER,
        product VARCHAR,
        category VARCHAR,
        region VARCHAR,
        sales_amount DECIMAL(10,2),
        date DATE
    )
""")

# 插入数据
conn.execute("""
    INSERT INTO sales VALUES 
    (1, 'Laptop', 'Electronics', 'East', 1200.00, '2023-01-15'),
    (2, 'Shirt', 'Clothing', 'West', 50.00, '2023-01-16'),
    (3, 'Headphones', 'Electronics', 'East', 150.00, '2023-01-17')
""")
```

**从文件直接加载数据**

```python
# 从CSV直接加载（无需预创建表）
conn.execute("""
    CREATE OR REPLACE TABLE sales AS 
    SELECT * FROM read_csv_auto('data/sales.csv', header=True)
""")

# 从Parquet加载
conn.execute("""
    CREATE OR REPLACE TABLE sales AS 
    SELECT * FROM read_parquet('data/sales.parquet')
""")
```

### 3.3 查询分析

**基础查询**

```python
# 简单查询
result = conn.execute("""
    SELECT region, SUM(sales_amount) as total_sales
    FROM sales
    GROUP BY region
    ORDER BY total_sales DESC
""").df()  # 直接转为 Pandas DataFrame
print(result)
```

**高级分析查询**

```python
# 复杂聚合查询
category_stats = conn.execute("""
    SELECT 
        category,
        AVG(sales_amount) as avg_sales,
        MIN(sales_amount) as min_sales,
        MAX(sales_amount) as max_sales,
        COUNT(*) as order_count
    FROM sales
    GROUP BY category
""").df()

# 条件查询
high_value_orders = conn.execute("""
    SELECT *
    FROM sales
    WHERE sales_amount > 100
    ORDER BY sales_amount DESC
    LIMIT 10
""").df()
```

### 3.4 结果导出

```python
# 导出为Parquet
conn.execute("""
    COPY (
        SELECT * FROM sales WHERE sales_amount > 100
    ) TO 'output/high_value_orders.parquet' (FORMAT 'parquet')
""")

# 导出为CSV
conn.execute("""
    COPY (
        SELECT * FROM sales WHERE sales_amount > 100
    ) TO 'output/high_value_orders.csv' (HEADER, DELIMITER ',')
""")

# 转换为Pandas DataFrame
df = conn.execute("SELECT * FROM sales").df()
```



<br/>



## 🚀 四. 高级特性

### 4.1 批量写入

**量写入优化**

```python
import pandas as pd
import time

# 生成大数据集
def generate_large_dataset(rows=1_000_000):
    data = {
        "user_id": [f"user_{i % 1000}" for i in range(rows)],
        "product_id": [f"prod_{i % 500}" for i in range(rows)],
        "category": ["Electronics", "Clothing", "Home", "Food"][i % 4] for i in range(rows)],
        "price": [round((i % 100) + 10, 2) for i in range(rows)],
        "quantity": [i % 5 + 1 for i in range(rows)],
        "timestamp": [pd.Timestamp.now() - pd.Timedelta(days=i % 365) for i in range(rows)],
    }
    return pd.DataFrame(data)

# 批量写入（推荐方法）
def bulk_insert_optimized():
    df = generate_large_dataset(1_000_000)
    
    # 方法1：直接从DataFrame写入
    conn.execute("CREATE TABLE sales_large AS SELECT * FROM df")
    
    # 方法2：先保存为CSV再批量导入（更高效）
    df.to_csv("temp_large_data.csv", index=False)
    conn.execute("""
        COPY sales_large FROM 'temp_large_data.csv' WITH (header=True, delimiter=',');
    """)
```

**使用COPY命令的优势**

| 操作 | DuckDB耗时 | Pandas耗时 | 备注 |
|------|------------|------------|------|
| 从CSV导入 | 2.5秒 | 8.2秒 | `COPY FROM` 批量优化 |
| 按类别聚合 | 0.8秒 | 3.1秒 | 向量化执行引擎 |
| 更新10万行数据 | 1.2秒 | 5.7秒 | 事务支持 |
| 导出为Parquet | 0.5秒 | 2.0秒 | 原生支持高效序列化 |

### 4.2 高效查询

**聚合查询优化**

```python
# 利用向量化执行引擎的聚合查询
result = conn.execute("""
    SELECT 
        category,
        SUM(price * quantity) as total_sales,
        AVG(price) as avg_price,
        COUNT(*) as order_count,
        MIN(timestamp) as first_sale,
        MAX(timestamp) as last_sale
    FROM sales_large
    GROUP BY category
    ORDER BY total_sales DESC
""").df()

# 复杂条件过滤
high_value_customers = conn.execute("""
    SELECT 
        user_id,
        SUM(price * quantity) as total_spent,
        COUNT(DISTINCT product_id) as unique_products
    FROM sales_large
    GROUP BY user_id
    HAVING total_spent > 1000
    ORDER BY total_spent DESC
    LIMIT 10
""").df()
```

**连接查询优化**

```python
# 表连接查询
conn.execute("""
    CREATE TABLE customers AS 
    SELECT DISTINCT user_id, 
           CONCAT('Customer_', user_id) as customer_name
    FROM sales_large
""")

joined_result = conn.execute("""
    SELECT 
        c.customer_name,
        s.category,
        SUM(s.price * s.quantity) as total_spending
    FROM sales_large s
    JOIN customers c ON s.user_id = c.user_id
    GROUP BY c.customer_name, s.category
    ORDER BY total_spending DESC
    LIMIT 20
""").df()
```

### 4.3 更新删除

**事务支持的数据修改**

```python
# 更新操作（带事务）
def update_with_transaction():
    try:
        # 开始事务
        conn.execute("BEGIN TRANSACTION;")
        
        # 执行更新操作
        conn.execute("""
            UPDATE sales_large
            SET price = price * 0.9
            WHERE category = 'Electronics';
        """)
        
        # 提交事务
        conn.execute("COMMIT;")
        print("更新成功完成！")
        
        # 验证更新结果
        updated_price = conn.execute("""
            SELECT AVG(price) as avg_price
            FROM sales_large
            WHERE category = 'Electronics'
        """).fetchone()[0]
        print(f"Electronics平均价格: {updated_price:.2f}")
        
    except Exception as e:
        # 回滚事务
        conn.execute("ROLLBACK;")
        print(f"更新失败，已回滚: {e}")

# 删除操作
def delete_old_records():
    start_time = time.time()
    
    # 删除特定条件的数据
    conn.execute("""
        DELETE FROM sales_large
        WHERE timestamp < '2023-01-01'
    """)
    conn.commit()
    
    elapsed = time.time() - start_time
    print(f"删除完成！耗时: {elapsed:.2f}秒")
    
    # 验证删除结果
    remaining_rows = conn.execute("SELECT COUNT(*) FROM sales_large").fetchone()[0]
    print(f"剩余行数: {remaining_rows}")
```

### 4.4 增量与追加

```python
# 增量数据追加
def append_new_data():
    # 生成新数据
    new_data = generate_large_dataset(100_000)
    new_data.to_csv("new_sales_data.csv", index=False)
    
    start_time = time.time()
    
    # 追加到现有表
    conn.execute("""
        COPY sales_large FROM 'new_sales_data.csv' WITH (header=True, delimiter=',');
    """)
    conn.commit()
    
    elapsed = time.time() - start_time
    print(f"追加完成！耗时: {elapsed:.2f}秒")
    
    # 验证总行数
    total_rows = conn.execute("SELECT COUNT(*) FROM sales_large").fetchone()[0]
    print(f"总行数: {total_rows}")
```



<br/>



## 🛠️ 五. 应用案例

### 5.1 销售数据分析

**项目结构**

```shell
sales_analysis/
├── data/
│   └── sales.csv          # 原始数据
├── output/
│   └── results.parquet    # 分析结果
└── analyze_sales.py       # 主程序
```

**主程序实现**

```python
import duckdb
import pandas as pd
import plotly.express as px

def load_data():
    # 从 CSV 加载数据到 DuckDB（无需显式创建表）
    conn = duckdb.connect("sales_analysis.duckdb")  # 单文件数据库
    conn.execute("""
        CREATE OR REPLACE TABLE sales AS 
        SELECT * FROM read_csv_auto('data/sales.csv', header=True)
    """)
    return conn

def analyze_sales(conn):
    # 示例1：按地区统计总销售额
    region_sales = conn.execute("""
        SELECT region, SUM(sales_amount) as total_sales
        FROM sales
        GROUP BY region
        ORDER BY total_sales DESC
    """).df()  # 直接转为 Pandas DataFrame

    # 示例2：按产品类别统计平均销售额
    category_avg = conn.execute("""
        SELECT category, AVG(sales_amount) as avg_sales
        FROM sales
        GROUP BY category
    """).df()

    return region_sales, category_avg

def visualize(region_sales):
    # 可选：用 Plotly 可视化
    fig = px.bar(region_sales, x="region", y="total_sales", title="Sales by Region")
    fig.show()

def save_results(conn):
    # 将查询结果导出为 Parquet 文件
    conn.execute("""
        COPY (SELECT * FROM sales WHERE sales_amount > 100) 
        TO 'output/high_value_orders.parquet' (FORMAT 'parquet')
    """)

def main():
    conn = load_data()
    region_sales, category_avg = analyze_sales(conn)
    
    print("=== Sales by Region ===")
    print(region_sales)
    
    print("\n=== Avg Sales by Category ===")
    print(category_avg)
    
    visualize(region_sales)  # 可视化（可选）
    save_results(conn)      # 导出数据
    
    conn.close()

if __name__ == "__main__":
    main()
```

### 5.2 大数据量分析

**完整的CRUD操作示例**

```python
import duckdb
import pandas as pd
from tqdm import tqdm
import time

# 初始化数据库连接（单文件存储）
DB_PATH = "big_data_analysis.duckdb"
conn = duckdb.connect(DB_PATH)

def full_crud_demo():
    print("=== DuckDB 大数据量 CRUD 操作演示 ===\n")
    
    # 1. 批量写入数据
    print("1. 批量写入数据...")
    bulk_insert_optimized()
    
    # 2. 查询数据
    print("\n2. 执行查询操作...")
    query_data()
    
    # 3. 更新数据
    print("\n3. 执行更新操作...")
    update_with_transaction()
    
    # 重新查询验证更新
    print("\n4. 验证更新结果...")
    query_data()
    
    # 5. 删除部分数据
    print("\n5. 执行删除操作...")
    delete_old_records()
    
    # 6. 增量写入
    print("\n6. 执行增量写入...")
    append_new_data()
    
    # 7. 导出结果
    print("\n7. 导出分析结果...")
    export_analysis_results()
    
    print("\n所有操作完成！")

def export_analysis_results():
    # 导出高价值客户到Parquet
    conn.execute("""
        COPY (
            SELECT user_id, total_spent
            FROM (
                SELECT user_id, SUM(price * quantity) as total_spent
                FROM sales_large
                GROUP BY user_id
                HAVING total_spent > 500
            )
        ) TO 'data/processed/high_value_customers.parquet' (FORMAT 'parquet');
    """)
    print("高价值客户数据已导出到 data/processed/high_value_customers.parquet")

# 运行演示
full_crud_demo()
```

### 5.3 性能监控案例

在性能采集场景中，一个程序持续采集指标并写入数据库，同时允许其他程序查询和分析数据。DuckDB 支持这种多连接使用模式，适合构建实时监控系统。

**核心过程**：

- 一个进程负责数据写入（如定时采集指标）
- 另一个进程负责数据查询（如实时分析、报表生成）
- 通过独立连接避免读写冲突

**项目结构**

```shell
perf_monitor/
├── data/
│   └── system_metrics.csv    # 原始数据
├── output/
│   └── reports.parquet       # 分析报告
└── perf_monitor.py           # 性能监控主程序
```

**简化示例代码**：

```python
import duckdb
import threading
import time
from datetime import datetime

def data_writer(db_path):
    """数据写入函数"""
    conn = duckdb.connect(db_path)
    timestamp = datetime.now()
    # 模拟写入一些指标
    conn.execute("INSERT INTO metrics VALUES (?, ?)", [timestamp, 85.5])
    conn.close()
    print(f"数据已写入: {timestamp}")

def data_reader(db_path):
    """数据读取函数"""
    conn = duckdb.connect(db_path)
    result = conn.execute("SELECT COUNT(*) FROM metrics").fetchone()[0]
    conn.close()
    print(f"当前记录数: {result}")

# 在不同线程中使用独立连接
writer_thread = threading.Thread(target=data_writer, args=["monitor.duckdb"])
reader_thread = threading.Thread(target=data_reader, args=["monitor.duckdb"])

writer_thread.start()
reader_thread.start()

writer_thread.join()
reader_thread.join()
```

**核心要点**：

- 每个线程或进程应创建独立的数据库连接
- 使用后及时关闭连接，避免连接泄漏
- DuckDB支持事务，确保数据一致性
- 虽然DuckDB是单线程引擎，但多连接模式下仍能有效支持读写分离场景




<br/>



## 🏆 六. 性能优化

### 6.1 写入优化

**批量写入优先**：

- 使用 `COPY FROM` 命令（比逐行 `INSERT` 快10倍以上）
- 支持从 CSV/Parquet 直接导入，无需先加载到 Pandas

**数据类型优化**：

- 明确定义列的数据类型，避免 DuckDB 自动推断
- 使用合适的数据类型（如 VARCHAR 长度限制）

### 6.2 查询优化

**利用向量化执行**：

- 对聚合查询（如 `SUM`/`GROUP BY`）自动使用向量化执行
- 对过滤条件（如 `WHERE category = 'Electronics'`）自动优化

**索引与分区**：

- 虽然 DuckDB 没有传统索引，但其列式存储本身提供了良好的查询性能
- 可考虑按时间分区（如 `PARTITION BY DATE(timestamp)`）加速历史数据查询

### 6.3 事务一致性

**事务支持**：

- 通过 `BEGIN/COMMIT` 确保数据一致性
- 适合需要原子性操作的场景（如金融数据更新）

### 6.4 并发与多连接

**DuckDB 并发模型**：

- DuckDB 是单线程数据库引擎，但支持多连接访问
- 不是多线程并发，而是通过独立连接实现并发访问
- 同一进程内多个连接可以同时访问数据库，但操作是串行执行的

**单连接性能**：

- DuckDB 在单连接场景下性能卓越，特别适合分析型查询
- 利用向量化执行引擎，聚合查询和过滤操作速度极快
- 适合数据科学、BI分析等场景

**多连接使用场景**：

- 一个进程负责数据写入（如定时采集指标）
- 另一个进程负责数据查询（如实时分析、报表生成）
- 通过独立连接避免读写冲突

**并发最佳实践**：

- 为每个线程/任务创建独立的连接
- 避免共享连接对象，防止并发访问问题
- 合理管理连接生命周期，及时关闭连接
- 对于高并发场景，考虑使用连接池或切换到支持多线程的数据库



<br/>



## 🎓 七. 场景与限制

### 7.1 适合场景

- **单机大数据量**：GB级数据的增删改查
- **快速聚合分析**：日志分析、用户行为分析等场景
- **数据科学工作流**：与 Pandas/Polars 生态无缝集成
- **本地分析工具**：无需部署服务器的数据分析应用
- **ETL 流程**：高效的数据提取、转换和加载

### 7.2 不适合场景

- **多机分布式写入**：需要使用 ClickHouse/Snowflake 等分布式系统
- **高并发点查询**：DuckDB 优化目标是分析型负载，而非高并发OLTP
- **大型Web应用后端**：更适合传统的客户端-服务器数据库



<br/>



## 📚 八. 扩展建议

### 8.1 高级功能

- **分区表**：按时间分区（如 `PARTITION BY DATE(timestamp)`）加速历史数据查询
- **物化视图**：对常用聚合查询预计算结果
- **并行查询**：通过 `SET parallel_enabled=true` 启用多核并行（DuckDB 0.9+）

### 8.2 性能监控

```python
# 启用查询性能分析
conn.execute("PRAGMA enable_profiling='query_profile';")

# 查看查询计划
conn.execute("EXPLAIN SELECT * FROM sales WHERE category = 'Electronics';")
```

### 8.3 工具集成

- **与Jupyter Notebook集成**：直接在Notebook中进行数据分析
- **与Streamlit集成**：构建交互式数据仪表盘
- **定时任务集成**：使用 `schedule` 库自动更新数据

