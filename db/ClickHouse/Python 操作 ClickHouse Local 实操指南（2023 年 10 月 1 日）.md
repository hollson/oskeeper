

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

