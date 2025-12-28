# ClickHouseLocal 实操练习
## 核心前提
1. 所有操作基于 ClickHouse-Local 交互界面，**会话内临时有效**，退出后数据库、表、数据全部销毁；
2. 示例以「电商订单」为业务场景，覆盖 ClickHouse 核心语法，适配 ClickHouse 26.x 及以上版本；
3. 无需关注安装流程，默认已进入 ClickHouse-Local 交互界面（提示符：`clickhouse-local :)`）。



## 一、基础约定
- 引擎选择：`Memory`（纯内存，读写最快）、`MergeTree`（模拟 OLAP 核心能力，支持分区/更新/删除）；
- 数据维度：用户表、商品表、订单表，模拟真实电商数据；
- 权限说明：UPDATE/DELETE 需显式开启权限，ClickHouse 主打 OLAP，改删为辅助能力。

## 二、完整实操流程
### 步骤 1：创建数据库（会话级临时库）
```sql
-- 1. 创建电商业务库（不存在则创建）
CREATE DATABASE IF NOT EXISTS ecommerce;

-- 2. 查看所有数据库（验证创建结果）
SHOW DATABASES;

-- 3. 切换到电商数据库（后续操作默认在此库执行）
USE ecommerce;
```
**执行结果参考**：
```
┌─name─────────────────────────┐
│ INFORMATION_SCHEMA           │
│ ecommerce                    │
│ default                      │
│ system                       │
└──────────────────────────────┘
```

### 步骤 2：表的创建与结构管理
#### 1. 创建核心业务表（适配 Enum 类型、分区、排序键）
```sql
-- ① 用户表（Memory 引擎，纯内存存储）
CREATE TABLE IF NOT EXISTS user_info (
    user_id UInt64,                  -- 用户ID（无符号整数）
    user_name String,                -- 用户名
    phone String,                    -- 手机号
    gender Enum8('unknown'=0, 'male'=1, 'female'=2), -- 性别（枚举）
    register_time DateTime           -- 注册时间
) ENGINE = Memory;

-- ② 商品表（MergeTree 引擎，支持磁盘模拟存储）
CREATE TABLE IF NOT EXISTS product (
    product_id UInt64,
    product_name String,
    price Decimal64(2),              -- 价格（保留2位小数）
    category String,                 -- 商品分类
    stock UInt32                     -- 库存
) ENGINE = MergeTree()
ORDER BY product_id;                -- MergeTree 必须指定排序键

-- ③ 订单表（MergeTree 引擎，带分区、主键）
CREATE TABLE IF NOT EXISTS order_info (
    order_id UInt64,
    user_id UInt64,
    product_id UInt64,
    order_amount Decimal64(2),
    order_time DateTime,
    pay_status Enum8('unpaid'=0, 'paid'=1, 'refunded'=2) -- 支付状态
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(order_time)  -- 按年月分区（OLAP 核心优化）
ORDER BY (order_id, user_id);       -- 复合排序键（主键）
```

#### 2. 查看与修改表结构
```sql
-- 1. 查看当前库下所有表
SHOW TABLES;

-- 2. 查看订单表详细结构（含引擎、分区、排序键）
SHOW CREATE TABLE order_info;

-- 3. 修改用户表结构（新增字段）
ALTER TABLE user_info ADD COLUMN IF NOT EXISTS user_level UInt8 AFTER phone;

-- 4. 删除用户表多余字段
ALTER TABLE user_info DROP COLUMN IF EXISTS user_level;

-- 5. 查看修改后的表结构
DESC user_info;
```
**执行结果参考（DESC user_info）**：
```
┌─name──────────┬─type───────────────────────────┬─default_type─┬─default_expression─┐
│ user_id       │ UInt64                         │              │                     │
│ user_name     │ String                         │              │                     │
│ phone         │ String                         │              │                     │
│ gender        │ Enum8('unknown'=0,'male'=1,'female'=2) │              │                     │
│ register_time │ DateTime                       │              │                     │
└───────────────┴────────────────────────────────┴──────────────┴─────────────────────┘
```

#### 3. 删除表
```sql
-- 先创建临时测试表，再删除（验证删除逻辑）
CREATE TABLE test_table (id UInt64) ENGINE = Memory;
DROP TABLE IF EXISTS test_table;

-- 验证删除结果（无 test_table）
SHOW TABLES;
```

### 步骤 3：数据操作（增/查/改/删）
#### 1. 插入数据（批量插入，ClickHouse 推荐方式）
```sql
-- ① 插入用户数据
INSERT INTO user_info VALUES
(1001, '张三', '13800138000', 'male', '2024-01-10 08:30:00'),
(1002, '李四', '13900139000', 'female', '2024-02-15 10:20:00'),
(1003, '王五', '13700137000', 'unknown', '2024-03-20 14:10:00'),
(1004, '赵六', '13600136000', 'male', '2024-04-05 09:00:00');

-- ② 插入商品数据
INSERT INTO product VALUES
(2001, '小米14 Pro', 4999.00, '手机', 1000),
(2002, '华为Mate60', 5999.00, '手机', 800),
(2003, '苹果AirPods Pro', 1999.00, '耳机', 2000),
(2004, '小米手环9', 299.00, '智能穿戴', 5000);

-- ③ 插入订单数据
INSERT INTO order_info VALUES
(3001, 1001, 2001, 4999.00, '2024-05-01 10:00:00', 'paid'),
(3002, 1001, 2003, 1999.00, '2024-05-01 10:05:00', 'paid'),
(3003, 1002, 2002, 5999.00, '2024-05-02 15:30:00', 'unpaid'),
(3004, 1003, 2004, 299.00, '2024-05-03 09:15:00', 'paid'),
(3005, 1004, 2001, 4999.00, '2024-05-04 11:20:00', 'refunded');
```

#### 2. 查询数据（ClickHouse 核心能力，覆盖 OLAP 场景）
##### （1）基础查询
```sql
-- ① 查询所有用户信息
SELECT * FROM user_info;

-- ② 条件筛选：查询已支付的订单
SELECT order_id, user_id, order_amount, order_time 
FROM order_info 
WHERE pay_status = 'paid';

-- ③ 去重查询：统计订单涉及的商品分类
SELECT DISTINCT category 
FROM product p
JOIN order_info o ON p.product_id = o.product_id;
```

##### （2）聚合分析查询（OLAP 典型场景）
```sql
-- ① 按商品分类统计库存
SELECT category, SUM(stock) AS total_stock 
FROM product 
GROUP BY category 
ORDER BY total_stock DESC;

-- ② 统计每个用户的订单数和消费总额
SELECT 
    u.user_id,
    u.user_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.order_amount) AS total_amount
FROM user_info u
LEFT JOIN order_info o ON u.user_id = o.user_id
GROUP BY u.user_id, u.user_name
HAVING total_amount > 0;

-- ③ 按年月分区统计订单金额
SELECT 
    toYYYYMM(order_time) AS order_month,
    toDate(order_time) AS order_date,
    SUM(order_amount) AS daily_amount
FROM order_info
GROUP BY order_month, order_date
ORDER BY order_month, order_date;

-- ④ 计算订单支付率
SELECT 
    COUNT(CASE WHEN pay_status = 'paid' THEN 1 END) / COUNT(*) AS pay_rate
FROM order_info;

-- ⑤ 商品销量 Top2
SELECT 
    p.product_name,
    SUM(o.order_amount) AS sales_amount
FROM product p
JOIN order_info o ON p.product_id = o.product_id
GROUP BY p.product_name
ORDER BY sales_amount DESC
LIMIT 2;
```

#### 3. 修改数据（UPDATE，需开启权限）
```sql
-- ① 开启更新权限（会话内有效）
SET allow_experimental_lightweight_delete = 1;
SET allow_update = 1;

-- ② 修改订单3003的支付状态（未支付→已支付）
UPDATE order_info 
SET pay_status = 'paid', order_time = '2024-05-02 16:00:00'
WHERE order_id = 3003;

-- ③ 验证修改结果
SELECT order_id, pay_status, order_time FROM order_info WHERE order_id = 3003;
```
**执行结果参考**：
```
┌─order_id─┬─pay_status─┬────────────order_time─┐
│ 3003     │ paid       │ 2024-05-02 16:00:00   │
└──────────┴────────────┴───────────────────────┘
```

#### 4. 删除数据（DELETE，需开启权限）
```sql
-- ① 开启删除权限（会话内有效）
SET allow_delete = 1;

-- ② 删除退款的订单（订单3005）
DELETE FROM order_info WHERE pay_status = 'refunded';

-- ③ 验证删除结果（无退款订单）
SELECT * FROM order_info WHERE pay_status = 'refunded';
```

### 步骤 4：数据导出（持久化临时数据）
clickhouse-local 数据默认会话级丢失，可导出到本地文件留存：
```sql
-- ① 导出用户表到 CSV 文件（带表头）
SELECT * FROM user_info 
INTO OUTFILE '/tmp/ecommerce_user.csv' 
FORMAT CSV WITH HEADERS;

-- ② 导出订单表到 Parquet 文件（列存格式，OLAP 常用）
SELECT * FROM order_info 
INTO OUTFILE '/tmp/ecommerce_order.parquet' 
FORMAT Parquet;

-- ③ 验证导出（退出 clickhouse-local 后执行）
-- cat /tmp/ecommerce_user.csv
```

### 步骤 5：清理操作（可选）
```sql
-- ① 清空表数据
TRUNCATE TABLE user_info;

-- ② 删除单个表
DROP TABLE IF EXISTS product;

-- ③ 级联删除数据库（删除库及所有表）
DROP DATABASE IF EXISTS ecommerce CASCADE;

-- ④ 验证清理结果
SHOW DATABASES; -- 无 ecommerce 库
```

## 三、常见问题与避坑
| 问题现象                                  | 原因                                  | 解决方案                                  |
|-------------------------------------------|---------------------------------------|-------------------------------------------|
| Cannot parse expression of type Enum8     | Enum 值与表定义不匹配（大小写/拼写）  | 确保插入值（如'male'）与表定义 Enum 字符串完全一致 |
| UPDATE/DELETE 执行失败                    | 未开启权限或引擎不支持                | 执行 `SET allow_update=1; allow_delete=1`，仅 MergeTree 引擎支持改删 |
| MergeTree 表创建失败                      | 未指定 ORDER BY 排序键                | 必须为 MergeTree 表指定 `ORDER BY`（如 `ORDER BY product_id`） |
| DateTime 解析错误                         | 时间格式非标准                        | 使用 `'YYYY-MM-DD HH:MM:SS'` 格式         |

## 四、核心总结
1. 会话特性：所有库、表、数据仅在当前 clickhouse-local 会话有效，退出即销毁；
2. 引擎差异：`Memory` 引擎适合临时计算，`MergeTree` 引擎支持分区、改删，模拟服务端核心能力；
3. 语法核心：ClickHouse 主打 SELECT 聚合分析，UPDATE/DELETE 为辅助能力，需显式开启权限；
4. 持久化：如需留存数据，需通过 `INTO OUTFILE` 导出到本地文件，或切换到 ClickHouse 服务端。

本指南覆盖 ClickHouse-Local 全核心操作，可直接复制语句在交互界面执行，快速掌握 ClickHouse 语法逻辑与 OLAP 分析思维。