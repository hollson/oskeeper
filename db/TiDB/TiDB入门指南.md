# TiDB 数据库指南

[TOC]



## 🌟 一. TiDB 介绍

**[TiDB](https://github.com/pingcap/tidb)** 是一个开源的分布式 NewSQL 数据库，兼容 MySQL 协议，支持水平扩展、强一致性和高可用性。它结合了传统 RDBMS 的 ACID 特性和 NoSQL 的可扩展性。

**核心优势：**

- 🔄 **水平扩展**：计算层和存储层均可独立扩展，支持 PB 级数据处理
- 🔗 **MySQL 兼容**：完全兼容 MySQL 5.7/8.0 协议，迁移成本低
- 📊 **HTAP 架构**：同时支持 OLTP（在线事务处理）和 OLAP（在线分析处理）
- 🛡️ **强一致性**：基于 Raft 协议实现分布式事务和数据一致性
- ⚡️ **高可用性**：自动故障转移，无单点故障
- 🌐 **云原生**：支持 Kubernetes 部署，适合云环境



<br/>



## ⚙️ 二. 安装与配置

### 2.1 本地开发环境安装

**使用 Docker（推荐）**

```bash
# 拉取最新版本镜像
docker pull pingcap/tidb:v7.5.0

# 启动 TiDB Playground（包含 PD、TiKV、TiDB）
docker run --name tidb-server -p 4000:4000 -p 10080:10080 pingcap/tidb:v7.5.0

# 或者使用 docker-compose
wget https://raw.githubusercontent.com/pingcap/tidb-docker-compose/master/docker-compose.yml
docker-compose up -d
```

**使用 Homebrew（macOS）**

```bash
# 安装 TiUP（TiDB 官方包管理器）
brew install tispark/tispark/tiup

# 启动本地测试集群
tiup playground

# 启动指定版本
tiup playground v7.5.0
```

### 2.2 生产环境部署

**使用 TiUP 部署集群**

```bash
# 安装 TiUP
curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh

# 编辑拓扑配置文件
cat > topology.yaml << EOF
# 全局配置
global:
  user: "tidb"
  ssh_port: 22
  deploy_dir: "/tidb-deploy"
  data_dir: "/tidb-data"

# PD Server 配置
pd_servers:
  - host: 10.0.1.1
  - host: 10.0.1.2
  - host: 10.0.1.3

# TiDB Server 配置
tidb_servers:
  - host: 10.0.1.4
  - host: 10.0.1.5

# TiKV Server 配置
tikv_servers:
  - host: 10.0.1.6
  - host: 10.0.1.7
  - host: 10.0.1.8
EOF

# 部署集群
tiup cluster deploy my-cluster v7.5.0 ./topology.yaml --user root -p

# 启动集群
tiup cluster start my-cluster
```

### 2.3 连接测试

```bash
# 使用 MySQL 客户端连接
mysql -h 127.0.0.1 -P 4000 -u root -p

# 或者使用官方客户端
tiup client
```

### 2.4 数据库客户端

- 推荐使用 **DBeaver** 或 **Navicat**
- VSCode 插件：**MySQL**
- 命令行工具：**mycli**（增强版 MySQL 客户端）



<br/>



## 📙 三. 基础操作

### 3.1 数据库连接

```python
import pymysql

# 建立连接
connection = pymysql.connect(
    host='127.0.0.1',
    port=4000,
    user='root',
    password='',
    database='test',
    charset='utf8mb4'
)

cursor = connection.cursor()
```

### 3.2 基本操作

**创建数据库和表**

```sql
-- 创建数据库
CREATE DATABASE IF NOT EXISTS ecommerce;
USE ecommerce;

-- 创建用户表
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 创建订单表
CREATE TABLE orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'paid', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**插入数据**

```sql
-- 插入用户数据
INSERT INTO users (username, email, password_hash) VALUES 
('john_doe', 'john@example.com', 'hashed_password_1'),
('jane_smith', 'jane@example.com', 'hashed_password_2');

-- 插入订单数据
INSERT INTO orders (user_id, order_number, total_amount, status) VALUES 
(1, 'ORD001', 299.99, 'paid'),
(2, 'ORD002', 159.50, 'pending');
```

### 3.3 查询操作

**基础查询**

```sql
-- 简单查询
SELECT username, email FROM users WHERE id = 1;

-- 连接查询
SELECT u.username, o.order_number, o.total_amount, o.status
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status = 'paid'
ORDER BY o.created_at DESC;

-- 聚合查询
SELECT 
    u.username,
    COUNT(o.id) as order_count,
    SUM(o.total_amount) as total_spent
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.username
HAVING order_count > 0
ORDER BY total_spent DESC;
```

**分页查询**

```sql
-- 分页获取订单列表
SELECT * FROM orders 
ORDER BY created_at DESC 
LIMIT 10 OFFSET 20;

-- 获取总数
SELECT COUNT(*) as total_orders FROM orders;
```

### 3.4 事务操作

```python
try:
    # 开始事务
    connection.begin()
    
    # 创建新订单
    cursor.execute("""
        INSERT INTO orders (user_id, order_number, total_amount, status) 
        VALUES (%s, %s, %s, %s)
    """, (user_id, order_number, total_amount, 'pending'))
    
    # 更新库存
    cursor.execute("""
        UPDATE products 
        SET stock_quantity = stock_quantity - %s 
        WHERE id = %s AND stock_quantity >= %s
    """, (quantity, product_id, quantity))
    
    # 检查更新影响的行数
    if cursor.rowcount == 0:
        raise Exception("库存不足")
    
    # 提交事务
    connection.commit()
    print("订单创建成功！")
    
except Exception as e:
    # 回滚事务
    connection.rollback()
    print(f"事务失败，已回滚: {e}")
finally:
    cursor.close()
    connection.close()
```



<br/>



## 🚀 四. 高级特性

### 4.1 分布式事务

**乐观事务 vs 悲观事务**

```sql
-- 设置会话级别的事务模式

-- 乐观事务（默认）
SET SESSION tidb_txn_mode = 'optimistic';

-- 悲观事务
SET SESSION tidb_txn_mode = 'pessimistic';

-- 示例：悲观事务处理高并发场景
START TRANSACTION;
SELECT * FROM accounts WHERE id = 1 FOR UPDATE;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
COMMIT;
```

**大事务优化**

```python
# 批量处理大量数据
def batch_process_large_data(connection, data_list, batch_size=1000):
    cursor = connection.cursor()
    
    try:
        connection.begin()
        
        for i in range(0, len(data_list), batch_size):
            batch = data_list[i:i + batch_size]
            
            # 批量插入
            sql = """
                INSERT INTO large_table (col1, col2, col3) 
                VALUES (%s, %s, %s)
            """
            cursor.executemany(sql, batch)
            
            # 定期提交避免事务过大
            if i % (batch_size * 10) == 0:
                connection.commit()
                connection.begin()
        
        connection.commit()
        
    except Exception as e:
        connection.rollback()
        raise e
    finally:
        cursor.close()
```

### 4.2 HTAP 混合负载

**实时分析查询**

```sql
-- 在线事务处理（OLTP）
INSERT INTO user_behavior (user_id, action, timestamp) VALUES (123, 'click', NOW());
UPDATE user_profiles SET last_active = NOW() WHERE user_id = 123;

-- 实时分析处理（OLAP）
SELECT 
    DATE(timestamp) as date,
    action,
    COUNT(*) as count,
    COUNT(DISTINCT user_id) as unique_users
FROM user_behavior 
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(timestamp), action
ORDER BY date DESC, count DESC;
```

**TiFlash 列式存储加速分析**

```sql
-- 为表启用 TiFlash 副本
ALTER TABLE orders SET TIFLASH REPLICA 1;

-- 强制使用 TiFlash 进行分析查询
SELECT /*+ READ_FROM_STORAGE(TIFLASH[orders]) */ 
    user_id,
    COUNT(*) as order_count,
    AVG(total_amount) as avg_order_value
FROM orders 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY user_id
ORDER BY order_count DESC
LIMIT 100;
```

### 4.3 分区表

```sql
-- 按时间范围分区
CREATE TABLE sales_data (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    amount DECIMAL(10,2),
    sale_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (YEAR(sale_date)) (
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- 按哈希分区分散热点
CREATE TABLE user_sessions (
    session_id VARCHAR(64) PRIMARY KEY,
    user_id BIGINT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP
) PARTITION BY HASH(user_id) PARTITIONS 16;

-- 查询特定分区
SELECT * FROM sales_data PARTITION (p2023) WHERE amount > 1000;
```

### 4.4 索引优化

```sql
-- 创建复合索引
CREATE INDEX idx_user_status_created 
ON orders (user_id, status, created_at);

-- 创建前缀索引（节省空间）
CREATE INDEX idx_email_prefix ON users (email(20));

-- 查看索引使用情况
EXPLAIN SELECT * FROM orders WHERE user_id = 123 AND status = 'paid';

-- 删除未使用的索引
DROP INDEX idx_unused ON orders;
```



<br/>



## 🛠️ 五. 应用案例

### 5.1 电商平台数据处理

**项目结构**

```shell
e-commerce-platform/
├── database/
│   ├── init.sql              # 数据库初始化脚本
│   ├── migrations/           # 数据库迁移文件
│   │   ├── 001_create_tables.sql
│   │   └── 002_add_indexes.sql
├── src/
│   ├── models/
│   │   ├── user.py
│   │   ├── order.py
│   │   └── product.py
│   ├── services/
│   │   ├── order_service.py
│   │   └── analytics_service.py
│   └── utils/
│       └── db_connection.py
└── config/
    └── database.yaml
```

**核心服务实现**

```python
# db_connection.py
import pymysql
from contextlib import contextmanager

class DatabaseManager:
    def __init__(self, config):
        self.config = config
    
    @contextmanager
    def get_connection(self):
        connection = pymysql.connect(**self.config)
        try:
            yield connection
        finally:
            connection.close()

# order_service.py
class OrderService:
    def __init__(self, db_manager):
        self.db = db_manager
    
    def create_order(self, user_id, items):
        with self.db.get_connection() as conn:
            try:
                conn.begin()
                
                # 计算总金额
                total_amount = sum(item['price'] * item['quantity'] for item in items)
                
                # 创建订单
                with conn.cursor() as cursor:
                    cursor.execute("""
                        INSERT INTO orders (user_id, total_amount, status) 
                        VALUES (%s, %s, 'pending')
                    """, (user_id, total_amount))
                    
                    order_id = cursor.lastrowid
                    
                    # 创建订单项
                    for item in items:
                        cursor.execute("""
                            INSERT INTO order_items (order_id, product_id, quantity, price)
                            VALUES (%s, %s, %s, %s)
                        """, (order_id, item['product_id'], item['quantity'], item['price']))
                
                conn.commit()
                return order_id
                
            except Exception as e:
                conn.rollback()
                raise e
```

### 5.2 实时数据分析

```python
# analytics_service.py
class AnalyticsService:
    def __init__(self, db_manager):
        self.db = db_manager
    
    def get_sales_report(self, start_date, end_date):
        """获取销售报表"""
        query = """
            SELECT 
                DATE(created_at) as date,
                COUNT(*) as order_count,
                SUM(total_amount) as daily_revenue,
                AVG(total_amount) as avg_order_value
            FROM orders 
            WHERE created_at BETWEEN %s AND %s
                AND status IN ('paid', 'delivered')
            GROUP BY DATE(created_at)
            ORDER BY date
        """
        
        with self.db.get_connection() as conn:
            with conn.cursor(pymysql.cursors.DictCursor) as cursor:
                cursor.execute(query, (start_date, end_date))
                return cursor.fetchall()
    
    def get_top_products(self, limit=10):
        """获取热销商品"""
        query = """
            SELECT 
                p.name,
                p.category,
                SUM(oi.quantity) as total_sold,
                SUM(oi.quantity * oi.price) as revenue
            FROM order_items oi
            JOIN products p ON oi.product_id = p.id
            JOIN orders o ON oi.order_id = o.id
            WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                AND o.status IN ('paid', 'delivered')
            GROUP BY p.id, p.name, p.category
            ORDER BY total_sold DESC
            LIMIT %s
        """
        
        with self.db.get_connection() as conn:
            with conn.cursor(pymysql.cursors.DictCursor) as cursor:
                cursor.execute(query, (limit,))
                return cursor.fetchall()
```

### 5.3 监控与运维

```python
# monitoring.py
class TiDBMonitor:
    def __init__(self, db_config):
        self.db_config = db_config
    
    def get_cluster_status(self):
        """获取集群状态信息"""
        queries = {
            'pd_members': "SHOW PD REGIONS",
            'tikv_stores': "SHOW STORES",
            'tidb_servers': "SHOW SERVERS",
            'schema_info': "SELECT table_schema, table_name, table_rows FROM information_schema.tables WHERE table_schema NOT IN ('INFORMATION_SCHEMA', 'PERFORMANCE_SCHEMA', 'mysql')"
        }
        
        results = {}
        with pymysql.connect(**self.db_config) as conn:
            with conn.cursor(pymysql.cursors.DictCursor) as cursor:
                for name, query in queries.items():
                    try:
                        cursor.execute(query)
                        results[name] = cursor.fetchall()
                    except Exception as e:
                        results[name] = f"Error: {str(e)}"
        
        return results
    
    def get_performance_metrics(self):
        """获取性能指标"""
        query = """
            SELECT 
                VARIABLE_NAME,
                VARIABLE_VALUE
            FROM performance_schema.global_status 
            WHERE VARIABLE_NAME IN (
                'Threads_connected',
                'Threads_running',
                'Queries',
                'Slow_queries',
                'Created_tmp_disk_tables',
                'Handler_read_rnd_next'
            )
        """
        
        with pymysql.connect(**self.db_config) as conn:
            with conn.cursor(pymysql.cursors.DictCursor) as cursor:
                cursor.execute(query)
                return dict((row['VARIABLE_NAME'], row['VARIABLE_VALUE']) for row in cursor.fetchall())
```



<br/>



## 🏆 六. 性能优化

### 6.1 读写优化

**查询优化策略**

```sql
-- 使用覆盖索引避免回表
SELECT user_id, status, created_at 
FROM orders 
WHERE user_id = 123 AND status = 'paid';

-- 避免 SELECT *
SELECT id, username, email FROM users WHERE active = 1;

-- 合理使用 LIMIT
SELECT * FROM orders ORDER BY created_at DESC LIMIT 100;

-- 使用 EXISTS 替代 IN（子查询）
SELECT * FROM users u 
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.status = 'paid');
```

**批量操作优化**

```python
# 批量插入优化
def batch_insert_optimized(cursor, table, columns, data, batch_size=1000):
    placeholders = ','.join(['%s'] * len(columns))
    columns_str = ','.join(columns)
    
    sql = f"INSERT INTO {table} ({columns_str}) VALUES ({placeholders})"
    
    for i in range(0, len(data), batch_size):
        batch = data[i:i + batch_size]
        cursor.executemany(sql, batch)

# 批量更新优化
def batch_update_optimized(cursor, table, updates, conditions, batch_size=100):
    for i in range(0, len(updates), batch_size):
        batch_updates = updates[i:i + batch_size]
        batch_conditions = conditions[i:i + batch_size]
        
        # 构建批量更新语句
        case_statements = []
        where_values = []
        
        for update_dict, condition_dict in zip(batch_updates, batch_conditions):
            for column, value in update_dict.items():
                case_statements.append(f"{column} = CASE id ")
                # 添加具体的 CASE 条件
                # 这里简化处理，实际应用中需要更复杂的逻辑
```

### 6.2 存储优化

**表结构设计**

```sql
-- 选择合适的数据类型
CREATE TABLE optimized_table (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    small_enum TINYINT UNSIGNED,  -- 替代 ENUM
    flag BOOLEAN,                 -- 替代 TINYINT(1)
    score DECIMAL(5,2),           -- 精确的小数
    description VARCHAR(255),     -- 避免 TEXT（如果长度可控）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created_flag (created_at, flag)
) ENGINE=InnoDB;

-- 归档历史数据
CREATE TABLE orders_archive LIKE orders;

INSERT INTO orders_archive 
SELECT * FROM orders 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);

DELETE FROM orders 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);
```

### 6.3 分布式优化

**Region 分裂控制**

```sql
-- 查看表的 Region 分布
SHOW TABLE orders REGIONS;

-- 手动分裂 Region（解决热点问题）
SPLIT TABLE orders BETWEEN (1) AND (1000000) REGIONS 16;

-- 设置合适的 Region 大小
SET CONFIG tikv raftstore.region-split-size = '96MB';
```

**负载均衡**

```bash
# 使用 pd-ctl 查看和调整调度
./pd-ctl -u http://pd_addr:2379

# 查看 store 状态
>> store

# 平衡 leader
>> scheduler add balance-leader-scheduler

# 平衡 region
>> scheduler add balance-region-scheduler
```

### 6.4 监控告警

```yaml
# Prometheus 监控配置示例
- job_name: 'tidb-cluster'
  static_configs:
  - targets: ['tidb-0:10080', 'tidb-1:10080']
  - targets: ['tikv-0:20180', 'tikv-1:20180', 'tikv-2:20180']
  - targets: ['pd-0:2379', 'pd-1:2379', 'pd-2:2379']

# 关键监控指标
metrics:
  - name: tidb_server_connections
    description: 当前连接数
    alert_threshold: 80% of max_connections
  
  - name: tikv_grpc_msg_duration_seconds
    description: gRPC 请求延迟
    alert_threshold: > 1s
  
  - name: pd_scheduler_region_heartbeat
    description: Region 心跳间隔
    alert_threshold: > 10s
```



<br/>



## 🎓 七. 场景与限制

### 7.1 适合场景

- **大规模在线服务**：需要水平扩展的 Web 应用、移动应用后端
- **混合负载应用**：同时需要 OLTP 和 OLAP 能力的业务系统
- **金融级应用**：需要强一致性和高可用性的交易系统
- **多租户 SaaS**：需要隔离和扩展能力的软件即服务
- **实时分析**：需要实时处理和分析大量数据的场景
- **全球化部署**：跨地域、多数据中心的应用

### 7.2 不适合场景

- **简单单机应用**：小型项目或原型开发，MySQL 更简单
- **超低延迟要求**：对微秒级延迟有极致要求的高频交易
- **完全无状态应用**：不需要持久化存储的纯计算服务
- **预算极度受限**：需要最小化硬件成本的场景

### 7.3 与同类产品对比

| 特性 | TiDB | CockroachDB | Vitess |
|------|------|-------------|--------|
| MySQL 兼容性 | ✅ 完全兼容 | ✅ 高度兼容 | ✅ 完全兼容 |
| 分布式事务 | ✅ 强一致性 | ✅ 强一致性 | ❌ 最终一致性 |
| HTAP 能力 | ✅ 原生支持 | ❌ 需要外部系统 | ❌ OLTP 为主 |
| 部署复杂度 | ⭐⭐⭐ 中等 | ⭐⭐⭐⭐ 较高 | ⭐⭐ 简单 |
| 社区活跃度 | ✅ 非常活跃 | ✅ 活跃 | ⭐⭐ 一般 |
| 商业支持 | ✅ 官方提供 | ✅ 官方提供 | ⭐ 有限 |



<br/>



## 📚 八. 扩展建议

### 8.1 生态工具

**数据迁移工具**

```bash
# 使用 Dumpling 导出数据
tiup dumpling -h 127.0.0.1 -P 4000 -u root -t 32 -F 256MB -o /tmp/export

# 使用 Lightning 导入数据
tiup tidb-lightning -config lightning.toml

# 实时同步 MySQL 到 TiDB
tiup dm-master &
tiup dm-worker &
tiup dmctl start-task ./task.yaml
```

**备份恢复**

```bash
# 创建备份
tiup br backup full -s "local:///tmp/backup" --pd "pd-addr:2379"

# 恢复数据
tiup br restore full -s "local:///tmp/backup" --pd "pd-addr:2379"

# 增量备份
tiup br backup incremental -s "local:///tmp/incr_backup" --pd "pd-addr:2379"
```

### 8.2 最佳实践

**开发规范**

```sql
-- 1. 统一命名规范
-- 表名：小写 + 下划线，如 user_profiles
-- 字段名：小写 + 下划线，如 created_at
-- 索引名：idx_表名_字段名，如 idx_users_email

-- 2. 合理设置字符集
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    username VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 使用合适的约束
ALTER TABLE orders ADD CONSTRAINT chk_amount CHECK (total_amount >= 0);
```

**运维建议**

1. **定期维护**：
   - 监控集群健康状态
   - 定期清理历史数据
   - 优化慢查询

2. **容量规划**：
   - 根据业务增长预测扩容时机
   - 预留足够的资源余量
   - 制定应急预案

3. **安全配置**：
   - 启用 TLS 加密传输
   - 配置防火墙规则
   - 定期更新密码策略

### 8.3 学习资源

- 📖 官方文档：https://docs.pingcap.com/zh/tidb/stable
- 🎥 在线课程：PingCAP Academy
- 🏫 社区论坛：AskTUG
- 🐙 GitHub：https://github.com/pingcap/tidb
- 📱 微信公众号：PingCAP

---

> 💡 **提示**：TiDB 是一个强大的分布式数据库，特别适合需要水平扩展和强一致性的应用场景。建议从小规模开始尝试，逐步熟悉其特性和最佳实践。