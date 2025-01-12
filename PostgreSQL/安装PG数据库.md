[TOC]
### 1. Yum安装
参考[官方安装向导](https://www.postgresql.org/download/linux/redhat/) 。
```shell
# 安装服务(CENTOS7)
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql96-server
/usr/pgsql-9.6/bin/postgresql96-setup initdb
systemctl enable postgresql-9.6
systemctl start postgresql-9.6

#查看服务
psql --version
ps -ef|grep postgres

# 卸载服务
yum -y remove postgresql*
```
### 2. MacOS安装
> 参考： https://www.enterprisedb.com/postgres-tutorials/installation-postgresql-mac-os

### 3. 编译安装
1.安装依赖项
```shell
yum install -y readline readline-devel
yum install -y gcc-c++
yum install -y pcre pcre-devel
yum install -y zlib zlib-devel
yum install -y openssl openssl-devel

# ubuntu
# sudo apt-get -Y install libreadline-gplv2-dev  
 #sudo apt-get install zlib1g-dev
```
2.编译安装
```shell
# 下载解压（https://www.postgresql.org/ftp/source）
PGVERSION=12.3
wget https://ftp.postgresql.org/pub/source/v${PGVERSION}/postgresql-${PGVERSION}.tar.gz
tar -zxvf postgresql-${PGVERSION}.tar.gz && cd postgresql-${PGVERSION}

# 编译安装
./configure --prefix=/usr/local/pgsql
make && make install

# 设置环境变量
cat >> /etc/profile <<EOF
export PGHOME=/usr/local/pgsql
export PGDATA=\$PGHOME/data
export PATH=\$PGHOME/bin:\$PATH
EOF
source /etc/profile
```
3.设置开机自启
```shell
# 在刚才解压的源码包内操作，编辑linux
vim ./contrib/start-scripts/linux
```
```conf
# Installation prefix
prefix=/usr/local/pgsql
# Data directory
PGDATA="/usr/local/pgsql/data"
```
```shell
# 设置权限，并设置开机启动
chmod a+x ./contrib/start-scripts/linux
cp ./contrib/start-scripts/linux /etc/init.d/postgresql
chkconfig --add postgresql
```
4.初始化并启动数据库
```shell
# 创建postgres系统用户(可忽略8位密码提示,强制设置为123456)
# 注意：这是Linux系统用户，不是PG用户
adduser postgres
passwd  postgres
 
# 为postgres用户创建数据目录
mkdir -p $PGHOME/data
mkdir -p $PGHOME/logs
chown -R postgres $PGHOME/*

# 切换用户，并初始化数据库
su - postgres
initdb -D $PGDATA

# 启动数据库服务
pg_ctl -D $PGDATA -l $PGHOME/logs/postgres.log start 
ps -ef | grep postgres
psql --version
```
### 3. 访问授权
> PG默认会创建一个`postgres(密码为空)`的数据库用户作为管理员。
```shell
su - postgres
psql  -c "ALTER user postgres with password '123456';"
psql  -c "select * from pg_shadow;"
```

```shell
vim /usr/local/pgsql/data/postgresql.conf

# 监听所有网络
listen_addresses = '*'
```
```shell
# 客户端授权
vim /usr/local/pgsql/data/pg_hba.conf

# local用户信任(无密码)访问
local   all          all                               trust
# 外部主机：所有用户|所有权限|所有IP|密码方式访问
host    all          all          0.0.0.0/0            md5
```
```shell
# 重启数据库使配置生效
su - postgres
pg_ctl -D $PGDATA -l $PGHOME/logs/postgres.log restart 
```
6.测试数据库
```sql
psql
create database demodb;
\c demodb
create table person(id integer, name text);
insert into person values (1,'tom'),(2,'lucy'),(3,'jack');
select * from person;
```

### 4.root账号授权
> root账号须使用`psql -U postgres`方式访问PG，我们可以添加别名，以简化root访问方式：
```shell
cat >> /etc/profile <<EOF
export PGPASSWORD=123456
# psql -U <username> -d <dbname> -h 127.0.0.1 -p 5432 
alias psql='psql -U postgres'
alias pg_dump='pg_dump -U postgres'
EOF
source /etc/profile

# root用户下输入psql直接登录PG
psql
```

### 参考链接
http://www.postgres.cn/v2/home
https://www.cnblogs.com/sunhongleibibi/p/11943393.html
http://blog.sina.com.cn/s/blog_8be8eb1b0101l1dt.html


https://www.enterprisedb.com/download-postgresql-binaries





