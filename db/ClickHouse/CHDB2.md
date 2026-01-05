# chdb Python 全面使用示例（CPU/内存指标采集场景）
chdb 是基于 ClickHouse 打造的嵌入式分析引擎，Python 端提供了简洁的 API 接口，支持 SQL 查询、DB-API 规范、DataFrame 交互、UDF 扩展等能力。以下以**采集并分析CPU/内存指标**为场景，提供从基础到进阶的完整使用示例。

## 一、环境准备
### 1. 安装 chdb
```bash
pip install chdb
# 如需支持DataFrame/Arrow格式，需额外安装
pip install chdb pyarrow pandas
```

### 2. 核心依赖说明
- 基础功能：仅需 `chdb` 包
- DataFrame 交互：需 `pyarrow` + `pandas`
- 扩展功能（如UDF）：内置支持，无需额外依赖

## 二、基础使用：直接执行SQL（核心API）
chdb 最基础的用法是通过 `chdb.query()` 直接执行 SQL，适合快速查询/数据写入。

### 场景：模拟采集CPU/内存指标并写入chdb
```python
import chdb
import psutil  # 用于获取系统CPU/内存指标
import time

# 1. 模拟采集CPU/内存数据（生成结构化数据）
def collect_sys_metrics():
    """采集CPU、内存使用率，返回结构化数据"""
    cpu_percent = psutil.cpu_percent(interval=1)
    mem = psutil.virtual_memory()
    mem_percent = mem.percent
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    return {
        "timestamp": timestamp,
        "cpu_percent": cpu_percent,
        "mem_percent": mem_percent
    }

# 2. 创建内存表存储指标（chdb支持ClickHouse SQL语法）
# 注：chdb默认使用内存引擎，也可指定文件路径持久化
create_table_sql = """
CREATE TABLE sys_metrics (
    timestamp DateTime,
    cpu_percent Float64,
    mem_percent Float64
) ENGINE = Memory
"""
# 执行建表SQL，默认输出格式为CSV（可指定其他格式）
chdb.query(create_table_sql, "CSV")

# 3. 循环采集并插入数据
for i in range(5):  # 模拟采集5次
    metrics = collect_sys_metrics()
    # 构造插入SQL（参数化写法避免注入）
    insert_sql = f"""
    INSERT INTO sys_metrics VALUES ('{metrics["timestamp"]}', {metrics["cpu_percent"]}, {metrics["mem_percent"]})
    """
    chdb.query(insert_sql, "CSV")
    print(f"已插入第{i+1}条指标数据")

# 4. 查询采集的指标数据（指定输出格式）
# 支持的格式：CSV、JSON、DataFrame、Arrow、Debug等
# 4.1 基础查询（CSV格式）
query_sql = "SELECT * FROM sys_metrics ORDER BY timestamp"
csv_result = chdb.query(query_sql, "CSV")
print("\nCSV格式查询结果：")
print(csv_result.data())  # .data() 获取字符串结果

# 4.2 JSON格式查询
json_result = chdb.query(query_sql, "JSONCompact")
print("\nJSON格式查询结果：")
print(json_result.data())

# 4.3 DataFrame格式（需安装pandas+pyarrow）
df_result = chdb.query(query_sql, "DataFrame")
print("\nDataFrame格式查询结果：")
print(df_result)  # 直接返回pandas.DataFrame

# 4.4 聚合分析（计算CPU平均使用率）
agg_sql = """
SELECT 
    AVG(cpu_percent) AS avg_cpu,
    MAX(mem_percent) AS max_mem,
    MIN(mem_percent) AS min_mem
FROM sys_metrics
"""
agg_result = chdb.query(agg_sql, "DataFrame")
print("\n指标聚合结果：")
print(agg_result)
```

## 三、标准DB-API使用（兼容Python DB-API 2.0）
chdb 提供了符合 DB-API 2.0 规范的接口（`chdb.dbapi`），适配通用数据库操作习惯，适合工程化开发。

```python
from chdb import dbapi
from chdb.dbapi.cursors import DictCursor  # 支持字典格式游标
import psutil
import time

# 1. 建立连接（:memory: 内存模式；也可指定路径如 "file:/tmp/sys_metrics.db" 持久化）
conn = dbapi.connect(":memory:")

# 2. 创建游标（支持普通游标/字典游标）
# 2.1 普通游标（返回元组）
cur = conn.cursor()

# 3. 建表
cur.execute("""
CREATE TABLE IF NOT EXISTS sys_metrics (
    timestamp DateTime,
    cpu_percent Float64,
    mem_percent Float64
) ENGINE = Memory
""")

# 4. 批量插入指标数据（executemany）
metrics_list = []
for i in range(3):
    cpu = psutil.cpu_percent(interval=0.5)
    mem = psutil.virtual_memory().percent
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    metrics_list.append((ts, cpu, mem))

# 批量插入（参数化查询，避免SQL注入）
cur.executemany(
    "INSERT INTO sys_metrics VALUES (%s, %s, %s)",
    metrics_list
)

# 5. 执行查询
cur.execute("SELECT * FROM sys_metrics ORDER BY timestamp")

# 6. 结果获取（fetchone/fetchmany/fetchall）
print("fetchone 结果：", cur.fetchone())  # 获取单行
print("fetchmany(2) 结果：", cur.fetchmany(2))  # 获取指定行数
# cur.execute("SELECT * FROM sys_metrics ORDER BY timestamp")  # 重置游标
# print("fetchall 结果：", cur.fetchall())  # 获取所有行

# 7. 字典游标（返回字典格式，更易读）
cur_dict = conn.cursor(cursorclass=DictCursor)
cur_dict.execute("SELECT * FROM sys_metrics ORDER BY timestamp")
print("\n字典游标结果：")
for row in cur_dict:
    print(f"时间：{row['timestamp']}，CPU：{row['cpu_percent']}%，内存：{row['mem_percent']}%")

# 8. 获取列元数据
cur.execute("SELECT * FROM sys_metrics")
print("\n列名：", cur.column_names())  # 获取列名
print("列类型：", cur.column_types())  # 获取列类型
print("DB-API描述：", cur.description)  # 标准DB-API描述

# 9. 关闭资源（必须）
cur.close()
cur_dict.close()
conn.close()
```

## 四、Session 持久化使用（状态保留）
`chdb.session.Session` 支持持久化存储（文件模式），适合长期采集指标、保留表结构/数据。

```python
from chdb import session
import psutil
import time
import os

# 1. 创建Session（指定本地目录持久化，而非内存）
session_path = "./sys_metrics_session"
if not os.path.exists(session_path):
    os.makedirs(session_path)
sess = session.Session(session_path)

# 2. 建表（持久化，重启后表结构仍存在）
sess.query("""
CREATE TABLE IF NOT EXISTS sys_metrics (
    timestamp DateTime,
    cpu_percent Float64,
    mem_percent Float64
) ENGINE = Atomic  # Atomic引擎支持持久化
""", "CSV")

# 3. 持续采集并插入
for i in range(4):
    cpu = psutil.cpu_percent(interval=0.5)
    mem = psutil.virtual_memory().percent
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    sess.query(f"INSERT INTO sys_metrics VALUES ('{ts}', {cpu}, {mem})", "CSV")

# 4. 查询历史数据（即使重启Session，数据仍在）
result = sess.query("SELECT * FROM sys_metrics", "DataFrame")
print("\n持久化Session查询结果：")
print(result)

# 5. 关闭Session
sess.close()

# 6. 重新打开Session，验证数据是否保留
new_sess = session.Session(session_path)
new_result = new_sess.query("SELECT COUNT(*) FROM sys_metrics", "CSV")
print("\n重启Session后数据行数：", new_result.data())
new_sess.close()

# 清理测试目录（可选）
import shutil
shutil.rmtree(session_path)
```

## 五、自定义UDF（用户定义函数）
chdb 支持Python UDF，可扩展指标计算逻辑（如CPU阈值判断、内存使用率分级）。

```python
from chdb import query
from chdb.udf import chdb_udf

# 1. 定义UDF：判断CPU使用率是否过高（阈值80%）
@chdb_udf()
def cpu_status(cpu_percent):
    cpu_val = float(cpu_percent)
    if cpu_val > 80:
        return "high"
    elif cpu_val > 50:
        return "medium"
    else:
        return "low"

# 2. 定义UDF：内存使用率分级
@chdb_udf()
def mem_grade(mem_percent):
    mem_val = float(mem_percent)
    if mem_val > 90:
        return "critical"
    elif mem_val > 70:
        return "warning"
    else:
        return "normal"

# 3. 插入测试数据
query("""
CREATE TABLE sys_metrics (
    timestamp DateTime,
    cpu_percent Float64,
    mem_percent Float64
) ENGINE = Memory
""", "CSV")

# 插入模拟指标数据
test_data = [
    ("2024-01-01 10:00:00", 85.5, 92.0),
    ("2024-01-01 10:01:00", 60.2, 75.5),
    ("2024-01-01 10:02:00", 30.1, 60.0)
]
for ts, cpu, mem in test_data:
    query(f"INSERT INTO sys_metrics VALUES ('{ts}', {cpu}, {mem})", "CSV")

# 4. 使用UDF查询指标状态
udf_sql = """
SELECT 
    timestamp,
    cpu_percent,
    cpu_status(cpu_percent) AS cpu_state,
    mem_percent,
    mem_grade(mem_percent) AS mem_state
FROM sys_metrics
"""
result = query(udf_sql, "DataFrame")
print("\n带UDF的指标分析结果：")
print(result)
```

## 六、DataFrame 交互（pandas 集成）
chdb 支持直接与 pandas.DataFrame 交互，适合将采集的指标数据与已有DataFrame融合分析。

```python
import chdb.dataframe as cdf
import pandas as pd
import psutil
import time

# 1. 采集指标到pandas DataFrame
metrics_data = []
for i in range(3):
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    cpu = psutil.cpu_percent(interval=0.5)
    mem = psutil.virtual_memory().percent
    metrics_data.append({"timestamp": ts, "cpu_percent": cpu, "mem_percent": mem})
df = pd.DataFrame(metrics_data)

# 2. 将DataFrame转换为chdb Table
chdb_table = cdf.Table(dataframe=df)

# 3. 直接查询chdb Table（__table__ 为内置表名）
# 3.1 基础查询
result1 = chdb_table.query("SELECT * FROM __table__ ORDER BY timestamp")
print("\nchdb Table查询结果：")
print(result1)

# 3.2 聚合分析
result2 = chdb_table.query("""
SELECT 
    AVG(cpu_percent) AS avg_cpu,
    AVG(mem_percent) AS avg_mem,
    COUNT(*) AS total_records
FROM __table__
""")
print("\nDataFrame聚合分析结果：")
print(result2)

# 4. chdb结果转回pandas DataFrame
df_result = result2.to_pandas()  # 或直接用chdb.query(..., "DataFrame")
print("\nchdb结果转回DataFrame：")
print(df_result)
```

## 七、命令行使用 chdb
chdb 支持通过Python命令行模式快速执行SQL，适合调试/一次性查询。

### 1. 基本用法
```bash
# 执行简单查询（默认CSV格式）
python -m chdb "SELECT 1 as test"

# 指定输出格式（如JSON）
python -m chdb "SELECT * FROM sys_metrics" "JSON"

# 结合指标采集（示例：查询CPU平均使用率）
python -m chdb "SELECT AVG(cpu_percent) FROM sys_metrics" "DataFrame"
```

### 2. 批量执行SQL文件
```python
# 新建 sql_file.sql
"""
CREATE TABLE IF NOT EXISTS sys_metrics (timestamp DateTime, cpu_percent Float64, mem_percent Float64) ENGINE = Memory;
INSERT INTO sys_metrics VALUES ('2024-01-01 10:00:00', 50.0, 70.0);
SELECT * FROM sys_metrics;
"""

# 读取SQL文件并执行
import chdb

with open("sql_file.sql", "r") as f:
    sql = f.read()
result = chdb.query(sql, "CSV")
print(result.data())
```

## 八、错误处理
生产环境中需捕获chdb执行异常，保证采集流程稳定性。

```python
from chdb import query
import psutil
import time

try:
    # 建表
    query("""
    CREATE TABLE sys_metrics (
        timestamp DateTime,
        cpu_percent Float64,
        mem_percent Float64
    ) ENGINE = Memory
    """, "CSV")

    # 插入无效数据（模拟异常）
    invalid_ts = "2024-01-01"  # 格式错误的时间
    cpu = psutil.cpu_percent()
    mem = psutil.virtual_memory().percent
    query(f"INSERT INTO sys_metrics VALUES ('{invalid_ts}', {cpu}, {mem})", "CSV")

except Exception as e:
    print(f"执行异常：{type(e).__name__} - {str(e)}")
    # 容错处理：使用正确的时间格式重新插入
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    query(f"INSERT INTO sys_metrics VALUES ('{ts}', {cpu}, {mem})", "CSV")
    print("容错后插入成功")
```

## 九、核心API总结
| API/模块                | 用途                                  | 核心方法/示例                          |
|-------------------------|---------------------------------------|----------------------------------------|
| `chdb.query(sql, format)` | 基础SQL执行，支持多格式输出           | `chdb.query("SELECT * FROM t", "DataFrame")` |
| `chdb.dbapi`            | 标准DB-API接口，工程化开发            | `conn = dbapi.connect(); cur = conn.cursor()` |
| `chdb.session.Session`  | 持久化会话，保留表/数据状态           | `sess = session.Session("./data"); sess.query(sql)` |
| `chdb.dataframe.Table`  | DataFrame与chdb表交互                 | `tbl = cdf.Table(df); tbl.query(sql)`  |
| `chdb.udf.chdb_udf`     | 自定义UDF扩展                         | `@chdb_udf() def func(x): ...`         |

## 十、注意事项
1. 数据引擎：默认 `Memory` 引擎为内存存储，重启后数据丢失；需持久化可使用 `Atomic` 引擎并指定文件路径（如 `session.Session("./persist_path")`）。
2. 格式支持：常用格式包括 CSV、JSON、DataFrame、Arrow、Debug，完整格式列表参考 [ClickHouse 格式文档](https://clickhouse.com/docs/en/interfaces/formats)。
3. 性能：chdb 为列式存储，批量插入/查询效率远高于单行操作，建议采集指标时批量写入。
4. 依赖：使用 `DataFrame`/`Arrow` 格式需安装 `pyarrow` 和 `pandas`，版本建议 `pyarrow>=10.0.0`、`pandas>=1.5.0`。

以上示例覆盖了Python操作chdb的核心场景（指标采集、存储、查询、分析、扩展），可根据实际需求调整（如增加采集频率、扩展更多指标、对接监控系统等）。