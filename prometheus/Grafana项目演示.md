# Grafana 可视化配置指南

## 一、确定数据库类型

根据 `app/common/config.py` 中的 `DATABASE_URL` 判断：

| 类型 | 前缀 | 默认数据库文件 |
|------|------|---------------|
| PostgreSQL | `postgresql://...` | - |
| SQLite | `sqlite:///...` | 项目根目录 `db.sqlite3` |

## 二、配置数据源

访问 Grafana：`http://localhost:3000` → **Connections** → **Data sources** → **Add data source**

### PostgreSQL（原生支持）

```shell
Type: PostgreSQL
Host:     developer.com:5432  ← 修改为你的主机:端口
Database: metric_collector_master
User:     postgres
Password: 你的密码
SSL Mode: disable

```

点击 **Save & test**，显示绿色即为成功。

### SQLite（需安装插件）

**1. 安装插件（Windows）**

```powershell
grafana-cli plugins install frser-sqlite-datasource
```

重启 Grafana 服务（服务名：`grafana`）。

**2. 配置数据源**

```shell
Type: SQLite
Path:  e:\gitee\tutor-python\examples\metric_collector\db.sqlite3
```

点击 **Save & test**。

## 三、创建仪表盘

新建 Dashboard，添加面板时选择 **SQL** 面板，填入下方查询。

> **注意**：所有查询必须包含 `$__timeFilter(timestamp)` 过滤时间范围，返回列名必须是 `"time"`。

### 图表类型选择建议

为了提升大屏美观性和数据可读性，建议根据数据特点选择合适的图表类型：

- **折线图 (Line chart)**: 适用于展示数据随时间变化的趋势，如CPU使用率、内存使用率等
- **时间序列 (Time series)**: 适用于展示多维度数据的变化趋势，如网络速率、磁盘IO等
- **仪表盘 (Gauge)**: 适用于突出显示关键指标的当前值，如温度、电池电量等，圆形设计直观易读
- **单值 (Stat)**: 适用于突出显示当前实时数据，如当前网络速率、最高温度等
- **表格 (Table)**: 适用于展示详细数据列表，如进程信息、服务状态等

### 常用查询速查

#### CPU 指标

**CPU 使用率** (折线图)

PostgreSQL:
```sql
SELECT timestamp AS "time", cpu_usage::double precision AS "value" FROM cpu_info WHERE $__timeFilter(timestamp) ORDER BY 1;
```

SQLite:
```sql
SELECT timestamp AS "time", cpu_usage AS "value" FROM cpu_info WHERE $__timeFilter(timestamp) ORDER BY 1;
```

**CPU 1分钟负载** (折线图)

PostgreSQL:
```sql
SELECT timestamp AS "time", load_avg_1min::double precision AS "value" FROM cpu_info WHERE $__timeFilter(timestamp) ORDER BY 1;
```

SQLite:
```
SELECT timestamp AS "time", load_avg_1min AS "value" FROM cpu_info WHERE $__timeFilter(timestamp) ORDER BY 1;
```

**CPU 各核心使用率** (折线图-多序列)

PostgreSQL:
```sql
SELECT timestamp AS "time", 
       jsonb_array_elements_text(cpu_info.per_cpu_usage) AS "metric", 
       (jsonb_array_elements(cpu_info.per_cpu_usage)::double precision) AS "value" 
FROM cpu_info 
WHERE $__timeFilter(timestamp) 
ORDER BY 1;
```

SQLite:
```sql
SELECT timestamp AS "time", 
       json_extract(value, '$') AS "metric", 
       json_extract(value, '$') AS "value" 
FROM cpu_info, json_each(cpu_info.per_cpu_usage) 
WHERE $__timeFilter(timestamp) 
ORDER BY 1;
```

#### 内存指标

**内存使用率** (折线图)

PostgreSQL:
```sql
SELECT timestamp AS "time", mem_used_percent::double precision AS "value" FROM memory_info WHERE $__timeFilter(timestamp) ORDER BY 1;
```

SQLite:
```sql
SELECT timestamp AS "time", mem_used_percent AS "value" FROM memory_info WHERE $__timeFilter(timestamp) ORDER BY 1;
```

**内存使用量** (折线图)

PostgreSQL:
```sql
SELECT timestamp AS "time", (mem_used::double precision / 1024 / 1024 / 1024) AS "value" FROM memory_info WHERE $__timeFilter(timestamp) ORDER BY 1; -- 以GB为单位
```

SQLite:
```sql
SELECT timestamp AS "time", (mem_used / 1024 / 1024 / 1024) AS "value" FROM memory_info WHERE $__timeFilter(timestamp) ORDER BY 1; -- 以GB为单位
```

#### 磁盘指标

**磁盘分区使用率** (折线图-多序列)

PostgreSQL:
```sql
SELECT timestamp AS "time", mountpoint AS "metric", used_percent::double precision AS "value" FROM disk_partitions WHERE $__timeFilter(timestamp) ORDER BY 1;
```

SQLite:
```sql
SELECT timestamp AS "time", mountpoint AS "metric", used_percent AS "value" FROM disk_partitions WHERE $__timeFilter(timestamp) ORDER BY 1;
```

**磁盘读取字节** (折线图-多序列)

PostgreSQL:
```sql
SELECT timestamp AS "time", device AS "metric", read_bytes::bigint AS "value" FROM disk_io WHERE $__timeFilter(timestamp) ORDER BY 1;
```

SQLite:
```sql
SELECT timestamp AS "time", device AS "metric", read_bytes AS "value" FROM disk_io WHERE $__timeFilter(timestamp) ORDER BY 1;
```

**磁盘写入字节** (折线图-多序列)

PostgreSQL:
```sql
SELECT timestamp AS "time", device AS "metric", write_bytes::bigint AS "value" FROM disk_io WHERE $__timeFilter(timestamp) ORDER BY 1;
```

SQLite:
```sql
SELECT timestamp AS "time", device AS "metric", write_bytes AS "value" FROM disk_io WHERE $__timeFilter(timestamp) ORDER BY 1;
```

#### 网络指标

**网络发送字节** (折线图-多序列)

PostgreSQL:
```sql
SELECT timestamp AS "time", interface AS "metric", bytes_sent::bigint AS "value" FROM network_io WHERE $__timeFilter(timestamp) AND bytes_sent > 0 ORDER BY 1;
```

SQLite:
```sql
SELECT timestamp AS "time", interface AS "metric", bytes_sent AS "value" FROM network_io WHERE $__timeFilter(timestamp) AND bytes_sent > 0 ORDER BY 1;
```

**网络接收字节** (折线图-多序列)

PostgreSQL:
```sql
SELECT timestamp AS "time", interface AS "metric", bytes_recv::bigint AS "value" FROM network_io WHERE $__timeFilter(timestamp) AND bytes_recv > 0 ORDER BY 1;
```

SQLite:
```sql
SELECT timestamp AS "time", interface AS "metric", bytes_recv AS "value" FROM network_io WHERE $__timeFilter(timestamp) AND bytes_recv > 0 ORDER BY 1;
```

**实时网络发送速率** (Time series/时间序列-多序列，单位：Mbps)

PostgreSQL:
```sql
SELECT 
    timestamp AS "time",
    interface AS "metric",
    CASE 
        WHEN lag(bytes_sent) OVER (PARTITION BY interface ORDER BY timestamp) IS NOT NULL 
        THEN (bytes_sent - lag(bytes_sent) OVER (PARTITION BY interface ORDER BY timestamp)) * 8.0 / 
             EXTRACT(EPOCH FROM (timestamp - lag(timestamp) OVER (PARTITION BY interface ORDER BY timestamp))) / 1024 / 1024
        ELSE 0 
    END AS "value"
FROM network_io 
WHERE $__timeFilter(timestamp) AND bytes_sent > 0
ORDER BY timestamp;
```

SQLite:
```sql
SELECT 
    timestamp AS "time",
    interface AS "metric",
    CASE 
        WHEN (SELECT bytes_sent FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1) IS NOT NULL 
        THEN (bytes_sent - (SELECT bytes_sent FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1)) * 8.0 / 
             (strftime('%s', timestamp) - strftime('%s', (SELECT timestamp FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1))) / 1024 / 1024
        ELSE 0 
    END AS "value"
FROM network_io 
WHERE $__timeFilter(timestamp) AND bytes_sent > 0
ORDER BY timestamp;
```

**实时网络接收速率** (Time series/时间序列-多序列，单位：Mbps)

PostgreSQL:
```sql
SELECT 
    timestamp AS "time",
    interface AS "metric",
    CASE 
        WHEN lag(bytes_recv) OVER (PARTITION BY interface ORDER BY timestamp) IS NOT NULL 
        THEN (bytes_recv - lag(bytes_recv) OVER (PARTITION BY interface ORDER BY timestamp)) * 8.0 / 
             EXTRACT(EPOCH FROM (timestamp - lag(timestamp) OVER (PARTITION BY interface ORDER BY timestamp))) / 1024 / 1024
        ELSE 0 
    END AS "value"
FROM network_io 
WHERE $__timeFilter(timestamp) AND bytes_recv > 0
ORDER BY timestamp;
```

SQLite:
```sql
SELECT 
    timestamp AS "time",
    interface AS "metric",
    CASE 
        WHEN (SELECT bytes_recv FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1) IS NOT NULL 
        THEN (bytes_recv - (SELECT bytes_recv FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1)) * 8.0 / 
             (strftime('%s', timestamp) - strftime('%s', (SELECT timestamp FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1))) / 1024 / 1024
        ELSE 0 
    END AS "value"
FROM network_io 
WHERE $__timeFilter(timestamp) AND bytes_recv > 0
ORDER BY timestamp;
```

**当前网络发送速率** (Stat/单値，单位：Mbps)

PostgreSQL:
```sql
SELECT 
    timestamp AS "time",
    CASE 
        WHEN lag(bytes_sent) OVER (PARTITION BY interface ORDER BY timestamp) IS NOT NULL 
        THEN (bytes_sent - lag(bytes_sent) OVER (PARTITION BY interface ORDER BY timestamp)) * 8.0 / 
             EXTRACT(EPOCH FROM (timestamp - lag(timestamp) OVER (PARTITION BY interface ORDER BY timestamp))) / 1024 / 1024
        ELSE 0 
    END AS "value"
FROM network_io 
WHERE $__timeFilter(timestamp) AND bytes_sent > 0
ORDER BY timestamp DESC LIMIT 1;
```

SQLite:
```sql
SELECT 
    timestamp AS "time",
    CASE 
        WHEN (SELECT bytes_sent FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1) IS NOT NULL 
        THEN (bytes_sent - (SELECT bytes_sent FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1)) * 8.0 / 
             (strftime('%s', timestamp) - strftime('%s', (SELECT timestamp FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1))) / 1024 / 1024
        ELSE 0 
    END AS "value"
FROM network_io 
WHERE $__timeFilter(timestamp) AND bytes_sent > 0
ORDER BY timestamp DESC LIMIT 1;
```

**当前网络接收速率** (Stat/单値，单位：Mbps)

PostgreSQL:
```sql
SELECT 
    timestamp AS "time",
    CASE 
        WHEN lag(bytes_recv) OVER (PARTITION BY interface ORDER BY timestamp) IS NOT NULL 
        THEN (bytes_recv - lag(bytes_recv) OVER (PARTITION BY interface ORDER BY timestamp)) * 8.0 / 
             EXTRACT(EPOCH FROM (timestamp - lag(timestamp) OVER (PARTITION BY interface ORDER BY timestamp))) / 1024 / 1024
        ELSE 0 
    END AS "value"
FROM network_io 
WHERE $__timeFilter(timestamp) AND bytes_recv > 0
ORDER BY timestamp DESC LIMIT 1;
```

SQLite:
```sql
SELECT 
    timestamp AS "time",
    CASE 
        WHEN (SELECT bytes_recv FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1) IS NOT NULL 
        THEN (bytes_recv - (SELECT bytes_recv FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1)) * 8.0 / 
             (strftime('%s', timestamp) - strftime('%s', (SELECT timestamp FROM network_io ni2 WHERE ni2.interface = network_io.interface AND ni2.timestamp < network_io.timestamp ORDER BY ni2.timestamp DESC LIMIT 1))) / 1024 / 1024
        ELSE 0 
    END AS "value"
FROM network_io 
WHERE $__timeFilter(timestamp) AND bytes_recv > 0
ORDER BY timestamp DESC LIMIT 1;
```

#### 进程指标

**Top 10 进程** (表格)

PostgreSQL:
```sql
SELECT timestamp, pid, name, cpu_percent::double precision AS cpu_percent, memory_percent::double precision AS memory_percent, memory_rss FROM processes WHERE $__timeFilter(timestamp) ORDER BY cpu_percent DESC LIMIT 10;
```

SQLite:
```sql
SELECT timestamp, pid, name, cpu_percent, memory_percent, memory_rss FROM processes WHERE $__timeFilter(timestamp) ORDER BY cpu_percent DESC LIMIT 10;
```

#### 传感器指标

**CPU 传感器温度** (折线图-多序列)

PostgreSQL:
```sql
SELECT 
    timestamp AS "time",
    temp_key AS "metric",
    (temp_value::double precision) AS "value"
FROM sensors, 
     jsonb_each_text(cpu_temperature) AS t(temp_key, temp_value)
WHERE $__timeFilter(timestamp) AND cpu_temperature IS NOT NULL
  AND temp_value IS NOT NULL
ORDER BY 1;
```

SQLite:
```sql
SELECT 
    timestamp AS "time",
    key AS "metric",
    json_extract(value, '$') AS "value"
FROM sensors, json_each(cpu_temperature)
WHERE $__timeFilter(timestamp) AND cpu_temperature IS NOT NULL
  AND json_extract(value, '$') IS NOT NULL
ORDER BY 1;
```

**当前CPU最高温度** (Gauge/仪表盘)

PostgreSQL:
```sql
SELECT 
    timestamp AS "time",
    MAX(temp_value::double precision) AS "value"
FROM sensors, 
     jsonb_each_text(cpu_temperature) AS t(temp_key, temp_value)
WHERE $__timeFilter(timestamp) AND cpu_temperature IS NOT NULL
  AND temp_value IS NOT NULL
GROUP BY timestamp
ORDER BY timestamp DESC LIMIT 1; -- 获取最新数据
```

SQLite:
```sql
SELECT 
    timestamp AS "time",
    MAX(json_extract(value, '$')) AS "value"
FROM sensors, json_each(cpu_temperature)
WHERE $__timeFilter(timestamp) AND cpu_temperature IS NOT NULL
  AND json_extract(value, '$') IS NOT NULL
GROUP BY timestamp
ORDER BY timestamp DESC LIMIT 1; -- 获取最新数据
```

**CPU温度趋势** (Time series/时间序列)

PostgreSQL:
```sql
SELECT 
    timestamp AS "time",
    'CPU Temperature' AS "series",
    MAX(temp_value::double precision) AS "value"
FROM sensors, 
     jsonb_each_text(cpu_temperature) AS t(temp_key, temp_value)
WHERE $__timeFilter(timestamp) AND cpu_temperature IS NOT NULL
  AND temp_value IS NOT NULL
GROUP BY timestamp
ORDER BY timestamp;
```

SQLite:
```sql
SELECT 
    timestamp AS "time",
    'CPU Temperature' AS "series",
    MAX(json_extract(value, '$')) AS "value"
FROM sensors, json_each(cpu_temperature)
WHERE $__timeFilter(timestamp) AND cpu_temperature IS NOT NULL
  AND json_extract(value, '$') IS NOT NULL
GROUP BY timestamp
ORDER BY timestamp;
```

**电池电量** (Gauge/仪表盘)

PostgreSQL:
```sql
SELECT 
    timestamp AS "time",
    (jsonb_extract_path_text(battery, 'percent'))::double precision AS "value"
FROM sensors 
WHERE $__timeFilter(timestamp) AND battery IS NOT NULL
ORDER BY timestamp DESC LIMIT 1; -- 获取最新数据
```

SQLite:
```sql
SELECT 
    timestamp AS "time",
    json_extract(battery, '$.percent') AS "value"
FROM sensors 
WHERE $__timeFilter(timestamp) AND battery IS NOT NULL
ORDER BY timestamp DESC LIMIT 1; -- 获取最新数据
```

**电池状态** (表格)

PostgreSQL:
```sql
SELECT 
    timestamp,
    (jsonb_extract_path_text(battery, 'percent'))::double precision AS "电量(%)",
    CASE WHEN (jsonb_extract_path_text(battery, 'power_plugged'))::text = 'true' THEN '充电中' ELSE '未充电' END AS "充电状态",
    (jsonb_extract_path_text(battery, 'secsleft'))::bigint AS "剩余时间(秒)"
FROM sensors 
WHERE $__timeFilter(timestamp) AND battery IS NOT NULL
ORDER BY timestamp DESC LIMIT 1;
```

SQLite:
```sql
SELECT 
    timestamp,
    json_extract(battery, '$.percent') AS "电量(%)",
    CASE WHEN json_extract(battery, '$.power_plugged') = 1 THEN '充电中' ELSE '未充电' END AS "充电状态",
    json_extract(battery, '$.secsleft') AS "剩余时间(秒)"
FROM sensors 
WHERE $__timeFilter(timestamp) AND battery IS NOT NULL
ORDER BY timestamp DESC LIMIT 1;
```

#### Windows 服务状态

**Windows 服务状态** (表格)

PostgreSQL:
```sql
SELECT DISTINCT ON (name) name, status, start_type, pid, timestamp FROM windows_services WHERE $__timeFilter(timestamp) ORDER BY name, timestamp DESC;
```

SQLite:
```sql
SELECT ws.name, ws.status, ws.start_type, ws.pid, ws.timestamp FROM windows_services ws JOIN (SELECT name, MAX(timestamp) AS ts FROM windows_services GROUP BY name) t ON t.name = ws.name AND t.ts = ws.timestamp WHERE $__timeFilter(ws.timestamp);
```

### 快速创建建议

按以下顺序创建面板，以实现大屏美观性与数据合理性的平衡：

1. **CPU 使用率** - 折线图
2. **CPU 1分钟负载** - 折线图
3. **内存使用率** - 折线图
4. **磁盘分区使用率** - 折线图（多序列）
5. **当前CPU最高温度** - Gauge/仪表盘（突出显示当前温度）
6. **CPU温度趋势** - Time series/时间序列（显示温度变化趋势）
7. **电池电量** - Gauge/仪表盘（圆形显示电量百分比）
8. **当前网络发送速率** - Stat/单値（突出显示当前上传速率）
9. **当前网络接收速率** - Stat/单値（突出显示当前下载速率）
10. **实时网络发送速率** - Time series/时间序列（多序列，Mbps）
11. **实时网络接收速率** - Time series/时间序列（多序列，Mbps）
12. **网络发送字节** - 折线图（多序列）
13. **网络接收字节** - 折线图（多序列）
14. **磁盘读取** - 折线图（多序列）
15. **磁盘写入** - 折线图（多序列）
16. **CPU 传感器温度** - 折线图（多序列）
17. **电池状态** - 表格
18. **Top 10 进程** - 表格
19. **Windows 服务** - 表格

保存为 `MetricCollector Overview`。

## 四、验证与排错

| 问题 | 解决方案 |
|------|----------|
| 时间轴不显示 | 查询返回列名必须是 `"time"` |
| 无数据 | 确保 `$__timeFilter(timestamp)` 包含在 WHERE 子句中 |
| 数据类型错误 | PostgreSQL 加 `::double precision` / `::bigint`，SQLite 不加 |
| 多序列不显示 | 确保查询返回 `metric` 列作为序列标签 |
| JSON查询错误 | 检查数据库类型，PostgreSQL使用`jsonb`操作符，SQLite使用`json`函数 |
| 传感器数据不显示 | 确认硬件支持温度/电池检测，检查`sensors`表中是否有数据 |
| 实时速率图表异常 | 确保有足够的历史数据点用于计算差值 |

## 五、自动化配置（可选）

### 配置数据源自动加载

**PostgreSQL** (`provisioning/datasources/datasources.yaml`):
```yaml
apiVersion: 1
datasources:
  - name: MetricCollector Postgres
    type: postgres
    access: proxy
    url: developer.com:5432
    database: metric_collector_master
    user: postgres
    secureJsonData:
      password: 123456
    jsonData:
      sslmode: disable
      postgresVersion: 1200
```

**SQLite** (`provisioning/datasources/datasources.yaml`):
```yaml
apiVersion: 1
datasources:
  - name: MetricCollector SQLite
    type: frser-sqlite-datasource
    access: proxy
    jsonData:
      path: e:\gitee\tutor-python\examples\metric_collector\db.sqlite3
```

### 仪表盘自动加载

`provisioning/dashboards/dashboards.yaml`:
```yaml
apiVersion: 1
providers:
  - name: MetricCollector
    type: file
    disableDeletion: true
    allowUiUpdates: true
    options:
      path: C:\grafana\dashboards
```

将 `dashboard.json` 文件放入 `C:\grafana\dashboards` 目录。
