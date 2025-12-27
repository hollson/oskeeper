# ClickHouse 高效写入数据实操指南（含 Local 模式）

ClickHouse 作为 OLAP 引擎，**写入性能的核心是适配其列式存储和批量处理特性**——单条写入效率极低，批量写入才能发挥极致性能。本文结合实操案例，讲解 ClickHouse 服务端 + Local 模式的快速写入方法，覆盖高频场景和性能优化技巧。

## 一、核心原则：先明确写入优化的底层逻辑
ClickHouse 写入的核心优化方向是「减少写入次数、增大单次写入量、适配存储引擎特性」，先记住 3 个关键原则：
1. **批量写入优先**：单次写入 1000~100000 行（推荐 10 万行级），远优于单条/小批量循环写入；
2. **避免高频小写入**：频繁小写入会产生大量小数据片段，触发频繁合并（Merge），占用 IO/CPU；
3. **选对引擎和格式**：MergeTree 系列引擎（默认）适配批量写入，Parquet/TSV 等格式比 JSON 写入更快。

## 二、ClickHouse 服务端：高频写入场景实操
### 1. 基础批量写入：INSERT 语句（最常用）
#### （1）单条 INSERT 批量写入多行
直接在 INSERT 中包含多条数据，适合测试/小批量数据导入：
```sql
-- 创建测试表（MergeTree 引擎，按 id 排序）
CREATE TABLE user_salary (
    id UInt8,
    name String,
    age UInt8,
    city String,
    salary UInt32
) ENGINE = MergeTree()
ORDER BY id;

-- 批量插入 5 行数据（推荐写法）
INSERT INTO user_salary VALUES
(1, '张三', 25, '北京', 10000),
(2, '李四', 30, '上海', 15000),
(3, '王五', 28, '广州', 12000),
(4, '赵六', 35, '深圳', 20000),
(5, '孙七', 27, '北京', 11000);
```

#### （2）从文件导入（大文件首选）
通过 `clickhouse-client` 直接导入本地文件，支持 TSV/CSV/Parquet 等格式，效率远高于逐条 INSERT：
```bash
# 示例：导入 TSV 文件（第一行是列名）到服务端
clickhouse-client --host 你的CH地址 --port 9000 --user 用户名 --password 密码 \
--database 数据库名 \
--query "INSERT INTO user_salary FORMAT TSVWithNames" \
--input-file test_data.tsv
```
- 格式适配：根据文件类型修改 `FORMAT`（如 CSVWithNames/Parquet/JSONEachRow）；
- 大文件提速：添加 `--max_insert_block_size=100000`（单次写入块大小，默认 1048576）。

#### （3）从查询结果写入（数据迁移/转换）
将一张表的查询结果批量写入另一张表，适合数据清洗后导入：
```sql
-- 示例：从临时表导入数据到目标表（筛选+转换后）
INSERT INTO user_salary_new
SELECT id, name, age, city, salary*1.1 as salary 
FROM user_salary_old 
WHERE city = '北京';
```

### 2. 高性能写入：使用 ClickHouse Bulk API/工具
#### （1）clickhouse-benchmark（压测/批量写入）
官方压测工具，可模拟高并发批量写入，适合验证写入性能：
```bash
# 示例：每秒写入 10 万行，持续 10 秒
clickhouse-benchmark --host 你的CH地址 --port 9000 \
--user 用户名 --password 密码 \
--database 数据库名 \
--table user_salary \
--max-requests 1000000 \
--requests-per-second 100000 \
--format TSV
```

#### （2）第三方工具（生产级）
- **clickhouse-connect**（Python）：支持批量写入 Pandas DataFrame，适合数据处理后导入；
  ```python
  import clickhouse_connect
  import pandas as pd
  
  # 连接 ClickHouse
  client = clickhouse_connect.get_client(host='你的CH地址', port=8123, user='用户名', password='密码')
  
  # 构造 DataFrame
  df = pd.DataFrame({
      'id': [1,2,3],
      'name': ['张三','李四','王五'],
      'age': [25,30,28],
      'city': ['北京','上海','广州'],
      'salary': [10000,15000,12000]
  })
  
  # 批量写入（自动分块，默认 10 万行/块）
  client.insert_df('user_salary', df)
  ```
- **Flink/Spark 连接器**：大数据量（TB 级）场景，通过计算引擎批量写入，适配分布式场景。

### 3. 服务端写入性能优化（关键配置）
修改 `config.xml` 或 `users.xml` 调整写入相关配置，大幅提升效率：
| 配置项 | 推荐值 | 说明 |
|--------|--------|------|
| `max_insert_block_size` | 100000~1000000 | 单次插入的块大小，越大越高效（需匹配内存） |
| `min_insert_block_size_rows` | 10000 | 触发写入的最小行数，避免小文件 |
| `merge_tree_min_rows_for_wide_part` | 100000 | 宽分区阈值，减少小分区合并 |
| `async_insert` | 1 | 开启异步插入（客户端无需等待写入完成） |
| `wait_for_async_insert` | 0 | 异步插入不等待结果（极致性能） |

## 三、ClickHouse Local：本地文件写入实操
ClickHouse Local 无服务端，写入核心是「写入临时表」或「输出为新文件」，适合本地数据处理后导出。

### 1. 写入临时表（Memory 引擎，测试用）
```bash
# 示例：创建 Memory 表并批量写入，查询验证
clickhouse local --output-format PrettyCompact \
--query "
CREATE TABLE temp_salary (id UInt8, name String, age UInt8, city String, salary UInt32) ENGINE = Memory;
-- 批量写入
INSERT INTO temp_salary VALUES (1,'张三',25,'北京',10000),(2,'李四',30,'上海',15000),(3,'王五',28,'广州',12000);
SELECT * FROM temp_salary;
"
```

### 2. 写入本地文件（生产级，格式转换/筛选后导出）
这是 Local 模式最常用的“写入”场景——将处理后的数据输出为新文件，等价于“写入到本地存储”：
```bash
# 示例1：将筛选后的数据写入 Parquet 文件（压缩比高，后续导入服务端更快）
clickhouse local --file test_data.tsv --input-format TSVWithNames \
--query "SELECT * FROM table WHERE city IN ('北京','上海')" \
--output-format Parquet > filtered_data.parquet

# 示例2：批量生成测试数据并写入 TSV 文件
clickhouse local --output-format TSVWithNames \
--query "
SELECT number as id, 
       concat('用户', toString(number)) as name,
       rand()%30 + 20 as age,
       ['北京','上海','广州','深圳'][rand()%4 + 1] as city,
       rand()%10000 + 10000 as salary
FROM numbers(100000)  -- 生成 10 万行测试数据
" > test_data_10w.tsv
```

### 3. Local → 服务端：本地文件快速导入服务端
先通过 Local 处理本地文件（清洗/格式转换），再导入服务端，兼顾灵活性和性能：
```bash
# 步骤1：Local 处理文件（筛选+转换为 Parquet）
clickhouse local --file test_data.tsv --input-format TSVWithNames \
--query "SELECT id, name, age, city, salary FROM table WHERE age > 25" \
--output-format Parquet > processed_data.parquet

# 步骤2：导入 Parquet 文件到服务端（Parquet 列式存储，导入效率比 TSV 高 2~5 倍）
clickhouse-client --host 你的CH地址 --port 9000 --user 用户名 --password 密码 \
--database 数据库名 \
--query "INSERT INTO user_salary FORMAT Parquet" \
--input-file processed_data.parquet
```

## 四、避坑指南：写入常见问题与解决
### 1. 写入慢/IO 高
- 原因：频繁小写入、数据片段过多、未开启异步插入；
- 解决：
  - 合并小写入为批量（比如客户端缓存 10 万行再提交）；
  - 开启 `async_insert = 1` 异步插入；
  - 执行 `OPTIMIZE TABLE 表名 FINAL` 手动合并小片段（仅离线场景）。

### 2. 数据写入后查询不到
- 原因：MergeTree 引擎写入后数据未合并（异步）、异步插入未等待；
- 解决：
  - 测试时添加 `SET wait_for_async_insert = 1`；
  - 查询时加 `SET merge_tree_read_split_microseconds = 0`（强制读取所有片段）。

### 3. Local 模式导入服务端乱码
- 解决：导入前统一字符集，执行 `export LANG=zh_CN.UTF-8`（Linux/macOS）或 `chcp 65001`（Windows）。

## 五、写入规范总结
| 场景                | 推荐写入方式                          | 性能优化点                                  |
|---------------------|---------------------------------------|---------------------------------------------|
| 服务端小批量（<1 万行） | INSERT 多行语句                       | 单次插入 ≥1000 行，避免循环单条插入         |
| 服务端大批量（≥1 万行） | clickhouse-client 导入文件（Parquet 优先） | 调整 `max_insert_block_size`，开启异步插入  |
| 本地数据处理后导入     | Local 转换为 Parquet → 服务端导入     | 先筛选/清洗，减少导入数据量                 |
| 大数据量（TB 级）      | Flink/Spark 分布式写入                | 按分区写入，避免单节点压力                  |

ClickHouse 写入的核心是“批量”和“适配引擎特性”——放弃 OLTP 式的单条写入思维，优先用文件导入、批量 INSERT、异步写入等方式，就能最大化其写入性能。Local 模式则聚焦“本地数据预处理+格式转换”，再导入服务端，是兼顾灵活性和性能的最佳实践。