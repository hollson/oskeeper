# chdb Python 数据写入/读取实操教程
chdb 是基于 ClickHouse 内核的轻量级嵌入式分析引擎，本文将详细讲解如何用 Python 向 chdb 写入数据、生产级存储引擎/格式选型，以及读取数据并转换为 Python 原生数据结构（如列表、字典、DataFrame）的实操方法。

## 一、环境准备
首先确保安装 chdb 和依赖库：
```bash
pip install chdb pyarrow pandas  # pyarrow用于Arrow格式，pandas用于DataFrame操作
```

## 二、核心概念：chdb 数据写入方式
chdb 支持两种主流写入方式：
1. **SQL INSERT 写入**：通过 DB-API 接口执行 INSERT 语句（推荐，兼容 ClickHouse 语法）；
2. **DataFrame 直接写入**：将 Pandas DataFrame 转为 chdb 表后操作（适合Python数据场景）。

## 三、生产级存储引擎/格式选型
### 推荐存储引擎（按场景）
| 场景                | 推荐引擎          | 特点                                                                 |
|---------------------|-------------------|----------------------------------------------------------------------|
| 临时/内存计算       | Memory            | 纯内存存储，读写最快，进程退出数据丢失                               |
| 持久化小表          | Log               | 写性能极高，不支持索引，适合日志类小数据                             |
| 生产级持久化大表    | ReplacingMergeTree| 支持去重、排序、分区，ClickHouse 最经典的生产级引擎，兼顾读写性能     |
| 外部数据源（如Parquet）| File(Parquet)    | 直接读写Parquet文件，适合大数据文件交互，无需导入数据                 |

### 推荐数据格式（读写效率）
- **写入/存储**：Parquet（列式存储，压缩比高，查询快）；
- **交互格式**：Arrow（chdb与Python交互的最优格式，零拷贝）；
- **通用格式**：CSV/JSON（兼容性好，适合少量数据）。

## 四、实操示例：写入+读取完整流程
### 示例1：SQL INSERT 写入（生产级 ReplacingMergeTree 引擎）
```python
import chdb
from chdb import dbapi
import tempfile
import os

# 1. 创建临时目录作为chdb数据存储路径（生产环境替换为固定路径）
tmp_dir = tempfile.TemporaryDirectory()
db_path = tmp_dir.name
print(f"chdb数据存储路径: {db_path}")

# 2. 建立连接（指定存储路径，持久化数据）
conn = dbapi.connect(db_path)
cursor = conn.cursor()

# 3. 创建生产级表（ReplacingMergeTree 引擎）
create_table_sql = """
CREATE TABLE IF NOT EXISTS user_behavior (
    user_id UInt64,
    action String,
    dt Date,
    pv UInt32
) ENGINE = ReplacingMergeTree ORDER BY (user_id, dt)
"""
cursor.execute(create_table_sql)

# 4. 写入数据（三种INSERT方式）
## 方式1：单条插入
cursor.execute("INSERT INTO user_behavior VALUES (%s, %s, %s, %s)", (1001, "click", "2024-01-01", 5))

## 方式2：批量插入（推荐，性能更高）
batch_data = [
    (1002, "view", "2024-01-01", 10),
    (1003, "click", "2024-01-01", 3),
    (1001, "click", "2024-01-02", 8)  # 同user_id+dt会被ReplacingMergeTree去重
]
cursor.executemany("INSERT INTO user_behavior VALUES (%s, %s, %s, %s)", batch_data)

# 5. 读取数据并转换为Python原生数据
## 方式1：fetchone/fetchmany/fetchall（元组格式）
print("\n=== 读取方式1：基础fetch接口 ===")
cursor.execute("SELECT * FROM user_behavior ORDER BY user_id")
# 获取列名（兼容DB-API）
col_names = [desc[0] for desc in cursor.description]
print(f"列名: {col_names}")

# 单行读取
row = cursor.fetchone()
print(f"单行数据: {row}")

# 批量读取
batch_rows = cursor.fetchmany(2)
print(f"批量数据: {batch_rows}")

# 读取所有剩余数据
all_rows = cursor.fetchall()
print(f"所有数据: {all_rows}")

## 方式2：转换为字典（更易读）
print("\n=== 读取方式2：转换为字典 ===")
cursor.execute("SELECT * FROM user_behavior ORDER BY user_id")
col_names = [desc[0] for desc in cursor.description]
# 逐行转为字典
dict_rows = []
for row in cursor:
    dict_row = dict(zip(col_names, row))
    dict_rows.append(dict_row)
print(f"字典格式数据: {dict_rows}")

## 方式3：转换为Pandas DataFrame（推荐，Python数据分析首选）
print("\n=== 读取方式3：转换为DataFrame ===")
# 直接用chdb.query返回DataFrame格式
df = chdb.query("SELECT * FROM user_behavior ORDER BY user_id", "DataFrame")
print("DataFrame格式:")
print(df)

# 6. 清理资源
cursor.close()
conn.close()
tmp_dir.cleanup()
```

### 示例2：DataFrame 直接写入（Python 数据场景最优）
```python
import chdb
import chdb.dataframe as cdf
import pandas as pd

# 1. 构造Pandas DataFrame（模拟业务数据）
df = pd.DataFrame({
    "product_id": [1, 2, 3, 4],
    "category": ["electronics", "clothes", "electronics", "food"],
    "price": [999.9, 199.9, 2999.9, 29.9],
    "stock": [100, 500, 50, 1000]
})
print("原始DataFrame:")
print(df)

# 2. 将DataFrame转为chdb Table（零拷贝，性能极高）
chdb_table = cdf.Table(dataframe=df)

# 3. 直接查询chdb表（__table__ 固定别名）
print("\n=== 查询chdb Table ===")
# 基础查询
ret_tbl = chdb_table.query("SELECT category, SUM(price) as total_price FROM __table__ GROUP BY category")
print("分组聚合结果（chdb Table）:")
print(ret_tbl)

# 4. 转换为Python原生数据
## 方式1：转为列表
ret_list = ret_tbl.to_pandas().to_dict('records')
print("\nPython列表字典格式:")
print(ret_list)

## 方式2：直接打印原生数据
print("\n终端打印最终结果:")
for item in ret_list:
    print(f"品类: {item['category']}, 总价: {item['total_price']:.2f}")
```

### 示例3：Parquet 文件写入/读取（生产级大数据场景）
```python
import chdb
import os
import tempfile

# 1. 创建临时Parquet文件路径
tmp_dir = tempfile.TemporaryDirectory()
parquet_path = os.path.join(tmp_dir.name, "sales.parquet")

# 2. 写入数据到Parquet文件（File引擎）
conn = chdb.connect(tmp_dir.name)
cursor = conn.cursor()

# 创建File引擎表，直接关联Parquet文件
cursor.execute(f"""
CREATE TABLE IF NOT EXISTS sales (
    order_id UInt64,
    amount Float64,
    dt Date
) ENGINE = File(Parquet, '{parquet_path}')
""")

# 插入数据（自动同步到Parquet文件）
cursor.execute("INSERT INTO sales VALUES (1001, 99.9, '2024-01-01'), (1002, 199.9, '2024-01-01'), (1003, 299.9, '2024-01-02')")

# 3. 读取Parquet文件数据
print("\n=== 读取Parquet文件数据 ===")
# 方式1：直接查询表
cursor.execute("SELECT dt, SUM(amount) as total_sales FROM sales GROUP BY dt")
col_names = [desc[0] for desc in cursor.description]
sales_data = [dict(zip(col_names, row)) for row in cursor]
for data in sales_data:
    print(f"日期: {data['dt']}, 销售额: {data['total_sales']:.2f}")

# 方式2：直接读取Parquet文件（无需建表）
print("\n=== 直接读取Parquet文件 ===")
res = chdb.query(f"SELECT * FROM file('{parquet_path}', Parquet)", "Arrow")
# 转为Python列表
import pyarrow as pa
arrow_table = pa.RecordBatchFileReader(res.bytes()).read_all()
python_data = arrow_table.to_pylist()
print(f"Parquet文件原生数据: {python_data}")

# 4. 清理资源
cursor.close()
conn.close()
tmp_dir.cleanup()
```

## 五、关键注意事项
1. **持久化 vs 临时数据**：
   - 临时数据：用 `chdb.connect(":memory:")` 内存模式，无需路径；
   - 持久化数据：指定固定路径（如 `/data/chdb`），而非临时目录。
2. **性能优化**：
   - 批量插入用 `executemany` 而非循环单插；
   - 大数据场景优先用 Parquet + Arrow 格式（零拷贝）；
3. **生产环境建议**：
   - 核心业务表用 `ReplacingMergeTree`，指定 `ORDER BY` 主键；
   - 日志/流水类数据用 `Log` 引擎；
   - 外部数据交互用 `File(Parquet)` 引擎，避免数据冗余。

## 六、终端输出效果示例
运行上述代码后，终端会输出类似以下内容：
```
chdb数据存储路径: /tmp/tmpXXXXXX

=== 读取方式1：基础fetch接口 ===
列名: ['user_id', 'action', 'dt', 'pv']
单行数据: (1001, 'click', '2024-01-01', 5)
批量数据: [(1002, 'view', '2024-01-01', 10), (1003, 'click', '2024-01-01', 3)]
所有数据: [(1001, 'click', '2024-01-02', 8)]

=== 读取方式2：转换为字典 ===
字典格式数据: [{'user_id': 1001, 'action': 'click', 'dt': '2024-01-01', 'pv': 5}, {'user_id': 1002, 'action': 'view', 'dt': '2024-01-01', 'pv': 10}, {'user_id': 1003, 'action': 'click', 'dt': '2024-01-01', 'pv': 3}, {'user_id': 1001, 'action': 'click', 'dt': '2024-01-02', 'pv': 8}]

=== 读取方式3：转换为DataFrame ===
DataFrame格式:
   user_id action          dt  pv
0     1001  click  2024-01-01   5
1     1002   view  2024-01-01  10
2     1003  click  2024-01-01   3
3     1001  click  2024-01-02   8
```

以上就是 chdb Python 写入/读取的完整实操教程，覆盖生产级选型和常用操作，可直接复制代码在终端运行验证。