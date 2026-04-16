# PostgreSQL 逻辑复制双向同步操作指南（双活架构）

> **文档版本**：1.1  
> **适用版本**：PostgreSQL 10+（推荐 13+）  
> **场景**：两个数据库节点双向同步，无写同一记录冲突（主键建议使用 UUID）  
> **目标**：实现双活数据复制，简单易维护
>
> 
>
> **使用场景**：把数据实时复制到另一个库，比如主库到分析库、不同版本PostgreSQL之间同步、两个库同时写入不同数据（互不冲突）。
> **局限性**：改表结构不会自动同步，两个库同时改同一条数据会报错停掉，而且数据同步有延迟。

---

## 1. 原理与架构说明

### 1.1 逻辑复制原理

PostgreSQL 逻辑复制基于 **WAL（Write-Ahead Log）** 的逻辑解码机制：

- **发布（Publication）**：节点上定义的一组表，标记为“可被复制”。节点会持续捕获这些表的变更（INSERT/UPDATE/DELETE），将其从 WAL 中解码为逻辑变更流。
- **订阅（Subscription）**：节点通过连接字符串连接到发布节点，接收变更流并应用（即回放）到本地表。
- **双向同步**：两个节点分别创建指向对方的订阅，同时各自发布自己的变更。PostgreSQL 内部通过**复制源标识**避免循环复制。

逻辑复制相比物理流复制的优势：**表级选择性、跨版本、双写支持**；劣势：不同步 DDL、最终一致性、无自动冲突解决。

### 1.2 双活架构图

```
        ┌─────────────┐          ┌─────────────┐
        │   节点 A    │◄────────►│   节点 B    │
        │ 192.168.1.10│ 逻辑复制  │ 192.168.1.20│
        └──────┬──────┘          └──────┬──────┘
               │                        │
               └──────────┬─────────────┘
                          │
                   应用层双写（随机/轮询）
```

- **节点 A 与节点 B**：彼此平等，均可读写。
- **发布与订阅**：A 发布 `pub_a`，B 订阅；B 发布 `pub_b`，A 订阅。
- **数据流向**：A 的变更 → 复制到 B；B 的变更 → 复制到 A。
- **前提条件**：应用确保 **不会在短时间内修改同一行数据**（或使用 UUID 主键避免主键冲突）。

---

## 2. 安装与前置要求

### 2.1 PostgreSQL 安装

如果尚未安装 PostgreSQL，按以下方式安装（以 PostgreSQL 15 为例）：

**CentOS/RHEL 7+**：
```bash
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install -y postgresql15-server postgresql15-contrib
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
sudo systemctl enable postgresql-15
sudo systemctl start postgresql-15
```

**Ubuntu 20.04/22.04**：
```bash
sudo apt update
sudo apt install -y postgresql-15 postgresql-contrib-15
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

**验证版本**：
```bash
psql --version
```

### 2.2 确认逻辑复制支持

逻辑复制不需要额外安装扩展，但需确认 `wal_level` 可设为 `logical`（PostgreSQL 10+ 默认 `replica`，需修改）。

---

## 3. 环境准备

| 节点 | 主机名/IP  | 数据库名 | 端口 |
|------|-----------|---------|------|
| A    | 192.168.1.10 | appdb   | 5432 |
| B    | 192.168.1.20 | appdb   | 5432 |

- 操作系统：Linux
- 网络互通，防火墙开放 5432 端口
- 两台节点 PostgreSQL 已安装并运行

---

## 4. 配置 PostgreSQL 参数（两个节点均需执行）

编辑 `postgresql.conf`（常见路径：`/var/lib/pgsql/data/postgresql.conf` 或 `/etc/postgresql/15/main/postgresql.conf`）：

```ini
wal_level = logical                # 必须设置为 logical
max_replication_slots = 10         # 至少 2 个（双向各占一个槽）
max_wal_senders = 10               # 至少大于复制槽数量
max_logical_replication_workers = 8
max_sync_workers_per_subscription = 2
listen_addresses = '*'
```

重启 PostgreSQL：

```bash
sudo systemctl restart postgresql
# 或使用 pg_ctl 重启
```

---

## 5. 配置 pg_hba.conf 允许复制连接

编辑 `pg_hba.conf`（与 postgresql.conf 同目录），添加：

```conf
# 允许对方节点使用复制用户连接
host    replication     repl_user       192.168.1.10/32       md5
host    replication     repl_user       192.168.1.20/32       md5
# 允许普通数据库连接（用于初始数据同步）
host    appdb           repl_user       192.168.1.10/32       md5
host    appdb           repl_user       192.168.1.20/32       md5
```

重载配置：

```bash
sudo systemctl reload postgresql
```

---

## 6. 创建复制专用用户（两个节点均需执行）

使用超级用户（如 `postgres`）连接数据库：

```sql
CREATE USER repl_user WITH REPLICATION LOGIN PASSWORD 'StrongPass123';
GRANT CONNECT ON DATABASE appdb TO repl_user;
GRANT USAGE ON SCHEMA public TO repl_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO repl_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO repl_user;
```

> **提示**：若表较多，可临时赋予 `repl_user` 超级用户权限（生产环境慎用）。

---

## 7. 表结构要求（避免主键冲突）

逻辑复制要求每个表有**主键**或**唯一索引**（所有列 NOT NULL）。  
**强烈建议使用 UUID 主键**，避免双节点写入时产生主键冲突。

```sql
-- 示例表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

如果已有表使用自增整数主键，可改为 UUID 或设置不同步长（复杂），推荐应用层改造。

---

## 8. 初始数据同步（两个节点数据需一致）

假设节点 A 已有数据，先同步到节点 B。

### 8.1 在节点 A 导出数据

```bash
pg_dump -U postgres -h 192.168.1.10 -d appdb -Fc -f appdb_dump.dump
```

### 8.2 在节点 B 恢复数据

```bash
pg_restore -U postgres -h 192.168.1.20 -d appdb -C -c appdb_dump.dump
```

> **注意**：恢复前确保节点 B 数据库为空或可覆盖。

---

## 9. 创建发布和订阅

### 9.1 在节点 A 上创建发布

```sql
CREATE PUBLICATION pub_a FOR ALL TABLES;
```

### 9.2 在节点 B 上创建发布

```sql
CREATE PUBLICATION pub_b FOR ALL TABLES;
```

### 9.3 在节点 A 上创建订阅（订阅节点 B 的发布）

```sql
CREATE SUBSCRIPTION sub_a
CONNECTION 'host=192.168.1.20 port=5432 dbname=appdb user=repl_user password=StrongPass123'
PUBLICATION pub_b
WITH (copy_data = true);   -- 首次会拷贝节点B现有数据（需B已有数据）
```

### 9.4 在节点 B 上创建订阅（订阅节点 A 的发布）

```sql
CREATE SUBSCRIPTION sub_b
CONNECTION 'host=192.168.1.10 port=5432 dbname=appdb user=repl_user password=StrongPass123'
PUBLICATION pub_a
WITH (copy_data = false);  -- 节点A数据已通过pg_dump恢复，无需再次拷贝
```

> **说明**：若初始数据同步是通过 `pg_dump` 完成，则只在一个订阅开启 `copy_data = true`；否则可能导致数据重复。

---

## 10. 验证复制状态

### 10.1 查看订阅状态（任一节点）

```sql
SELECT subname, status, received_lsn, last_msg_send_time, last_msg_receipt_time 
FROM pg_stat_subscription;
```
- `status = t` 表示正常。

### 10.2 测试双向同步

节点 A 插入数据，节点 B 查询；反之亦然。

```sql
-- 节点 A
INSERT INTO users (name) VALUES ('Alice');
-- 节点 B（稍等后查询）
SELECT * FROM users WHERE name = 'Alice';
```

---

## 11. 日常维护与故障处理

### 11.1 监控复制延迟

```sql
SELECT 
    subname,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), received_lsn)) as replication_lag
FROM pg_stat_subscription;
```

### 11.2 处理订阅中断

若因网络闪断等原因停止，PostgreSQL 会自动重连。若因错误停止（如主键冲突），查看错误原因：

```sql
SELECT * FROM pg_stat_subscription WHERE status = 'f';
```

恢复方法（先禁用再启用）：

```sql
ALTER SUBSCRIPTION sub_a DISABLE;
ALTER SUBSCRIPTION sub_a ENABLE;
```

### 11.3 变更表结构（DDL）

逻辑复制**不同步 DDL**。需在两个节点**手动执行相同 DDL**：

```sql
-- 节点 A
ALTER TABLE users ADD COLUMN email TEXT;
-- 节点 B
ALTER TABLE users ADD COLUMN email TEXT;
```

建议使用迁移工具（Flyway、Liquibase）同时作用于两个节点。

### 11.4 磁盘空间保护

设置复制槽保留 WAL 上限（PG 13+）：

```ini
max_slot_wal_keep_size = 10GB   # 避免订阅中断导致 WAL 堆积
```

---

## 12. 故障恢复（节点完全失效后重建）

假设节点 A 故障，修复后需重新同步数据：

1. 清空节点 A 数据库。
2. 从节点 B 导出数据：`pg_dump -h 192.168.1.20 ...`
3. 恢复到节点 A。
4. 在节点 A 重新创建订阅（指向节点 B）：

```sql
DROP SUBSCRIPTION IF EXISTS sub_a;
CREATE SUBSCRIPTION sub_a CONNECTION '...' PUBLICATION pub_b WITH (copy_data false);
```

5. 检查节点 B 上的订阅 `sub_b` 状态，若异常则重建。

---

## 13. 最佳实践总结

- **主键使用 UUID**：彻底避免双节点写入冲突。
- **监控复制槽**：定期检查 `pg_replication_slots`，防止 WAL 堆积。
- **负载均衡**：应用层配置两个节点地址，随机或按权重分发写请求（确保同一记录总是落在同一节点，否则可能出现更新丢失；但 UUID 主键下，不同节点更新不同行是安全的）。
- **不要同时修改同一行**：业务层必须保证。
- **定期测试切换**：模拟节点故障，验证应用能否正常切换到另一节点。

---

## 附录：快速安装脚本（CentOS 7+）

```bash
#!/bin/bash
# 在两台节点分别执行

# 安装 PostgreSQL 15
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install -y postgresql15-server postgresql15-contrib
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
sudo systemctl start postgresql-15
sudo systemctl enable postgresql-15

# 修改配置
sudo sed -i "s/#wal_level = replica/wal_level = logical/" /var/lib/pgsql/15/data/postgresql.conf
sudo sed -i "s/#max_replication_slots = 10/max_replication_slots = 10/" /var/lib/pgsql/15/data/postgresql.conf
sudo sed -i "s/#max_wal_senders = 10/max_wal_senders = 10/" /var/lib/pgsql/15/data/postgresql.conf
sudo systemctl restart postgresql-15

echo "PostgreSQL 安装配置完成，请继续按操作指南配置 pg_hba 和创建用户。"
```

