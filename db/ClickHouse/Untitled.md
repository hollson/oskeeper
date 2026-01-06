

# chDB (Embedded ClickHouse) 技术文档

## 1. 什么是 chDB？

**chDB** 是基于 ClickHouse 核心构建的**高性能嵌入式分析引擎**。它以库（Library）的形式运行在你的进程内，无需安装、配置或运行独立的数据库服务（如 MySQL 或标准的 ClickHouse Server）。

- **核心特性**：列式存储、向量化执行、LSM-Tree 存储架构。
- **适用场景**：服务器监控指标存储、本地大数据量分析、边缘计算、实时报表生成。

------

## 2. 存储与格式

在 chDB 中，你需要理解**存储引擎**与**交互格式**的区别：

- **MergeTree (存储引擎)**：这是 chDB 的灵魂。数据在磁盘上按列存储，并自动进行排序、索引和后台压缩合并。它是实现“3个月长周期数据秒级查询”的关键。
- **Parquet / Arrow (高性能格式)**：当你需要将数据提供给其他程序（如 Python 数据分析、Go 后台）时，chDB 可以直接输出这些二进制格式，效率远高于 JSON 或 CSV。

------

## 3. 快速上手（以 Python 为例）

### A. 安装

```shell
pip install chdb
```

### B. 创建带自动过期的监控表

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

### C. 高性能实时写入

建议采用**批量写入**（例如每 5-10 秒写入一次），这是 chDB 最擅长的模式。

```python
# 模拟批量写入数据
data_to_insert = [
    ("2026-01-06 10:00:00.000", "srv-01", "cpu_usage", 15.5, 0),
    ("2026-01-06 10:00:00.000", "srv-01", "mem_usage", 64.2, 0)
]

# chDB 支持直接从内存结构或 CSV/JSON 字符串高速导入
chdb.query(f"INSERT INTO server_metrics VALUES", data=data_to_insert)
```

### D. 复杂过滤与查询

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



