# OceanBase 数据库指南

[TOC]



## 🌊 一. OceanBase 介绍

**[OceanBase](https://www.oceanbase.com/)** 是蚂蚁集团自主研发的金融级分布式关系型数据库，具备高可用、水平扩展、强一致性等特点，在支付宝等核心金融场景中得到大规模验证。

**核心优势：**

- 🏦 **金融级可靠性**：支持两地三中心部署，RPO=0，RTO<30秒
- 📈 **弹性扩展**：支持在线扩容缩容，计算存储分离架构
- 🔗 **MySQL/Oracle 兼容**：双模式支持，降低迁移成本
- ⚡️ **高性能**：单集群可支撑千万级并发，TPC-C性能世界纪录
- 🛡️ **多租户隔离**：资源隔离，支持混合部署
- ☁️ **云原生设计**：原生支持容器化部署和Kubernetes编排



<br/>



## ⚙️ 二. 安装与配置

### 2.1 本地开发环境

**使用 Docker（快速体验）**

```bash
# 拉取 OceanBase CE 镜像
docker pull oceanbase/oceanbase-ce:latest

# 启动单机版 OceanBase
docker run -d \
  --name oceanbase-ce \
  -p 2881:2881 \
  -p 2882:2882 \
  -e MODE=slim \
  -e OB_SYS_PASSWORD=OceanBase123 \
  oceanbase/oceanbase-ce:latest

# 等待启动完成（约2-3分钟）
sleep 180

docker logs oceanbase-ce | grep "boot success"

# 连接测试
docker exec -it oceanbase-ce obclient -h127.1 -uroot -pOceanBase123 -Doceanbase
```

**使用 OBD（OceanBase Deployer）**

```bash
# 安装 OBD
curl -fsSL https://obbusiness-private.oss-cn-shanghai.aliyuncs.com/download-center/opensource/oceanbase-developer-center/obd-installer.sh | bash

# 配置集群
obd cluster edit-config test

# 部署集群
obd cluster deploy test -c mini-local.yaml -f

# 启动集群
obd cluster start test

# 连接数据库
obclient -h127.0.0.1 -P2881 -uroot -Doceanbase
```

### 2.2 生产环境部署

**Kubernetes 部署（推荐）**

```yaml
# oceanbase-cluster.yaml
apiVersion: core.oceanbase.com/v1alpha1
kind: OceanBaseCluster
metadata:
  name: obcluster
spec:
  clusterName: obcluster
  observer:
    image: oceanbase/oceanbase-cloud-native:latest
    replicas: 3
    resources:
      limits:
        cpu: "8"
        memory: 32Gi
      requests:
        cpu: "4"
        memory: 16Gi
    storage:
      dataStorage:
        storageClass: local-path
        size: 500Gi
      logStorage:
        storageClass: local-path
        size: 100Gi
      redoLogStorage:
        storageClass: local-path
        size: 100Gi
  parameters:
    - name: max_cpu
      value: "8"
    - name: memory_limit
      value: "30G"
    - name: syslog_level
      value: "INFO"
```

```bash
# 部署 OceanBase 集群
kubectl apply -f oceanbase-cluster.yaml

# 查看集群状态
kubectl get obclusters.core.oceanbase.com

# 查看 Pod 状态
kubectl get pods -l app=oceanbase
```

### 2.3 连接配置

```python
import pymysql

# MySQL 模式连接
mysql_config = {
    'host': '127.0.0.1',
    'port': 2881,
    'user': 'root',
    'password': 'OceanBase123',
    'database': 'test',
    'charset': 'utf8mb4',
    'autocommit': True,
    'connect_timeout': 10,
    'read_timeout': 30
}

# Oracle 模式连接（需要 cx_Oracle）
oracle_config = {
    'dsn': '127.0.0.1:2883/ORCL',
    'user': 'SYS',
    'password': 'OceanBase123'
}

# 连接池配置
class OceanBaseManager:
    def __init__(self, config, pool_size=10):
        self.config = config
        self.pool = Queue(maxsize=pool_size)
        
        # 初始化连接池
        for _ in range(pool_size):
            conn = self._create_connection()
            self.pool.put(conn)
    
    def _create_connection(self):
        return pymysql.connect(**self.config)
    
    @contextmanager
    def get_connection(self):
        conn = self.pool.get(timeout=5)
        try:
            yield conn
        finally:
            if conn.open:
                self.pool.put(conn)
            else:
                # 重建连接
                new_conn = self._create_connection()
                self.pool.put(new_conn)
```

### 2.4 客户端工具

- **OBClient**：官方命令行客户端
- **OCP (OceanBase Cloud Platform)**：图形化管理平台
- **DBeaver**：通用数据库管理工具
- **Navicat**：商业数据库管理工具



<br/>



## 📙 三. 基础操作

### 3.1 数据库连接

```python
import pymysql
from contextlib import contextmanager

@contextmanager
def get_ob_connection(config):
    connection = pymysql.connect(**config)
    try:
        yield connection
    finally:
        connection.close()

# 基本使用示例
config = {
    'host': '127.0.0.1',
    'port': 2881,
    'user': 'root',
    'password': 'OceanBase123',
    'database': 'ecommerce',
    'charset': 'utf8mb4'
}

with get_ob_connection(config) as conn:
    with conn.cursor() as cursor:
        # 查询版本信息
        cursor.execute("SELECT VERSION(), tenant_name FROM oceanbase.DBA_OB_TENANTS LIMIT 1")
        result = cursor.fetchone()
        print(f"OceanBase Version: {result[0]}, Tenant: {result[1]}")
```

### 3.2 租户和用户管理

```sql
-- 创建资源单元
CREATE RESOURCE UNIT small_unit 
MAX_CPU 2, 
MAX_MEMORY '4G', 
MAX_IOPS 10000, 
MAX_DISK_SIZE '100G';

-- 创建资源池
CREATE RESOURCE POOL small_pool 
UNIT = 'small_unit', 
UNIT_NUM = 1, 
ZONE_LIST = ('zone1');

-- 创建租户
CREATE TENANT ecommerce_tenant 
PRIMARY_ZONE = 'zone1', 
RESOURCE_POOL_LIST = ('small_pool') 
SET VARIABLES ob_tcp_invited_nodes = '%', 
ob_compatibility_mode = 'mysql';

-- 创建用户并授权
CREATE USER 'app_user'@'%' IDENTIFIED BY 'AppPass123';
GRANT ALL PRIVILEGES ON ecommerce_tenant.* TO 'app_user'@'%';

-- 修改租户配置
ALTER TENANT ecommerce_tenant 
SET VARIABLES max_user_connections = 1000;
```

### 3.3 表结构设计

```sql
-- 创建电商核心表

-- 用户表
CREATE TABLE users (
    user_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户ID',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    email VARCHAR(100) NOT NULL UNIQUE COMMENT '邮箱',
    mobile VARCHAR(20) COMMENT '手机号',
    password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希',
    status TINYINT DEFAULT 1 COMMENT '状态：1正常 0禁用',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_mobile (mobile)
) COMPRESSION='zstd_1.3.8';

-- 商品表
CREATE TABLE products (
    product_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '商品ID',
    name VARCHAR(200) NOT NULL COMMENT '商品名称',
    category_id INT NOT NULL COMMENT '分类ID',
    brand VARCHAR(100) COMMENT '品牌',
    price DECIMAL(10,2) NOT NULL COMMENT '价格',
    stock_quantity INT DEFAULT 0 COMMENT '库存数量',
    description LONGTEXT COMMENT '商品描述',
    status TINYINT DEFAULT 1 COMMENT '状态：1上架 0下架',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category_brand (category_id, brand),
    INDEX idx_price_status (price, status),
    INDEX idx_created_at (created_at)
) COMPRESSION='zstd_1.3.8';

-- 订单表（分区表）
CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '订单ID',
    order_no VARCHAR(32) NOT NULL UNIQUE COMMENT '订单号',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    total_amount DECIMAL(12,2) NOT NULL COMMENT '订单总额',
    discount_amount DECIMAL(12,2) DEFAULT 0.00 COMMENT '优惠金额',
    payable_amount DECIMAL(12,2) NOT NULL COMMENT '应付金额',
    status VARCHAR(20) DEFAULT 'pending' COMMENT '订单状态',
    payment_method VARCHAR(20) COMMENT '支付方式',
    paid_at TIMESTAMP NULL COMMENT '支付时间',
    shipped_at TIMESTAMP NULL COMMENT '发货时间',
    delivered_at TIMESTAMP NULL COMMENT '收货时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_user_created (user_id, created_at),
    INDEX idx_order_no (order_no),
    INDEX idx_status_paid (status, paid_at)
) COMPRESSION='zstd_1.3.8'
PARTITION BY RANGE COLUMNS(created_at) (
    PARTITION p2023_q1 VALUES LESS THAN ('2023-04-01'),
    PARTITION p2023_q2 VALUES LESS THAN ('2023-07-01'),
    PARTITION p2023_q3 VALUES LESS THAN ('2023-10-01'),
    PARTITION p2023_q4 VALUES LESS THAN ('2024-01-01'),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

### 3.4 数据操作

**插入数据**

```sql
-- 批量插入用户数据
INSERT INTO users (username, email, mobile, password_hash) VALUES 
('alice_wang', 'alice@example.com', '13800138001', 'hash_alice'),
('bob_li', 'bob@example.com', '13800138002', 'hash_bob'),
('charlie_zhang', 'charlie@example.com', '13800138003', 'hash_charlie');

-- 批量插入商品数据
INSERT INTO products (name, category_id, brand, price, stock_quantity, description) VALUES 
('iPhone 15', 1, 'Apple', 5999.00, 100, '苹果最新款手机'),
('MacBook Pro', 2, 'Apple', 12999.00, 50, '专业级笔记本电脑'),
('iPad Air', 3, 'Apple', 4399.00, 80, '轻薄平板电脑');
```

**查询操作**

```sql
-- 基础查询
SELECT user_id, username, email FROM users WHERE status = 1;

-- 连接查询
SELECT 
    o.order_no,
    u.username,
    o.total_amount,
    o.status,
    o.created_at
FROM orders o
JOIN users u ON o.user_id = u.user_id
WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
ORDER BY o.created_at DESC;

-- 聚合查询
SELECT 
    p.brand,
    COUNT(*) as product_count,
    AVG(p.price) as avg_price,
    SUM(p.stock_quantity * p.price) as inventory_value
FROM products p
WHERE p.status = 1
GROUP BY p.brand
HAVING product_count > 2
ORDER BY inventory_value DESC;
```

### 3.5 事务处理

```python
import pymysql
from datetime import datetime

class OceanBaseOrderService:
    def __init__(self, db_config):
        self.db_config = db_config
    
    def create_order(self, user_id, items):
        """创建订单 - 分布式事务处理"""
        connection = pymysql.connect(**self.db_config)
        try:
            # 开启事务
            connection.begin()
            
            with connection.cursor() as cursor:
                # 生成全局唯一订单号
                order_no = f"OB{datetime.now().strftime('%Y%m%d%H%M%S')}{user_id:08d}"
                
                # 计算订单金额
                total_amount = sum(item['price'] * item['quantity'] for item in items)
                
                # 创建订单记录
                cursor.execute("""
                    INSERT INTO orders 
                    (order_no, user_id, total_amount, payable_amount, status) 
                    VALUES (%s, %s, %s, %s, %s)
                """, (order_no, user_id, total_amount, total_amount, 'pending'))
                
                order_id = cursor.lastrowid
                
                # 创建订单明细并扣减库存
                for item in items:
                    # 插入订单明细
                    cursor.execute("""
                        INSERT INTO order_items 
                        (order_id, product_id, quantity, unit_price, subtotal)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (order_id, item['product_id'], item['quantity'], 
                          item['price'], item['price'] * item['quantity']))
                    
                    # 扣减商品库存（使用悲观锁）
                    cursor.execute("""
                        UPDATE products 
                        SET stock_quantity = stock_quantity - %s 
                        WHERE product_id = %s 
                        AND stock_quantity >= %s
                    """, (item['quantity'], item['product_id'], item['quantity']))
                    
                    # 检查库存扣减是否成功
                    if cursor.rowcount == 0:
                        raise Exception(f"商品 {item['product_id']} 库存不足")
                
                # 记录操作日志
                cursor.execute("""
                    INSERT INTO operation_logs 
                    (operation_type, target_id, operator_id, details)
                    VALUES (%s, %s, %s, %s)
                """, ('CREATE_ORDER', order_id, user_id, f"创建订单 {order_no}"))
            
            # 提交事务
            connection.commit()
            print(f"✅ 订单创建成功，订单号: {order_no}")
            return order_no
            
        except Exception as e:
            # 回滚事务
            connection.rollback()
            print(f"❌ 订单创建失败: {str(e)}")
            raise e
        finally:
            connection.close()
```



<br/>



## 🚀 四. 高级特性

### 4.1 多租户架构

```sql
-- 租户管理操作

-- 查看所有租户
SELECT tenant_name, tenant_id, status FROM oceanbase.DBA_OB_TENANTS;

-- 创建新的资源单元配置
CREATE RESOURCE UNIT medium_unit 
MAX_CPU 4, 
MAX_MEMORY '8G', 
MAX_IOPS 20000, 
MAX_DISK_SIZE '200G',
MIN_CPU 2,
MIN_MEMORY '4G';

-- 创建资源池
CREATE RESOURCE POOL medium_pool 
UNIT = 'medium_unit', 
UNIT_NUM = 2, 
ZONE_LIST = ('zone1','zone2');

-- 创建多租户
CREATE TENANT finance_tenant 
PRIMARY_ZONE = 'RANDOM', 
RESOURCE_POOL_LIST = ('medium_pool') 
SET VARIABLES ob_compatibility_mode = 'mysql';

CREATE TENANT analytics_tenant 
PRIMARY_ZONE = 'RANDOM', 
RESOURCE_POOL_LIST = ('medium_pool') 
SET VARIABLES ob_compatibility_mode = 'mysql';

-- 租户间资源调配
ALTER RESOURCE POOL medium_pool 
UNIT_NUM = 3;

-- 租户参数调优
ALTER TENANT finance_tenant 
SET VARIABLES max_user_connections = 2000,
              ob_sql_work_area_percentage = 40;
```

### 4.2 分区表管理

```sql
-- 创建不同类型的分区表

-- Range 分区（按时间）
CREATE TABLE sales_data (
    sale_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    amount DECIMAL(12,2),
    sale_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (TO_DAYS(sale_date)) (
    PARTITION p2023_q1 VALUES LESS THAN (TO_DAYS('2023-04-01')),
    PARTITION p2023_q2 VALUES LESS THAN (TO_DAYS('2023-07-01')),
    PARTITION p2023_q3 VALUES LESS THAN (TO_DAYS('2023-10-01')),
    PARTITION p2023_q4 VALUES LESS THAN (TO_DAYS('2024-01-01')),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Hash 分区（分散热点）
CREATE TABLE user_sessions (
    session_id VARCHAR(64) PRIMARY KEY,
    user_id BIGINT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_time (user_id, created_at)
) PARTITION BY HASH(user_id) PARTITIONS 16;

-- List 分区（按地域）
CREATE TABLE regional_customers (
    customer_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    region_code VARCHAR(10),
    city VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY LIST COLUMNS(region_code) (
    PARTITION p_north VALUES IN ('BJ', 'TJ', 'HE'),
    PARTITION p_south VALUES IN ('SH', 'JS', 'ZJ'),
    PARTITION p_east VALUES IN ('SD', 'AH', 'FJ'),
    PARTITION p_west VALUES IN ('SC', 'YN', 'XZ')
);

-- 分区维护操作
-- 添加新分区
ALTER TABLE sales_data 
ADD PARTITION (PARTITION p2024_q1 VALUES LESS THAN (TO_DAYS('2024-04-01')));

-- 删除旧分区（注意：会删除数据）
ALTER TABLE sales_data DROP PARTITION p2023_q1;

-- 合并分区
ALTER TABLE sales_data 
REORGANIZE PARTITION p2023_q2, p2023_q3 INTO (
    PARTITION p2023_h1 VALUES LESS THAN (TO_DAYS('2023-07-01'))
);
```

### 4.3 分布式事务

```sql
-- OceanBase 分布式事务示例

-- Session 1: 开始分布式事务
SET SESSION ob_trx_idle_timeout = 600000000;
START TRANSACTION;

-- 扣减账户余额
UPDATE accounts SET balance = balance - 1000 WHERE user_id = 123;

-- 检查余额是否足够
SELECT balance FROM accounts WHERE user_id = 123;

-- 如果余额不足，回滚
-- ROLLBACK;

-- 如果余额充足，继续执行
UPDATE merchant_accounts SET balance = balance + 1000 WHERE merchant_id = 456;

-- 提交事务
COMMIT;

-- 查看事务信息
SELECT * FROM oceanbase.GV$OB_TRANSACTION_PARTICIPANTS 
WHERE tx_id = CONNECTION_ID();
```

### 4.4 性能优化

```sql
-- 索引优化

-- 创建复合索引
CREATE INDEX idx_orders_user_status_date 
ON orders (user_id, status, created_at);

-- 创建函数索引（MySQL模式）
CREATE INDEX idx_orders_date_part 
ON orders ((DATE(created_at)));

-- 创建全文索引（适用于搜索场景）
CREATE FULLTEXT INDEX idx_products_description 
ON products(description);

-- 查询优化示例

-- 优化前：可能导致全表扫描
SELECT * FROM orders WHERE YEAR(created_at) = 2023;

-- 优化后：使用索引
SELECT * FROM orders 
WHERE created_at >= '2023-01-01' AND created_at < '2024-01-01';

-- 使用执行计划分析
EXPLAIN FORMAT=JSON 
SELECT u.username, COUNT(o.order_id) as order_count
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.status = 1 AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.user_id, u.username
HAVING order_count > 5
ORDER BY order_count DESC;

-- 统计信息更新
ANALYZE TABLE orders;
ANALYZE TABLE users;

-- 查看表统计信息
SELECT 
    table_name,
    table_rows,
    avg_row_length,
    data_length,
    index_length
FROM information_schema.tables 
WHERE table_schema = 'ecommerce';
```



<br/>



## 🛠️ 五. 应用案例

### 5.1 金融支付系统

```python
# 金融支付核心服务
class PaymentService:
    def __init__(self, db_manager):
        self.db = db_manager
        
    def process_payment(self, user_id, order_id, amount, payment_method):
        """处理支付 - 金融级事务要求"""
        with self.db.get_connection() as conn:
            try:
                conn.begin()
                
                with conn.cursor() as cursor:
                    # 1. 验证订单状态
                    cursor.execute("""
                        SELECT status, payable_amount 
                        FROM orders 
                        WHERE order_id = %s AND user_id = %s FOR UPDATE
                    """, (order_id, user_id))
                    
                    order = cursor.fetchone()
                    if not order:
                        raise Exception("订单不存在")
                    
                    if order[0] != 'pending':
                        raise Exception("订单状态不正确")
                    
                    if order[1] != amount:
                        raise Exception("支付金额与订单金额不符")
                    
                    # 2. 检查用户账户余额
                    cursor.execute("""
                        SELECT balance FROM user_accounts 
                        WHERE user_id = %s FOR UPDATE
                    """, (user_id,))
                    
                    account = cursor.fetchone()
                    if not account or account[0] < amount:
                        raise Exception("账户余额不足")
                    
                    # 3. 扣减用户账户
                    cursor.execute("""
                        UPDATE user_accounts 
                        SET balance = balance - %s,
                            frozen_amount = frozen_amount + %s,
                            updated_at = NOW()
                        WHERE user_id = %s
                    """, (amount, amount, user_id))
                    
                    # 4. 创建支付记录
                    cursor.execute("""
                        INSERT INTO payments 
                        (order_id, user_id, amount, payment_method, status)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (order_id, user_id, amount, payment_method, 'processing'))
                    
                    payment_id = cursor.lastrowid
                    
                    # 5. 更新订单状态
                    cursor.execute("""
                        UPDATE orders 
                        SET status = 'paid',
                            paid_at = NOW(),
                            payment_method = %s
                        WHERE order_id = %s
                    """, (payment_method, order_id))
                    
                    # 6. 记录资金流水
                    cursor.execute("""
                        INSERT INTO fund_flows 
                        (user_id, amount, flow_type, business_type, business_id, remark)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (user_id, -amount, 'out', 'payment', payment_id, f"订单支付-{order_id}"))
                
                conn.commit()
                return {
                    'success': True,
                    'payment_id': payment_id,
                    'message': '支付成功'
                }
                
            except Exception as e:
                conn.rollback()
                self.log_payment_error(user_id, order_id, amount, str(e))
                raise e
    
    def refund_payment(self, payment_id, reason):
        """退款处理"""
        with self.db.get_connection() as conn:
            try:
                conn.begin()
                
                with conn.cursor() as cursor:
                    # 查询支付记录
                    cursor.execute("""
                        SELECT order_id, user_id, amount, status 
                        FROM payments 
                        WHERE payment_id = %s FOR UPDATE
                    """, (payment_id,))
                    
                    payment = cursor.fetchone()
                    if not payment:
                        raise Exception("支付记录不存在")
                    
                    if payment[3] != 'completed':
                        raise Exception("支付状态不允许退款")
                    
                    # 更新支付状态
                    cursor.execute("""
                        UPDATE payments 
                        SET status = 'refunded',
                            refund_reason = %s,
                            refunded_at = NOW()
                        WHERE payment_id = %s
                    """, (reason, payment_id))
                    
                    # 解冻并退还用户资金
                    cursor.execute("""
                        UPDATE user_accounts 
                        SET balance = balance + %s,
                            frozen_amount = frozen_amount - %s
                        WHERE user_id = %s
                    """, (payment[2], payment[2], payment[1]))
                    
                    # 记录退款流水
                    cursor.execute("""
                        INSERT INTO fund_flows 
                        (user_id, amount, flow_type, business_type, business_id, remark)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (payment[1], payment[2], 'in', 'refund', payment_id, reason))
                
                conn.commit()
                return True
                
            except Exception as e:
                conn.rollback()
                raise e
```

### 5.2 电商平台库存系统

```sql
-- 库存相关表结构
CREATE TABLE inventory (
    product_id BIGINT PRIMARY KEY,
    available_stock INT NOT NULL DEFAULT 0 COMMENT '可用库存',
    reserved_stock INT NOT NULL DEFAULT 0 COMMENT '预留库存',
    sold_stock INT NOT NULL DEFAULT 0 COMMENT '已售库存',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_available_stock (available_stock),
    INDEX idx_product_update (product_id, last_updated)
) COMPRESSION='zstd_1.3.8';

CREATE TABLE inventory_logs (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    product_id BIGINT NOT NULL,
    operation_type VARCHAR(20) NOT NULL COMMENT '操作类型',
    change_quantity INT NOT NULL COMMENT '变更数量',
    available_before INT NOT NULL COMMENT '操作前可用库存',
    available_after INT NOT NULL COMMENT '操作后可用库存',
    reserved_before INT NOT NULL,
    reserved_after INT NOT NULL,
    operator_id BIGINT COMMENT '操作人ID',
    order_id BIGINT COMMENT '关联订单ID',
    remark VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_product_time (product_id, created_at),
    INDEX idx_order (order_id)
) COMPRESSION='zstd_1.3.8';
```

```python
# 库存管理服务
class InventoryManager:
    def __init__(self, db_manager):
        self.db = db_manager
    
    def reserve_stock(self, product_id, quantity, order_id, user_id=None):
        """预留库存 - 高并发场景优化"""
        with self.db.get_connection() as conn:
            try:
                conn.begin()
                
                with conn.cursor() as cursor:
                    # 查询当前库存（使用悲观锁）
                    cursor.execute("""
                        SELECT available_stock, reserved_stock 
                        FROM inventory 
                        WHERE product_id = %s FOR UPDATE
                    """, (product_id,))
                    
                    stock_info = cursor.fetchone()
                    if not stock_info:
                        raise Exception(f"商品 {product_id} 库存记录不存在")
                    
                    available_stock, reserved_stock = stock_info
                    
                    # 检查可用库存是否充足
                    if available_stock < quantity:
                        raise Exception(f"商品 {product_id} 库存不足，当前可用: {available_stock}")
                    
                    # 更新库存
                    cursor.execute("""
                        UPDATE inventory 
                        SET available_stock = available_stock - %s,
                            reserved_stock = reserved_stock + %s,
                            last_updated = NOW()
                        WHERE product_id = %s
                    """, (quantity, quantity, product_id))
                    
                    # 记录库存变更日志
                    cursor.execute("""
                        INSERT INTO inventory_logs 
                        (product_id, operation_type, change_quantity, 
                         available_before, available_after,
                         reserved_before, reserved_after,
                         operator_id, order_id, remark)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """, (product_id, 'RESERVE', quantity,
                          available_stock, available_stock - quantity,
                          reserved_stock, reserved_stock + quantity,
                          user_id, order_id, '订单预留库存'))
                
                conn.commit()
                return True
                
            except Exception as e:
                conn.rollback()
                raise e
    
    def release_reserved_stock(self, product_id, quantity, order_id, reason):
        """释放预留库存"""
        with self.db.get_connection() as conn:
            try:
                conn.begin()
                
                with conn.cursor() as cursor:
                    cursor.execute("""
                        UPDATE inventory 
                        SET available_stock = available_stock + %s,
                            reserved_stock = reserved_stock - %s,
                            last_updated = NOW()
                        WHERE product_id = %s
                    """, (quantity, quantity, product_id))
                    
                    cursor.execute("""
                        INSERT INTO inventory_logs 
                        (product_id, operation_type, change_quantity, 
                         available_before, available_after,
                         reserved_before, reserved_after,
                         order_id, remark)
                        SELECT product_id, %s, %s, 
                               available_stock + %s, available_stock,
                               reserved_stock - %s, reserved_stock,
                               %s, %s
                        FROM inventory 
                        WHERE product_id = %s
                    """, ('RELEASE', quantity, quantity, quantity, order_id, reason, product_id))
                
                conn.commit()
                return True
                
            except Exception as e:
                conn.rollback()
                raise e
```

### 5.3 实时数据分析

```python
# 实时数据分析服务
class RealTimeAnalytics:
    def __init__(self, db_manager):
        self.db = db_manager
    
    def get_business_metrics(self, time_range='today'):
        """获取实时业务指标"""
        time_conditions = {
            'today': "DATE(created_at) = CURDATE()",
            'yesterday': "DATE(created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)",
            'week': "created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)",
            'month': "created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"
        }
        
        condition = time_conditions.get(time_range, time_conditions['today'])
        
        queries = {
            'order_statistics': f"""
                SELECT 
                    COUNT(*) as total_orders,
                    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_orders,
                    SUM(CASE WHEN status = 'completed' THEN payable_amount ELSE 0 END) as total_revenue,
                    AVG(CASE WHEN status = 'completed' THEN payable_amount END) as avg_order_value
                FROM orders 
                WHERE {condition}
            """,
            
            'user_growth': f"""
                SELECT 
                    COUNT(*) as new_users,
                    COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR) THEN 1 END) as recent_users
                FROM users 
                WHERE {condition}
            """,
            
            'popular_products': f"""
                SELECT 
                    p.name,
                    p.brand,
                    SUM(oi.quantity) as total_sold,
                    SUM(oi.subtotal) as product_revenue,
                    COUNT(DISTINCT o.user_id) as unique_buyers
                FROM order_items oi
                JOIN products p ON oi.product_id = p.product_id
                JOIN orders o ON oi.order_id = o.order_id
                WHERE {condition.replace('created_at', 'o.created_at')} 
                  AND o.status = 'completed'
                GROUP BY p.product_id, p.name, p.brand
                ORDER BY total_sold DESC
                LIMIT 10
            """,
            
            'hourly_trend': f"""
                SELECT 
                    HOUR(created_at) as hour,
                    COUNT(*) as order_count,
                    SUM(payable_amount) as hourly_revenue
                FROM orders 
                WHERE {condition} AND status = 'completed'
                GROUP BY HOUR(created_at)
                ORDER BY hour
            """
        }
        
        results = {}
        with self.db.get_connection() as conn:
            with conn.cursor(pymysql.cursors.DictCursor) as cursor:
                for metric_name, query in queries.items():
                    cursor.execute(query)
                    if metric_name in ['order_statistics', 'user_growth']:
                        results[metric_name] = cursor.fetchone()
                    else:
                        results[metric_name] = cursor.fetchall()
        
        return results
    
    def monitor_system_health(self):
        """监控系统健康状态"""
        health_queries = {
            'connection_count': "SHOW STATUS LIKE 'Threads_connected';",
            'slow_queries': "SHOW STATUS LIKE 'Slow_queries';",
            'table_locks': "SHOW STATUS LIKE 'Table_locks_waited';",
            'buffer_pool_hit_rate': """
                SELECT 
                    (1 - (SUM(IF(variable_name = 'Innodb_buffer_pool_reads', variable_value, 0)) /
                          NULLIF(SUM(IF(variable_name = 'Innodb_buffer_pool_read_requests', variable_value, 0)), 0))) * 100 
                    as buffer_pool_hit_rate
                FROM information_schema.GLOBAL_STATUS
                WHERE variable_name IN ('Innodb_buffer_pool_reads', 'Innodb_buffer_pool_read_requests')
            """
        }
        
        health_status = {}
        with self.db.get_connection() as conn:
            with conn.cursor() as cursor:
                for check_name, query in health_queries.items():
                    cursor.execute(query)
                    result = cursor.fetchone()
                    health_status[check_name] = result[1] if result else 0
        
        return health_status
```



<br/>



## 🏆 六. 性能优化

### 6.1 查询优化策略

```sql
-- 索引设计优化

-- 1. 复合索引优化
CREATE INDEX idx_orders_composite 
ON orders (user_id, status, created_at);

-- 2. 覆盖索引减少回表
CREATE INDEX idx_products_covering 
ON products (category_id, brand, price, name, product_id);

-- 3. 前缀索引节省空间
CREATE INDEX idx_users_email_prefix ON users (email(30));

-- 4. 函数索引（MySQL模式）
CREATE INDEX idx_orders_date_func ON orders ((DATE(created_at)));

-- SQL 查询优化

-- 避免 SELECT *
SELECT order_id, order_no, user_id, total_amount, status 
FROM orders WHERE user_id = 123;

-- 使用 EXISTS 替代 IN
-- 不好
SELECT * FROM users u 
WHERE u.user_id IN (SELECT user_id FROM orders WHERE status = 'paid');

-- 好
SELECT * FROM users u 
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.user_id AND o.status = 'paid');

-- 合理使用 LIMIT
SELECT * FROM orders 
ORDER BY created_at DESC 
LIMIT 20 OFFSET 100;

-- 使用 UNION ALL 替代 UNION（避免去重开销）
SELECT user_id, 'order' as type FROM orders WHERE status = 'paid'
UNION ALL
SELECT user_id, 'refund' as type FROM refunds WHERE status = 'completed';
```

### 6.2 批量操作优化

```python
# 批量插入优化
def batch_insert_optimized(cursor, table, data, batch_size=1000):
    """批量插入数据 - OceanBase 优化版本"""
    if not data:
        return
    
    # 获取字段名
    columns = list(data[0].keys())
    placeholders = ','.join(['%s'] * len(columns))
    columns_str = ','.join(columns)
    
    # 构造 SQL
    sql = f"INSERT INTO {table} ({columns_str}) VALUES ({placeholders})"
    
    # 分批执行
    for i in range(0, len(data), batch_size):
        batch = data[i:i + batch_size]
        values = [tuple(row[col] for col in columns) for row in batch]
        cursor.executemany(sql, values)
        
        # OceanBase 特有的批量提交优化
        if (i + 1) % (batch_size * 5) == 0:
            cursor.execute("SELECT SLEEP(0.01)")  # 短暂暂停让系统处理

# 批量更新优化
def batch_update_oceanbase(cursor, table, updates, conditions, batch_size=100):
    """OceanBase 批量更新优化"""
    for i in range(0, len(updates), batch_size):
        batch_updates = updates[i:i + batch_size]
        batch_conditions = conditions[i:i + batch_size]
        
        # 构建批量更新语句
        case_clauses = []
        where_clause = []
        params = []
        
        for j, (update_dict, condition_dict) in enumerate(zip(batch_updates, batch_conditions)):
            for column, value in update_dict.items():
                case_clause = f"{column} = CASE "
                for k, cond in enumerate(batch_conditions):
                    case_clause += f"WHEN {' AND '.join([f'{k} = %s' for k in condition_dict.keys()])} THEN %s "
                    params.extend(list(condition_dict.values()) + [value])
                case_clause += f"ELSE {column} END"
                case_clauses.append(case_clause)
        
        sql = f"UPDATE {table} SET {', '.join(case_clauses)} WHERE id IN ({','.join([str(c['id']) for c in batch_conditions])})"
        cursor.execute(sql, params)
```

### 6.3 连接池和缓存

```python
# OceanBase 连接池优化
class OceanBaseConnectionPool:
    def __init__(self, config, min_connections=5, max_connections=20):
        self.config = config
        self.min_connections = min_connections
        self.max_connections = max_connections
        self.pool = Queue(maxsize=max_connections)
        self.active_connections = 0
        
        # 初始化最小连接数
        for _ in range(min_connections):
            conn = self._create_connection()
            self.pool.put(conn)
            self.active_connections += 1
    
    def _create_connection(self):
        # OceanBase 特定连接配置
        ob_config = {
            **self.config,
            'autocommit': False,
            'connect_timeout': 10,
            'read_timeout': 30,
            'write_timeout': 30,
            'charset': 'utf8mb4'
        }
        return pymysql.connect(**ob_config)
    
    @contextmanager
    def get_connection(self, timeout=5):
        # 尝试从池中获取连接
        try:
            conn = self.pool.get(timeout=timeout)
        except Empty:
            # 池中无连接，创建新连接（不超过最大限制）
            if self.active_connections < self.max_connections:
                conn = self._create_connection()
                self.active_connections += 1
            else:
                raise Exception("连接池已满")
        
        try:
            # 检查连接有效性
            if not self._is_connection_alive(conn):
                conn.close()
                conn = self._create_connection()
            
            yield conn
            
            # 事务自动提交
            if not conn.get_autocommit():
                conn.commit()
                conn.autocommit(True)
                
        except Exception as e:
            # 异常时回滚
            if not conn.get_autocommit():
                conn.rollback()
                conn.autocommit(True)
            raise e
        finally:
            # 归还连接到池中
            if conn.open:
                self.pool.put(conn)
            else:
                # 连接已关闭，创建新连接
                new_conn = self._create_connection()
                self.pool.put(new_conn)
    
    def _is_connection_alive(self, conn):
        try:
            conn.ping(reconnect=False)
            return True
        except:
            return False

# 结果缓存层
class QueryCache:
    def __init__(self, redis_client, default_ttl=300):
        self.redis = redis_client
        self.default_ttl = default_ttl
    
    def cached_query(self, cache_key, query_func, ttl=None):
        """带缓存的查询"""
        ttl = ttl or self.default_ttl
        
        # 尝试从缓存获取
        cached_result = self.redis.get(cache_key)
        if cached_result:
            return json.loads(cached_result)
        
        # 缓存未命中，执行查询
        result = query_func()
        
        # 存入缓存
        self.redis.setex(cache_key, ttl, json.dumps(result, cls=DecimalEncoder))
        
        return result
```

### 6.4 监控和诊断

```sql
-- OceanBase 性能监控

-- 查看租户资源使用情况
SELECT 
    tenant_name,
    svr_ip,
    cpu_total,
    mem_total,
    disk_total,
    cpu_assigned_percent,
    mem_assigned_percent,
    disk_assigned_percent
FROM oceanbase.CDB_OB_SERVERS;

-- 查看慢查询
SELECT 
    tenant_name,
    sql_id,
    query_sql,
    executions,
    elapsed_time,
    avg_exe_time
FROM oceanbase.CDB_OB_SQL_AUDIT 
WHERE is_slow_query = 1 
  AND tenant_name = 'ecommerce_tenant'
ORDER BY avg_exe_time DESC 
LIMIT 10;

-- 查看表分区信息
SELECT 
    table_name,
    partition_name,
    high_value,
    table_rows,
    data_length,
    index_length
FROM information_schema.partitions 
WHERE table_schema = 'ecommerce'
ORDER BY table_name, partition_name;

-- 查看索引使用统计
SELECT 
    s.schemaname,
    s.tablename,
    s.indexname,
    s.idx_tup_read,
    s.idx_tup_fetch,
    s.idx_scan
FROM pg_stat_user_indexes s
JOIN pg_index i ON s.indexrelid = i.indexrelid
WHERE s.schemaname = 'ecommerce'
ORDER BY s.idx_scan DESC;

-- OceanBase 特有的诊断视图
SELECT 
    svr_ip,
    zone,
    status,
    stop_time,
    start_service_time
FROM oceanbase.DBA_OB_SERVERS;

SELECT 
    tenant_id,
    tenant_name,
    primary_zone,
    locality
FROM oceanbase.DBA_OB_TENANTS;
```



<br/>



## 🎓 七. 场景与限制

### 7.1 适合场景

- **金融核心系统**：银行、支付、保险等对一致性和可靠性要求极高的场景
- **互联网平台**：高并发、海量数据处理的电商平台、社交平台
- **政企应用**：政务系统、企业级应用需要多租户隔离
- **混合负载**：同时需要 OLTP 和 OLAP 能力的业务系统
- **国产化需求**：需要自主可控数据库解决方案
- **云原生应用**：容器化部署、弹性伸缩需求强烈的场景

### 7.2 不适合场景

- **小型项目**：简单的 CRUD 应用，MySQL 更经济实用
- **单机应用**：无需分布式能力的传统应用
- **学习研究**：数据库原理学习，SQLite 更简单
- **超大规模分析**：专门的数据仓库场景，ClickHouse 等更适合
- **极端成本敏感**：预算极其有限的初创项目

### 7.3 与其他分布式数据库对比

| 特性 | OceanBase | TiDB | GaussDB |
|------|-----------|------|---------|
| 开发厂商 | 蚂蚁集团 | PingCAP | 华为 |
| 架构类型 | 分布式关系型 | 分布式 NewSQL | 分布式关系型 |
| MySQL 兼容性 | 高度兼容 | 完全兼容 | 高度兼容 |
| Oracle 兼容性 | 支持双模式 | 有限支持 | 有限支持 |
| 金融行业适配 | ★★★★★ | ★★★★☆ | ★★★★☆ |
| 多租户支持 | ★★★★★ | ★★★☆☆ | ★★★★☆ |
| 部署复杂度 | ★★★★☆ | ★★★★☆ | ★★★☆☆ |
| 国产化程度 | ★★★★★ | ★★☆☆☆ | ★★★★★ |
| 社区活跃度 | ★★★★☆ | ★★★★★ | ★★★★☆ |



<br/>



## 📚 八. 扩展建议

### 8.1 备份与恢复

```bash
# OceanBase 备份策略

# 创建备份路径
obclient -h127.1 -P2881 -uroot -Doceanbase -e "
    CREATE BACKUP SET ENCRYPTION ON;
    CREATE BACKUP PATH '/data/backup' SERVER IP_PORT_LIST=('127.0.0.1:2882');
"

# 全量备份
obclient -h127.1 -P2881 -uroot -Doceanbase -e "
    ALTER SYSTEM ADD BACKUP DEVICE 'FILE' FORMAT '/data/backup/full_%Y%m%d_%H%i%s';
    ALTER SYSTEM BACKUP DATABASE ecommerce_tenant TO 'FILE';
"

# 增量备份
obclient -h127.1 -P2881 -uroot -Doceanbase -e "
    ALTER SYSTEM BACKUP INCREMENTAL DATABASE ecommerce_tenant TO 'FILE';
"

# 恢复数据
obclient -h127.1 -P2881 -uroot -Doceanbase -e "
    CREATE RESTORE POINT rp1 FOR DATABASE ecommerce_tenant;
    ALTER SYSTEM RESTORE DATABASE ecommerce_tenant FROM '/data/backup/full_20231201_120000';
"

# 验证备份完整性
obclient -h127.1 -P2881 -uroot -Doceanbase -e "
    SELECT backup_set_id, status, start_time, end_time 
    FROM CDB_OB_BACKUP_SET_FILES 
    ORDER BY start_time DESC;
"
```

### 8.2 安全配置

```sql
-- 用户和权限管理

-- 创建应用用户
CREATE USER 'app_user'@'%' IDENTIFIED BY 'StrongAppPass123!';

-- 授予必要权限
GRANT SELECT, INSERT, UPDATE, DELETE ON ecommerce.* TO 'app_user'@'%';
GRANT CREATE TEMPORARY TABLES ON ecommerce.* TO 'app_user'@'%';

-- 创建只读用户
CREATE USER 'readonly_user'@'%' IDENTIFIED BY 'ReadOnlyPass456!';
GRANT SELECT ON ecommerce.* TO 'readonly_user'@'%';

-- 创建管理员用户
CREATE USER 'dba_user'@'192.168.%' IDENTIFIED BY 'DBAPass789!';
GRANT ALL PRIVILEGES ON *.* TO 'dba_user'@'192.168.%' WITH GRANT OPTION;

-- 安全审计配置
SET GLOBAL general_log = 'ON';
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL log_output = 'TABLE';
SET GLOBAL long_query_time = 2;

-- 查看审计日志
SELECT 
    event_time,
    user_host,
    thread_id,
    server_id,
    command_type,
    argument
FROM mysql.general_log 
WHERE event_time >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY event_time DESC;
```

### 8.3 最佳实践

**开发规范**

1. **命名约定**：
   - 表名：小写 + 下划线，如 `user_profiles`
   - 字段名：小写 + 下划线，如 `created_at`
   - 索引名：`idx_表名_字段`，如 `idx_users_email`
   - 外键名：`fk_子表_父表`，如 `fk_orders_users`

2. **SQL 编写规范**：
   ```sql
   -- 好的写法
   SELECT user_id, username, email 
   FROM users 
   WHERE status = 1 
   ORDER BY created_at DESC 
   LIMIT 100;
   
   -- 避免的写法
   SELECT * FROM users;  -- 避免 SELECT *
   SELECT * FROM orders WHERE YEAR(created_at) = 2023;  -- 避免函数索引失效
   ```

3. **事务使用**：
   ```python
   # 明确的事务边界
   def transfer_funds(from_account, to_account, amount):
       with connection.begin():
           # 所有相关操作都在同一个事务中
           debit_account(from_account, amount)
           credit_account(to_account, amount)
           log_transaction(from_account, to_account, amount)
   ```

**监控告警配置**

```yaml
# Prometheus 监控配置
- job_name: 'oceanbase-monitor'
  static_configs:
  - targets: ['observer1:2884', 'observer2:2884', 'observer3:2884']
  metrics_path: /metrics/ob/basic
  scrape_interval: 15s
  
# 告警规则
groups:
- name: oceanbase.rules
  rules:
  - alert: HighCPUUsage
    expr: avg(rate(ob_sysstat_cpu_utilization[5m])) > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "OceanBase CPU 使用率过高"
      
  - alert: SlowQueryRate
    expr: rate(ob_sql_audit_slow_query_count[5m]) > 10
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "慢查询频率异常"
      
  - alert: LowDiskSpace
    expr: ob_server_data_disk_percent > 85
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "磁盘空间不足"
```

### 8.4 学习资源

- 📖 官方文档：https://www.oceanbase.com/docs
- 🎓 开发者中心：https://open.oceanbase.com/
- 🏫 技术社区：https://ask.oceanbase.com/
- 🐙 GitHub：https://github.com/oceanbase/oceanbase
- 📱 微信公众号：OceanBase 数据库
- 📺 B站频道：OceanBase官方账号

---

> 💡 **提示**：OceanBase 是蚂蚁集团基于多年金融业务场景打磨的分布式数据库，在高并发、强一致性、多租户隔离等方面表现出色。适合对数据可靠性和系统稳定性有极高要求的企业级应用。