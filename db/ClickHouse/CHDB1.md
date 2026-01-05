# chdb Python 生产级应用教程：服务器监控指标存储与查询
本文基于你的需求（存储服务器CPU、内存等监控指标，供可视化工具读取），从**环境安装、数据存储设计、写入/读取、生产级优化、可视化对接** 全流程讲解 chdb 的使用，所有代码可直接嵌入生产项目。

## 一、环境准备
### 1. 安装 chdb
遵循官方文档安装（适配Linux/macOS，Windows需WSL）：
```bash
# pip 安装（推荐）
pip install chdb

# 验证安装
python -c "import chdb; print(chdb.__version__)"
```

### 2. 核心概念说明
- chdb 是 ClickHouse 的轻量级无服务版本，兼容ClickHouse SQL语法，支持本地文件/内存存储，无需启动ClickHouse服务。
- 存储引擎：推荐使用 `MergeTree` 系列（适合时序数据）、`Log`（轻量只读）、`SQLite`（跨语言兼容）。
- 数据格式：支持Parquet（高效列存）、CSV/JSON（通用）、Arrow（对接Pandas）。

## 二、数据模型设计（服务器监控指标）
### 1. 表结构设计
时序监控数据核心需求：**按时间/服务器维度快速聚合、筛选**，设计表结构如下：
| 字段名          | 类型          | 说明                     |
|-----------------|---------------|--------------------------|
| server_ip       | String        | 服务器IP（分区/排序键）  |
| collect_time    | DateTime      | 采集时间（精确到秒）     |
| cpu_usage       | Float64       | CPU使用率（0-100）       |
| mem_usage       | Float64       | 内存使用率（0-100）      |
| mem_total       | UInt64        | 总内存（MB）             |
| mem_used        | UInt64        | 已用内存（MB）           |
| disk_usage      | Float64       | 磁盘使用率（0-100）      |
| load_1m         | Float64       | 1分钟负载均值            |

### 2. 存储引擎选择
- **生产首选：ReplacingMergeTree**（解决重复采集数据覆盖问题）
- 分区键：按月份分区 `toYYYYMM(collect_time)`
- 排序键：`(server_ip, collect_time)`（按服务器+时间排序，加速查询）

## 三、核心操作代码示例
### 1. 初始化连接（本地文件存储）
chdb 支持**内存模式**（临时数据）和**文件模式**（持久化），生产环境用文件模式：
```python
import chdb
from chdb import dbapi
import datetime
import time

# 生产环境：指定本地目录存储数据（持久化）
DB_DIR = "/data/chdb/monitor_data"  # 提前创建目录，权限需读写
conn = dbapi.connect(DB_DIR)  # 核心连接对象

# 内存模式（测试用，进程退出数据丢失）
# conn = dbapi.connect()
```

### 2. 创建监控表
```python
def init_monitor_table():
    cursor = conn.cursor()
    # 创建表（ReplacingMergeTree，按collect_time去重）
    create_sql = """
    CREATE TABLE IF NOT EXISTS server_metrics (
        server_ip String,
        collect_time DateTime,
        cpu_usage Float64,
        mem_usage Float64,
        mem_total UInt64,
        mem_used UInt64,
        disk_usage Float64,
        load_1m Float64
    ) ENGINE = ReplacingMergeTree(collect_time)  -- 按时间去重
    PARTITION BY toYYYYMM(collect_time)        -- 按月分区
    ORDER BY (server_ip, collect_time)         -- 排序键
    SETTINGS index_granularity = 8192;         -- 索引粒度（默认即可）
    """
    try:
        cursor.execute(create_sql)
        print("表初始化成功")
    except Exception as e:
        print(f"表创建失败：{e}")
    finally:
        cursor.close()

# 执行初始化
init_monitor_table()
```

### 3. 写入监控数据
支持**单条写入**和**批量写入**（生产优先批量，提升性能）：
#### （1）单条写入（适合实时采集）
```python
def insert_single_metric(server_ip, cpu, mem, mem_total, mem_used, disk, load):
    cursor = conn.cursor()
    collect_time = datetime.datetime.now()  # 采集时间
    # 参数化查询（防止SQL注入）
    insert_sql = """
    INSERT INTO server_metrics 
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """
    try:
        cursor.execute(
            insert_sql,
            (server_ip, collect_time, cpu, mem, mem_total, mem_used, disk, load)
        )
        print(f"单条数据写入成功：{server_ip} {collect_time}")
    except Exception as e:
        print(f"单条写入失败：{e}")
    finally:
        cursor.close()

# 测试写入
insert_single_metric(
    server_ip="192.168.1.100",
    cpu=25.6,
    mem=60.2,
    mem_total=16384,
    mem_used=9850,
    disk=45.8,
    load=1.2
)
```

#### （2）批量写入（适合定时批量采集）
```python
def insert_batch_metrics(metrics_list):
    """
    批量写入数据
    :param metrics_list: 列表，每个元素是元组：(server_ip, collect_time, cpu, mem, mem_total, mem_used, disk, load)
    """
    cursor = conn.cursor()
    insert_sql = """
    INSERT INTO server_metrics 
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """
    try:
        # executemany 批量插入（推荐每次1000-10000条）
        cursor.executemany(insert_sql, metrics_list)
        print(f"批量写入成功，共{len(metrics_list)}条")
    except Exception as e:
        print(f"批量写入失败：{e}")
    finally:
        cursor.close()

# 构造批量数据示例
batch_data = []
for ip in ["192.168.1.100", "192.168.1.101", "192.168.1.102"]:
    for i in range(5):  # 每个服务器5条模拟数据
        collect_time = datetime.datetime.now() - datetime.timedelta(minutes=i)
        batch_data.append(
            (
                ip,
                collect_time,
                20 + i * 2.5,  # cpu
                50 + i * 3.2,  # mem
                16384,         # mem_total
                8000 + i * 100, # mem_used
                40 + i * 1.8,  # disk
                0.8 + i * 0.1  # load_1m
            )
        )

# 执行批量写入
insert_batch_metrics(batch_data)
```

### 4. 数据查询（适配可视化需求）
可视化工具（如Grafana/Metabase）需支持SQL查询，以下是常见查询场景：
#### （1）单服务器近1小时指标
```python
def query_server_recent_metrics(server_ip, hours=1):
    cursor = conn.cursor()
    start_time = datetime.datetime.now() - datetime.timedelta(hours=hours)
    query_sql = """
    SELECT collect_time, cpu_usage, mem_usage, disk_usage, load_1m
    FROM server_metrics
    WHERE server_ip = %s AND collect_time >= %s
    ORDER BY collect_time ASC
    """
    try:
        cursor.execute(query_sql, (server_ip, start_time))
        # 获取列名（适配可视化工具表头）
        columns = [desc[0] for desc in cursor.description]
        # 获取数据
        data = cursor.fetchall()
        # 转换为字典列表（方便JSON返回给前端）
        result = [dict(zip(columns, row)) for row in data]
        return result
    except Exception as e:
        print(f"查询失败：{e}")
        return []
    finally:
        cursor.close()

# 测试查询
recent_data = query_server_recent_metrics("192.168.1.100", hours=1)
print("近1小时指标：", recent_data)
```

#### （2）多服务器聚合统计（按IP分组）
```python
def query_server_agg_metrics(start_time, end_time):
    cursor = conn.cursor()
    query_sql = """
    SELECT 
        server_ip,
        AVG(cpu_usage) AS avg_cpu,
        MAX(cpu_usage) AS max_cpu,
        AVG(mem_usage) AS avg_mem,
        MAX(mem_usage) AS max_mem,
        AVG(disk_usage) AS avg_disk
    FROM server_metrics
    WHERE collect_time BETWEEN %s AND %s
    GROUP BY server_ip
    ORDER BY avg_cpu DESC
    """
    try:
        cursor.execute(query_sql, (start_time, end_time))
        columns = [desc[0] for desc in cursor.description]
        result = [dict(zip(columns, row)) for row in data]
        return result
    except Exception as e:
        print(f"聚合查询失败：{e}")
        return []
    finally:
        cursor.close()

# 测试聚合查询（今日数据）
today_start = datetime.datetime.now().replace(hour=0, minute=0, second=0)
today_end = datetime.datetime.now()
agg_data = query_server_agg_metrics(today_start, today_end)
print("今日服务器聚合指标：", agg_data)
```

#### （3）导出数据为Parquet（高效供可视化工具读取）
chdb 支持直接导出为Parquet（列存格式，可视化工具如Tableau/PowerBI原生支持）：
```python
def export_metrics_to_parquet(server_ip, output_path):
    # 使用chdb.query直接执行SQL并导出格式
    sql = f"""
    SELECT * FROM server_metrics
    WHERE server_ip = '{server_ip}' AND collect_time >= toDateTime('{datetime.datetime.now() - datetime.timedelta(days=1)}')
    """
    # 导出为Parquet格式
    res = chdb.query(sql, "Parquet")
    # 写入文件
    with open(output_path, "wb") as f:
        f.write(res.bytes())
    print(f"数据已导出到：{output_path}")

# 导出192.168.1.100近1天数据
export_metrics_to_parquet("192.168.1.100", "/data/metrics/192.168.1.100_metrics.parquet")
```

### 5. 数据清理（生产必备）
时序数据需定期清理过期数据，避免存储膨胀：
```python
def clean_expired_metrics(keep_days=90):
    """清理超过指定天数的数据"""
    cursor = conn.cursor()
    expire_time = datetime.datetime.now() - datetime.timedelta(days=keep_days)
    # ClickHouse删除分区（高效）
    clean_sql = f"""
    ALTER TABLE server_metrics DROP PARTITION WHERE toYYYYMM(collect_time) < toYYYYMM('{expire_time}')
    """
    try:
        cursor.execute(clean_sql)
        # 优化表（释放磁盘空间）
        cursor.execute("OPTIMIZE TABLE server_metrics FINAL")
        print(f"清理{keep_days}天前数据完成")
    except Exception as e:
        print(f"数据清理失败：{e}")
    finally:
        cursor.close()

# 保留90天数据，每月执行一次
clean_expired_metrics(90)
```

### 6. 对接Pandas（数据分析/可视化）
chdb 可直接转换为Pandas DataFrame，适配Matplotlib/Seaborn/Plotly等可视化库：
```python
import pandas as pd
import pyarrow as pa

def query_to_dataframe(sql):
    """执行SQL并转换为Pandas DataFrame"""
    # 导出为Arrow格式（高效转换Pandas）
    res = chdb.query(sql, "Arrow")
    # 转换为Arrow Table
    arrow_table = pa.RecordBatchFileReader(res.bytes()).read_all()
    # 转换为DataFrame
    df = arrow_table.to_pandas(use_threads=True)
    return df

# 查询并可视化
sql = """
SELECT collect_time, cpu_usage, mem_usage 
FROM server_metrics 
WHERE server_ip = '192.168.1.100' 
AND collect_time >= toDateTime('{datetime.datetime.now() - datetime.timedelta(hours=24)}')
"""
df = query_to_dataframe(sql)

# 绘制CPU/内存趋势图
import matplotlib.pyplot as plt
plt.rcParams['font.sans-serif'] = ['SimHei']  # 中文支持
plt.figure(figsize=(12, 6))
plt.plot(df['collect_time'], df['cpu_usage'], label='CPU使用率(%)', color='red')
plt.plot(df['collect_time'], df['mem_usage'], label='内存使用率(%)', color='blue')
plt.xlabel('采集时间')
plt.ylabel('使用率(%)')
plt.title('服务器192.168.1.100近24小时资源趋势')
plt.legend()
plt.grid(True)
plt.savefig('/data/metrics/192.168.1.100_trend.png')
plt.close()
```

## 四、生产级优化建议
### 1. 存储优化
- **目录规划**：将chdb数据目录挂载到独立磁盘（避免与系统盘共用）。
- **引擎调优**：
  - 写入频繁场景：设置 `min_bytes_for_wide_part = 0`（小分区也用宽格式）。
  - 读取频繁场景：开启 `enable_vertical_merge_algorithm = 1`（提升合并性能）。
- **数据压缩**：MergeTree默认使用LZ4压缩，无需额外配置（压缩比高，性能损耗低）。

### 2. 写入优化
- **批量写入**：每次写入1000-10000条（避免单条频繁写入）。
- **异步写入**：生产环境用线程池异步写入，避免阻塞采集流程：
  ```python
  from concurrent.futures import ThreadPoolExecutor
  executor = ThreadPoolExecutor(max_workers=4)  # 根据服务器配置调整
  
  # 异步批量写入
  executor.submit(insert_batch_metrics, batch_data)
  ```
- **去重策略**：利用 `ReplacingMergeTree` 的去重键，避免重复采集数据。

### 3. 读取优化
- **分区过滤**：查询时必带 `collect_time` 范围（避免全表扫描）。
- **列裁剪**：只查询需要的列（如只查cpu_usage、mem_usage，不查所有列）。
- **预聚合**：定时生成聚合表（如每小时/每天的平均值），减少可视化工具实时计算压力：
  ```sql
  -- 创建小时聚合表
  CREATE TABLE IF NOT EXISTS server_metrics_hourly (
      server_ip String,
      collect_hour DateTime,  -- 按小时聚合
      avg_cpu Float64,
      avg_mem Float64,
      avg_disk Float64
  ) ENGINE = SummingMergeTree()
  PARTITION BY toYYYYMM(collect_hour)
  ORDER BY (server_ip, collect_hour);
  
  -- 定时插入聚合数据（每小时执行）
  INSERT INTO server_metrics_hourly
  SELECT 
      server_ip,
      toStartOfHour(collect_time) AS collect_hour,
      AVG(cpu_usage) AS avg_cpu,
      AVG(mem_usage) AS avg_mem,
      AVG(disk_usage) AS avg_disk
  FROM server_metrics
  WHERE collect_time >= toStartOfHour(now()) - INTERVAL 1 HOUR
  GROUP BY server_ip, collect_hour;
  ```

### 4. 监控与运维
- **磁盘监控**：定期检查chdb数据目录磁盘使用率，避免满盘。
- **日志记录**：捕获chdb操作异常并写入日志（如使用logging模块）：
  ```python
  import logging
  logging.basicConfig(filename='/var/log/chdb_monitor.log', level=logging.ERROR)
  
  try:
      cursor.execute(sql)
  except Exception as e:
      logging.error(f"SQL执行失败：{sql}，错误：{e}")
  ```
- **备份策略**：定期备份chdb数据目录（如每日增量备份，每周全量备份）。

## 五、可视化工具对接
### 1. 对接Grafana（推荐）
Grafana 支持自定义SQL数据源，可通过以下方式对接：
- **方式1**：搭建chdb HTTP服务（参考chdb/examples/server.py），Grafana通过HTTP API查询：
  ```python
  # 简易HTTP服务（生产需加认证/限流）
  from flask import Flask, request
  app = Flask(__name__)
  
  @app.route('/query', methods=['POST'])
  def query():
      sql = request.form.get('sql')
      format = request.form.get('format', 'JSONCompact')
      res = chdb.query(sql, format)
      return res.bytes()
  
  if __name__ == '__main__':
      app.run(host='0.0.0.0', port=8123)  # 模拟ClickHouse HTTP端口
  ```
- **方式2**：将chdb数据导出为Parquet/CSV，Grafana通过File/CSV插件读取。

### 2. 对接Tableau/PowerBI
直接读取chdb导出的Parquet文件（列存格式，Tableau/PowerBI原生支持，查询效率高）。

## 六、常见问题与解决方案
| 问题                  | 解决方案                                                                 |
|-----------------------|--------------------------------------------------------------------------|
| 数据写入后查询不到    | 1. 检查分区是否创建；2. ReplacingMergeTree需等待合并（或手动OPTIMIZE）|
| 磁盘使用率高          | 1. 清理过期数据；2. 开启分区级别的TTL（CREATE TABLE时指定TTL）|
| 查询性能慢            | 1. 加分区过滤；2. 列裁剪；3. 预聚合数据                                 |
| 进程崩溃数据丢失      | 1. 使用文件模式存储；2. 定期备份数据目录                                 |
| 并发写入冲突          | 1. 用线程池控制并发数；2. 批量写入减少冲突                               |

## 七、完整生产项目目录结构
```
/server-monitor/
├── config.py          # 配置（DB_DIR、保留天数、线程池数等）
├── db_operation.py    # chdb核心操作（创建表、写入、查询、清理）
├── collector.py       # 服务器指标采集（psutil库）
├── api.py             # HTTP接口（供可视化工具调用）
├── logs/              # 日志目录
└── data/              # chdb数据目录（挂载独立磁盘）
```

## 总结
chdb 作为轻量级ClickHouse，非常适合**中小规模服务器监控数据**的存储与查询，核心优势是无需部署ClickHouse服务、兼容ClickHouse SQL、列存高效。生产使用的核心原则：
1. 用文件模式持久化数据，选择ReplacingMergeTree引擎；
2. 批量写入、分区查询、定期清理过期数据；
3. 预聚合减少实时计算压力，对接可视化工具优先用Parquet格式或HTTP API。

如果后期数据量增长到TB级，可无缝迁移到ClickHouse集群（语法完全兼容），无需修改查询逻辑。