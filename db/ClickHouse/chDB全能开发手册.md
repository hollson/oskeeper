# 📖 chDB全能开发手册

## 1. 环境安装

chDB 是一个 C++ 编写的动态库，目前对 Python 支持最完善，同时也支持 C/C++/Rust/Go（通过 C-API）。

```shell
pip install chdb
python -c "import chdb; print(chdb.engine_version)"
```



## 2. 核心概念

- **MergeTree (存储引擎)**：这是 chDB 的核心。数据在磁盘上按列存储，并自动进行排序、索引和后台压缩合并。
- **Parquet / Arrow (交互格式)**：当需要跟其他程序进行数据交换时，可以直接输出二进制格式，效率远高于 JSON 或 CSV。



## 3. DDL/DML

chDB 的强大之处在于其 **MergeTree** 系列引擎，支持索引、分区和自动过期。

### 3.1 初始化持久化表

```python
import chdb

# 指定路径以持久化数据（若不指定则在内存中）
ctx = chdb.session(path="./monitor_data") 

# 创建监控表：按月分区，按指标名和时间排序，数据保留 90 天
ctx.query("""
CREATE TABLE IF NOT EXISTS metrics (
    ts DateTime64(3),
    tag_host String,
    metric_name String,
    value Float64
) 
ENGINE = MergeTree()
PARTITION BY toYYYYMM(ts)
ORDER BY (metric_name, ts, tag_host)
TTL ts + INTERVAL 90 DAY;
""")
```

### 3.2 创建带自动过期的监控表

监控数据通常不需要永久保存。我们可以使用 `TTL` (Time To Live) 让 chDB 自动清理 3 个月前的数据。

```python
import chdb

# 1. 初始化并创建表（使用 MergeTree 引擎）
# 这里的路径 'path/to/data' 是持久化存储位置
chdb.query("""
CREATE TABLE IF NOT EXISTS server_metrics (
    timestamp DateTime64(3),
    host_id String,
    metric_name String,
    value Float64,
    cpu_core Int16
) 
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (metric_name, timestamp, host_id)
TTL timestamp + INTERVAL 3 MONTH; -- 自动删除3个月前的数据
""")
```

### 3.3 高性能数据写入

**注意：** 避免逐条插入。推荐"攒批写入"（如每 5 秒或每 5000 条一次）

```python
# 方式 A：直接传入 Python 列表
data = [
    ("2026-01-06 12:00:00.000", "srv-a", "cpu", 12.5),
    ("2026-01-06 12:00:00.001", "srv-a", "mem", 45.8)
]
ctx.query("INSERT INTO metrics VALUES", data=data)

# 模拟批量写入数据
data_to_insert = [
    ("2026-01-06 10:00:00.000", "srv-01", "cpu_usage", 15.5, 0),
    ("2026-01-06 10:00:00.000", "srv-01", "mem_usage", 64.2, 0)
]

# chDB 支持直接从内存结构或 CSV/JSON 字符串高速导入
chdb.query(f"INSERT INTO server_metrics VALUES", data=data_to_insert)

# 方式 B：从本地 CSV/Parquet 文件直接导入（速度最快）
ctx.query("INSERT INTO metrics SELECT * FROM file('input.csv', CSV)")
```

## 4. 数据导出与程序交互

chDB 支持多种输出格式，方便您的开发语言或其他程序调用。

| **输出格式**  | **适用场景**             | **代码示例 (output_format=)** |
| ------------- | ------------------------ | ----------------------------- |
| **Dataframe** | Python 数据分析 (Pandas) | `ctx.query(sql, "DataFrame")` |
| **Parquet**   | 跨程序高性能传输         | `ctx.query(sql, "Parquet")`   |
| **JSON**      | Web API 返回             | `ctx.query(sql, "JSON")`      |
| **Arrow**     | 零拷贝内存共享           | `ctx.query(sql, "Arrow")`     |

## 5. 常用查询工具与技巧

### 5.1 复杂过滤与查询

查询过去 3 天内，某个特定主机的 CPU 平均负载：

```python
query_sql = """
SELECT 
    toStartOfHour(timestamp) as hour,
    avg(value) as avg_val
FROM server_metrics
WHERE metric_name = 'cpu_usage' 
  AND host_id = 'srv-01'
  AND timestamp > now() - INTERVAL 3 DAY
GROUP BY hour
ORDER BY hour ASC
"""

# 以 Dataframe 格式获取结果，方便后续处理
res = chdb.query(query_sql, "DataFrame")
print(res)
```

### 5.2 时间范围过滤（过去 3 天）

```sql
SELECT 
    toStartOfInterval(ts, INTERVAL 5 MINUTE) AS time_bucket,
    avg(value) AS avg_val
FROM metrics
WHERE metric_name = 'cpu' 
  AND ts > now() - INTERVAL 3 DAY
GROUP BY time_bucket ORDER BY time_bucket;
```

### 5.3 查看表占用空间

```sql
SELECT 
    table, 
    formatReadableSize(sum(data_compressed_bytes)) AS compressed,
    formatReadableSize(sum(data_uncompressed_bytes)) AS raw
FROM system.parts GROUP BY table;
```

## 6. 进阶：免安装查询（工具化使用）

chDB 提供了一个强大的功能：**无需建表直接查询文件**。你可以把它当作一个增强版的 `grep` 或 `awk`。

```python
# 直接在磁盘上的 100 个 Parquet 文件中搜索异常值
res = chdb.query("""
    SELECT tag_host, max(value) 
    FROM file('logs/*.parquet', Parquet) 
    WHERE value > 90 
    GROUP BY tag_host
""")
```

## 7. 开发者避坑指南

1. **进程锁**：chDB 是嵌入式的，通常同一时间**只有一个进程**能以写模式打开持久化目录（类似于 SQLite）。

2. **主键设计**：`ORDER BY` 里的字段顺序决定了查询性能。把最常用的过滤字段（如 `metric_name`）放最前面。

3. **内存限制**：在受限环境下，可以通过 SQL 设置内存上限：
   
   SET max_memory_usage = '2G';