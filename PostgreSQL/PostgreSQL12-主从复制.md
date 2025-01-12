[TOC]

## 前言
PostgreSQL数据库支持多种复制解决方案，以构建高可用性，可伸缩，容错的应用程序，其中之一是预写日志（WAL）传送。该解决方案允许使用基于文件的日志传送或流复制，或者在可能的情况下，将两种方法结合使用来实现备用服务器。

使用流复制时，备用（复制从属）数据库服务器被配置为连接到主服务器/主服务器，主服务器/主服务器在生成WAL记录时将其流传输到备用服务器，而无需等待WAL文件被填充。

默认情况下，流复制是异步的，其中在将事务提交到主服务器后将数据写入备用服务器。这意味着在主服务器中提交事务与更改在备用服务器中变得可见之间存在很小的延迟。这种方法的一个缺点是，如果主服务器崩溃，则可能无法复制任何未提交的事务，这可能导致数据丢失。

> **注意**：PostgreSQL 12对主从复制实现和配置做了重大改进，如废弃了`recovery.conf`，并将参数转换为普通的`PostgreSQL`配置参数，使得配置群集和复制更加简单。

<br/>

**示例环境：**

```shell
Postgresql master  database server:     10.20.20.1
Postgresql standby database server:     10.20.20.2
```

## 一.  配置主服务器

**1. 修改监听端口**

```shell
su - postgres
psql -c "ALTER SYSTEM SET listen_addresses TO '*';"/
ls -l /var/lib/pgsql/12/data/  # 会生成一个postgresql.auto.conf文件
```

>  `ALTER SYSTEM SET`会将配置保存在一个`postgresql.conf.auto`中，与`postgresql.conf`并存，系统会优先使用`.auto`配置。 

**2. 创建复制角色**

```shell
# su – postgres
createuser --replication -P -e replicator # -P:设置密码，-e：回显
psql -c "\du"
exit
```

**3. 角色授权**
`vim /var/lib/pgsql/12/data/pg_hba.conf`
```shell
host    replication     replicator      10.20.20.2/24     md5
```

**4.  重启服务**

```shell
systemctl restart postgresql-12.service
```

**5. 设置防火墙(非必选)** 

```shell
firewall-cmd --add-service=postgresql --permanent
firewall-cmd --reload
```


## 二.  配置从服务器

**1. 将主机基础数据备份到从机**

```shell
# 先停掉服务，备份下本地数据，并清除本地数据
systemctl stop postgresql-12.service
su - postgres
tar -zcvf /var/lib/pgsql/12/data.tar.gz /var/lib/pgsql/12/data #备份一下
rm -rf /var/lib/pgsql/12/data/*
```

```shell
# 使用pg_basebackup工具备份
pg_basebackup -h 10.20.20.1 -D /var/lib/pgsql/12/data -U replicator -P -v  -R -X stream -C -S pgstandby1
exit
```

- `-h` –指定作为主服务器的主机。
- `-D` –指定数据目录。
- `-U` –指定连接用户。
- `-P` –启用进度报告。
- `-v` –启用详细模式。
- `-R`–启用恢复配置的创建：创建一个**standby.signal**文件，并将连接设置附加到数据目录下的**postgresql.auto.conf**。
- `-X`–用于在备份中包括所需的预写日志文件（WAL文件）。流的值表示在创建备份时流式传输WAL。
- `-C` –在开始备份之前，允许创建由-S选项命名的复制插槽。
- `-S` –指定复制插槽名称。



> 备份过程完成后，会在data目录下创建了一个`standby.signal`，并将`primary_conninfo`写入`postgresql.auto.conf`。

```
ls -l /var/lib/pgsql/12/data/
cat /var/lib/pgsql/12/data/postgresql.auto.conf
```

如果postgresql.conf中的hot_standby参数设置为on（默认值），并且数据目录中存在Standby.signal文件，则`replication slave`将在“热备”模式下运行。



**2. 验证`主机(master)`复制插槽信息** 
```shell
# su - postgres
$ psql -c "SELECT * FROM pg_replication_slots;"
$ exit
```
> 在`pg_replication_slots`视图会看到名为`pgstandby1`的复制插槽。

**3. 启动从服务(standby)**
```shell
＃systemctl start postgresql-12
```

## 三. 测试主从服务

**1. 查看从服务(WAL接收器进程)状态：**


```shell
psql -c "\x" -c "SELECT * FROM pg_stat_wal_receiver;"
```

```shell
扩展显示已打开.
-[ RECORD 1 ]---------+----------------------------
pid                   | 3240
status                | streaming
receive_start_lsn     | 0/3000000
receive_start_tli     | 1
received_lsn          | 0/3013BF8
received_tli          | 1
last_msg_send_time    | 2020-06-22 18:12:29.985512+08
last_msg_receipt_time | 2020-06-22 18:12:29.761575+08
latest_end_lsn        | 0/3013BF8
latest_end_time       | 2020-06-22 17:02:51.977569+08
slot_name             | pgstandby1
sender_host           | 10.20.20.1
sender_port           | 5432
conninfo              | user=replicator password=******** dbname=replication host=10.20.20.1 port=5432 fallback_application_name=walreceiver sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any
```

**2. 查看主服务(WAL发送器进程)状态：**

```shell
psql -c "\x" -c "SELECT * FROM pg_stat_replication;"
```
```shell
-[ RECORD 1 ]----+------------------------------
pid              | 4647
usesysid         | 16384
usename          | replicator
application_name | walreceiver
client_addr      | 10.20.20.2
client_hostname  |
client_port      | 38418
backend_start    | 2020-06-22 16:54:54.391772+08
backend_xmin     |
state            | streaming                    # ☆☆☆服务状态☆☆☆
sent_lsn         | 0/3013BF8
write_lsn        | 0/3013BF8
flush_lsn        | 0/3013BF8
replay_lsn       | 0/3013BF8
write_lag        |
flush_lag        |
replay_lag       |
sync_priority    | 0
sync_state       | async                       # ☆☆☆同步状态☆☆☆
reply_time       | 2020-06-22 18:18:20.293569+08
```

**3. 数据测试**
> 在`master`创建`replica_demo`数据库，在`standby`上可以看到同步效果
```shell
[master] ＃CREATE DATABASE replica_demo;
[standby]＃\l
```

## 参考链接
> https://www.tecmint.com/configure-postgresql-streaming-replication-in-centos-8/


