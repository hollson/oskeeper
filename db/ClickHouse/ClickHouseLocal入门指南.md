# ClickHouse Local 极简实操指南

[**ClickHouse Local**](https://clickhouse.com/docs/zh/operations/utilities/clickhouse-local) 是 ClickHouse 官方的轻量级本地数据处理工具，直接在本地就能用SQL分析**CSV、JSON、Parquet**等格式文件。



## 一、安装CK

### 1.1 Linux/MacOS 系统

```bash
# 下载ClickHouse客户端（包含 local 工具）
$ curl https://clickhouse.com/ | sh
$ ./clickhouse local --version
$ ./clickhouse -V

# [选] 安装到目标目录
$ mv clickhouse ~/.local/bin/

# 添加别名
# CSVWithNames:逗号分隔,如xxx.csv
# TSVWithNames:制表符分隔,如xxx.tsv
$ alias ck='clickhouse'
$ alias ckl='clickhouse local --output-format PrettyCompact'
```
### 1.2  Windows 系统

> [**ClickHouse 官方下载页**](https://clickhouse.com/docs/zh/install/#binary-tarballs) 下载并安装。



### 1.3 安装验证

```shell
$ clickhouse -V
$ clickhouse --help
$ clickhouse local --help
$ clickhouse --query "SELECT version()"
$ clickhouse local --query "SELECT version()"
```



<br/>



## 二、基础入门

### 1.3 ClickHouse 命令





<br/>



## 2.5 常用场景速查

| 场景                | 核心命令模板                                                                 |
|---------------------|------------------------------------------------------------------------------|
| 查Nginx日志（JSON） | `clickhouse local --file access.log --input-format JSONEachRow --query "SELECT remote_addr, COUNT(*) FROM table GROUP BY remote_addr"` |
| CSV转Parquet        | `clickhouse local --file 数据.csv --input-format CSVWithNames --query "SELECT * FROM table" --output-format Parquet > 数据.parquet` |
| 统计文件行数        | `clickhouse local --file 大文件.tsv --input-format TSV --query "SELECT COUNT(*) FROM table"` |
| 按条件筛选并导出    | `clickhouse local --file 数据.tsv --input-format TSVWithNames --query "SELECT * FROM table WHERE age > 30" --output-format CSV > 筛选结果.csv` |



<br/>





## 三、实战演练

### 2.1 数据格式

**ClickHouse** 支持大多数已知的文本和二进制[**数据格式**](https://clickhouse.com/docs/zh/interfaces/formats)，从而可以轻松集成到几乎任何现有的数据管道中，充分发挥 ClickHouse 的优势。

#### 示例1：TSV文件测试

- 新建文本文件 `user.tsv`（TSV 是制表符分隔，用记事本/VSCode 编辑），输入格式为**TSVWithNames**：

```
id	name	age	city	salary
1	张三	25	北京	10000
2	李四	30	上海	15000
3	王五	28	广州	12000
4	赵六	35	深圳	20000
5	孙七	27	北京	11000
```
```shell
# 简化命令
$ ckl -F user.tsv -q "SELECT * FROM table"
┌─id─┬─name─┬─age─┬─city─┬─salary─┐
│  1 │ 张三  │  25 │ 北京 │ 10000  │
│  2 │ 李四  │  30 │ 上海 │ 15000  │
│  3 │ 王五  │  28 │ 广州 │ 12000  │
│  4 │ 赵六  │  35 │ 深圳 │ 20000  │
│  5 │ 孙七  │  27 │ 北京 │ 11000  │
└────┴──────┴─────┴──────┴────────┘

# 完整命令
$ clickhouse local --file user.tsv --input-format TSVWithNames --output-format PrettyCompact --query "SELECT * FROM table"
```



#### 示例2：CSV文件测试

- 新建文本文件 `user.csv`,  输入格式为**CSVWithNames**：

```csv
id,name,age,city,salary
1,张三,25,北京,10000
2,李四,30,上海,15000
3,王五,28,广州,12000
4,赵六,35,深圳,20000
5,孙七,27,北京,11000
```

```shell
# 简化查询
$ ckl -F user.csv -q "SELECT * FROM table"

# 完整命令
$ clickhouse local --file user.csv --input-format CSVWithNames --output-format PrettyCompact --query "SELECT * FROM table"
```



#### 示例3：Json文件测试

先准备 `user.json`（每行一个JSON，复制粘贴），输入格式为**JSONEachRow**：：
```json
{"id":1,"name":"张三","age":25,"city":"北京","salary":10000}
{"id":2,"name":"李四","age":30,"city":"上海","salary":15000}
```
```bash
# 简化查询
$ ckl -F user.json -q "SELECT name, city FROM table WHERE age > 28"

# 完整命令
$ clickhouse local --file user.json --input-format JSONEachRow --query "SELECT name, city FROM table WHERE age > 28"
```


#### 示例4：Parquet文件测试

如果有 `test_data.parquet` 文件，直接执行：
```bash
clickhouse local --file test_data.parquet \
--input-format Parquet \
--output-format PrettyCompact \
--query "SELECT * FROM table LIMIT 10"
```



### 2.2 复杂查询

- **筛选数据：**查北京的用户，按薪资降序

```bash
clickhouse local --file test_data.tsv --input-format TSVWithNames --output-format PrettyCompact \
--query "SELECT name, age, salary FROM table WHERE city = '北京' ORDER BY salary DESC"
```

- **分组统计: ** 按城市算平均薪资、人数

```bash
clickhouse local --file test_data.tsv --input-format TSVWithNames --output-format PrettyCompact \
--query "SELECT city, COUNT(*) as 人数, AVG(salary) as 平均薪资 FROM table GROUP BY city"
```

- **聚合查询：** 计算总和/最大值/最小值

```bash
clickhouse local --file test_data.tsv --input-format TSVWithNames --output-format PrettyCompact \
--query "SELECT SUM(salary) as 薪资总和, MAX(salary) as 最高薪资, MIN(salary) as 最低薪资 FROM table"
```



### 2.3 压缩导出

比如把统计结果导出为CSV，或把TSV转成Parquet（节省空间）：

#### 1. 导出为CSV（带列名）
```bash
clickhouse local --file test_data.tsv --input-format TSVWithNames \
--query "SELECT city, 人数, 平均薪资 FROM (SELECT city, COUNT(*) as 人数, AVG(salary) as 平均薪资 FROM table GROUP BY city)" \
--output-format CSVWithNames > 城市薪资统计.csv
```
执行后，文件夹里会多出 `城市薪资统计.csv`，直接用Excel打开即可。

#### 2. 转成Parquet（推荐，压缩比高）

```bash
clickhouse local --file test_data.tsv --input-format TSVWithNames \
--query "SELECT * FROM table WHERE city = '北京'" \
--output-format Parquet > 北京用户数据.parquet
```



### 示例6：处理大文件（提速小技巧）

如果文件是GB级的，加 `--max_threads` 指定线程数（比如8线程），利用多核提速：
```bash
clickhouse local --file 大文件.tsv \
--input-format TSVWithNames \
--max_threads 8 \
--output-format PrettyCompact \
--query "SELECT city, COUNT(*) FROM table GROUP BY city"
```





### 性能测试

**ClickHouse**为我们提供了多个[示例数据集](https://clickhouse.com/docs/getting-started/example-datasets) ，



我们以**纽约图书馆目录**([New York Public Library "What's on the Menu?" Dataset](https://s3.amazonaws.com/menusdata.nypl.org/gzips/2021_08_01_07_01_17_data.tgz))







## 四、进阶参考

- 支持的文件格式：[ClickHouse 官方格式说明（中文）](https://clickhouse.com/docs/zh/interfaces/formats)；
- SQL语法：和ClickHouse服务端完全一样，参考 [ClickHouse SQL语法（中文）](https://clickhouse.com/docs/zh/sql-reference)；
- 官方文档：[ClickHouse Local 官方指南（中文）](https://clickhouse.com/docs/zh/operations/utilities/clickhouse-local)。

## 总结
ClickHouse Local 最大的优势是「轻量化」——不用装服务、不用配配置文件，拿到文件就能用SQL查。新手先掌握「读文件→查数据→写文件」这三步，就能覆盖80%的日常场景，遇到问题对照「避坑指南」改参数即可。