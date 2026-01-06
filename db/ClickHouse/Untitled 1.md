

# 📖 chDB (Embedded ClickHouse) 全能开发手册

## 一、 环境安装

chDB 是一个 C++ 编写的动态库，目前对 Python 支持最完善，同时也支持 C/C++/Rust/Go（通过 C-API）。

```shell
# Python 环境
pip install chdb

# 验证安装
python3 -c "import chdb; print(chdb.engine_version())"
```





## 二、 数据库核心操作 (DDL/DML)

chDB 的强大之处在于其 **MergeTree** 系列引擎，支持索引、分区和自动过期。

### 1. 初始化持久化表

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

### 2. 高性能数据写入

**注意：** 避免逐条插入。推荐“攒批写入”（如每 5 秒或每 5000 条一次）

```python
# 方式 A：直接传入 Python 列表
data = [
    ("2026-01-06 12:00:00.000", "srv-a", "cpu", 12.5),
    ("2026-01-06 12:00:00.001", "srv-a", "mem", 45.8)
]
ctx.query("INSERT INTO metrics VALUES", data=data)

# 方式 B：从本地 CSV/Parquet 文件直接导入（速度最快）
ctx.query("INSERT INTO metrics SELECT * FROM file('input.csv', CSV)")
```





## 三、 数据导出与程序交互

chDB 支持多种输出格式，方便您的开发语言或其他程序调用。

| **输出格式**  | **适用场景**             | **代码示例 (output_format=)** |
| ------------- | ------------------------ | ----------------------------- |
| **Dataframe** | Python 数据分析 (Pandas) | `ctx.query(sql, "DataFrame")` |
| **Parquet**   | 跨程序高性能传输         | `ctx.query(sql, "Parquet")`   |
| **JSON**      | Web API 返回             | `ctx.query(sql, "JSON")`      |
| **Arrow**     | 零拷贝内存共享           | `ctx.query(sql, "Arrow")`     |



## 四、 常用查询工具与技巧

### 1. 时间范围过滤（过去 3 天）

```sql
SELECT 
    toStartOfInterval(ts, INTERVAL 5 MINUTE) AS time_bucket,
    avg(value) AS avg_val
FROM metrics
WHERE metric_name = 'cpu' 
  AND ts > now() - INTERVAL 3 DAY
GROUP BY time_bucket ORDER BY time_bucket;
```

### 2. 查看表占用空间

```sql
SELECT 
    table, 
    formatReadableSize(sum(data_compressed_bytes)) AS compressed,
    formatReadableSize(sum(data_uncompressed_bytes)) AS raw
FROM system.parts GROUP BY table;
```



## 五、 进阶：免安装查询（工具化使用）

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



## 六、 开发者避坑指南

1. **进程锁**：chDB 是嵌入式的，通常同一时间**只有一个进程**能以写模式打开持久化目录（类似于 SQLite）。

2. **主键设计**：`ORDER BY` 里的字段顺序决定了查询性能。把最常用的过滤字段（如 `metric_name`）放最前面。

3. 内存限制：在受限环境下，可以通过 SQL 设置内存上限：

   SET max_memory_usage = '2G';

