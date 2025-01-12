[TOC]

**主机信息：**
```shell
# cat /etc/hosts
10.20.20.1 pg_master   # PG主机
10.20.20.2 pg_standby  # PG从机
```

## 一. 配置主服务
1.创建`replicator`角色，并赋予登录和复制的权限。
```shell
CREATE ROLE replicator login replication encrypted password '123456';
\du
```
2.修改`pg_hba.conf`,添加如下两项。
```shell
vim /var/lib/pgsql/9.6/data/pg_hba.conf
```
```shell
#host   all           all         10.20.20.2/32  trust   #允许从机连接
host    replication   replicator  pg_standby  md5        #允许从机复制
```
3.修改`postgresql.conf`配置。
```shell
vim /var/lib/pgsql/9.6/data/postgresql.conf
```
```shell
listen_addresses = '*'
wal_level = replica  #设置主为wal的主机   
max_wal_senders = 32          #最多有几个流复制连接
wal_keep_segments = 256  #流复制保留的最多的xlog数目
wal_sender_timeout = 60s #设置流复制主机发送数据的超时时间
max_connections = 100   # 从库必须要大于主库的数量

# 是否开启归档，参考 http://www.freeswitch.net.cn/130.html
# archive_mode = on
# archive_command = 'rsync -a %p postgres@standbyhost:/var/lib/postgresql/9.6/main/archive/%f'
```
```shell
# 如果是以root开启并创建归档模式，则须将权限授权给postgres用户）
mkdir -p /var/lib/postgresql/9.6/main/archive/
chmod 700 /var/lib/postgresql/9.6/main/archive/
chown -R postgres:postgres /var/lib/postgresql/9.6/main/archive/
```
4.重启服务
```shell
systemctl restart postgresql-9.6.service
```

## 二. 配置从服务
1.将`master`数据目录覆盖`standby`数据目录
```shell
cd /var/lib/pgsql/9.6

# 清空standby的数据目录，并复制master数据目录
tar -zcvf data.tar.gz ./data && rm -rf  ./data/* 
pg_basebackup -h pg_master -U replicator -D /var/lib/pgsql/9.6/data -X stream -P
```
2.配置主从复制链接
```shell
cp /usr/pgsql-9.6/share/recovery.conf.sample /var/lib/pgsql/9.6/data/recovery.conf
vim /var/lib/pgsql/9.6/data/recovery.conf
```
```shell
# recovery.conf内容
standby_mode = on    # 说明该节点是从服务器
primary_conninfo = 'host=pg_master port=5432 user=replicator password=123456'  # 主服务器的信息以及连接的用户
recovery_target_timeline = 'latest'
```
3.修改`postgresql.conf`
```shell
vim /var/lib/pgsql/9.6/data/postgresql.conf
```
```shell
max_connections = 500 #一般查多于写的应用从库的最大连接数要比较大
hot_standby = on  #说明这台机器不仅仅是用于数据归档，也用于数据查询
max_standby_streaming_delay = 30s # 数据流备份的最大延迟时间
wal_receiver_status_interval = 10s  # 多久向主报告一次从的状态，当然从每次数据复制都会向主报告状态，这里只是设置最长的间隔时间
hot_standby_feedback = on # 如果有错误的数据复制，是否向主进行反馈
```
4.重启服务
```shell
# 如果上面的操作用户是root，则须将目录授权给postgres用户
chown -R postgres:postgres /var/lib/pgsql/9.6/data/*
systemctl restart postgresql-9.6.service
```

## 三. 测试主从
```shell
# 在master上执行SQL，查看主从信息
postgres=# select client_addr,sync_state from pg_stat_replication;
   client_addr   | sync_state
-----------------+------------
 10.20.20.2 | async
```
```shell
# 查看master进程，会有wal sender信息
ps aux | grep postgres
postgres  26556  ... postgres: wal sender process replicator 10.20.20.2(38452) streaming 0/30003E0

# 查看standby进程，会有wal receiver信息
ps aux | grep postgres
postgres  12422  ... postgres: wal receiver process   streaming 0/30003E0
```

## 四. 主从切换
> 在主库故障或维护过程中，可以讲从库提升(`promote`)为主库。
```shell
# 模拟主库故障
/usr/pgsql-9.6/bin/pg_ctl stop -m fast

# 将从库提升为主库，并查看主从角色(f:主库，t:从库)
/usr/pgsql-9.6/bin/pg_ctl promote
psql -c "select pg_is_in_recovery();"
```
```shell
# 旧主库的数据已经滞后，所以在旧主库执行恢复
pg_rewind --target-pgdata $PGDATA --source-server='host=pg_standby port=5432 user=postgres dbname=postgres' -P

# 重启旧主库，使之变为新从库
pg_ctl start -D $PGDATA
```

## 参考链接：
> https://www.jianshu.com/p/12bc931ebba3


postgresql wal 解释
https://blog.csdn.net/cdnight/article/details/79455366





