# ClickHouse Local 标准入门文档（精简版）
## 一、核心定义
ClickHouse Local 是 ClickHouse 官方出品的**无服务端、轻量级命令行工具**，复用 ClickHouse 核心引擎，无需部署/启动 `clickhouse-server`，可直接在本地执行高性能的数据分析、数据转换、文件读写操作，主打离线批量处理，适配各类结构化数据文件。
✅ 核心优势：无服务依赖、极致分析性能、兼容 ClickHouse 99% SQL、支持多数据格式。

## 二、快速部署（全平台）
### ✅ 部署要求
无需安装，仅需下载对应系统的 **[ClickHouse 二进制包](https://packages.clickhouse.com/tgz/stable/)**，解压即可使用，无额外依赖。
### ✅ 快速获取（Linux/macOS 推荐）
```bash
# 方式1：官方一键下载（Linux）
curl https://clickhouse.com/ | sh

# 方式2：解压后直接使用，验证可用性
./clickhouse local --version
```
> 补充：Windows 建议用 WSL 运行；二进制包解压后，`clickhouse local` 为核心可执行命令。

## 三、核心语法（通用模板）
```bash
# 基础执行格式
clickhouse local -q "【你的SQL语句】"
```
### ✅ 核心关键字：`file()`
操作本地文件的核心函数，所有文件读写均基于此，语法规范：
```sql
file('文件路径', '文件格式', '字段名1 字段类型1, 字段名2 字段类型2,...')
```
- 必填1：文件路径（绝对/相对路径均可）
- 必填2：文件格式（CSV/TSV/Parquet/JSONEachRow 为高频）
- 必填3：字段schema（字段名+ClickHouse数据类型，如 `id UInt32, name String`）

## 四、高频核心用法（即学即用）
### 1. 读取本地文件 & 数据查询
支持**单表查询、聚合分析、条件过滤、排序**，完全兼容 ClickHouse 分析型SQL。
```bash
# 示例1：读取CSV文件，统计聚合结果
clickhouse local -q "SELECT id, SUM(score) AS total FROM file('score.csv', 'CSV', 'id UInt32, name String, score UInt8') GROUP BY id ORDER BY total DESC"

# 示例2：读取JSON文件，过滤时间范围数据
clickhouse local -q "SELECT * FROM file('logs.json', 'JSONEachRow', 'msg String, ts DateTime') WHERE ts > toDateTime('2025-01-01') LIMIT 10"
```

### 2. 数据导出 & 格式转换
将查询结果写入本地文件，实现 **CSV→Parquet、JSON→TSV** 等格式互转（Parquet为高性能列式格式，推荐）。
```bash
# 示例1：CSV转Parquet（极致压缩+高性能）
clickhouse local -q "SELECT * FROM file('data.csv', 'CSV', 'id UInt32, val Float64') INTO OUTFILE 'data.parquet' FORMAT Parquet"

# 示例2：查询结果导出为TSV文件
clickhouse local -q "SELECT id, avg(val) FROM file('data.csv', 'CSV') GROUP BY id INTO OUTFILE 'result.tsv' FORMAT TSV"
```

### 3. 多文件联合查询
直接关联本地多个文件，实现跨文件分析，无需提前导入数据。
```bash
# 示例：关联用户表+订单表，统计用户消费总额
clickhouse local -q "
    SELECT u.id, u.name, SUM(o.amount) AS pay_total
    FROM file('user.csv', 'CSV', 'id UInt32, name String') u
    LEFT JOIN file('order.csv', 'CSV', 'uid UInt32, amount Float64') o ON u.id = o.uid
    GROUP BY u.id, u.name
"
```

### 4. 临时表 & 数据预处理
创建内存临时表，实现复杂数据清洗、多步预处理，适合批量数据加工。
```bash
clickhouse local -q "
    CREATE TEMP TABLE tmp_data AS SELECT * FROM file('raw_data.csv', 'CSV', 'id UInt32, val Float64') WHERE val > 0;
    SELECT id, round(val,2) AS val_clean FROM tmp_data ORDER BY id;
"
```

## 五、支持的核心特性（精简）
### ✅ 支持的文件格式（高频）
CSV、TSV、Parquet、JSONEachRow、ORC、Excel（XLSX），满足日常离线数据场景。
### ✅ 支持的核心能力
1. 全量 ClickHouse 分析型SQL（聚合、窗口函数、JOIN、子查询、函数）；
2. 数据格式一键转换、文件拆分/合并；
3. 内存级临时表、数据清洗过滤；
4. 超大文件分片处理（自动适配本地算力，不卡顿）。

### ❌ 不支持的特性（避坑）
1. 无事务、无增删改（仅支持读+批量写，不适合联机业务）；
2. 无网络服务、无集群能力（纯本地操作）；
3. 无持久化专属数据库文件（仅操作原始数据文件）。

## 六、典型适用场景
✅ 本地日志文件离线分析（GB/TB级）；
✅ 结构化数据格式转换（CSV→Parquet 首选）；
✅ 离线数据清洗、预处理、聚合统计；
✅ 快速验证 ClickHouse SQL 语法；
✅ 轻量级ETL批量任务。

## 七、常用参数速查（极简）
| 参数 | 作用 | 示例 |
|:--- |:--- |:--- |
| `-q` | 直接执行SQL语句（最常用） | `clickhouse local -q "SQL语句"` |
| `--input-format` | 指定默认输入格式 | `clickhouse local -q "SQL" --input-format CSV` |
| `--output-format` | 指定默认输出格式 | `clickhouse local -q "SQL" --output-format Parquet` |
| `-f` | 从SQL文件中执行语句 | `clickhouse local -f query.sql` |