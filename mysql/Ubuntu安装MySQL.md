# Ubuntu22.04安装MySQL8.x



## 系统环境

```shell
# 内核版本
$ uname -r
5.15.0-67-generic

# Ubuntu版本
$ lsb_release -d | awk -F"\t" '{print $2}'
Ubuntu 22.04.2 LTS

# CPU架构
$ lscpu | grep Architecture | awk '{print $2}'
x86_64
```



##  安装Mysql

> 下载 [Mysql离线包( **DEB Bundle**) ](https://dev.mysql.com/downloads/mysql) ，按顺序安装组件包。

```shell
$ VERSION=8.2.0
$ LIBCLI=libmysqlclient22

$ VERSION=8.3.0
$ LIBCLI=libmysqlclient23

# 下载解压(选择版本 Server ${VERSION} Innovation -> ubuntu22.04_x86_64bit -> DEB Bundle)
$ wget https://dev.mysql.com/get/Downloads/MySQL-8.3/mysql-server_${VERSION}-1ubuntu22.04_amd64.deb-bundle.tar
$ tar -xvf mysql-server_${VERSION}-1ubuntu22.04_amd64.deb-bundle.tar -C ./tmp && cd tmp

# 安装依赖项
$ sudo dpkg -i mysql-common_${VERSION}-1ubuntu22.04_amd64.deb

# 安装Client
$ sudo dpkg -i mysql-community-client-plugins_${VERSION}-1ubuntu22.04_amd64.deb
$ sudo dpkg -i mysql-community-client-core_${VERSION}-1ubuntu22.04_amd64.deb
$ sudo dpkg -i ${LIBCLI}_${VERSION}-1ubuntu22.04_amd64.deb
$ sudo dpkg -i libmysqlclient-dev_${VERSION}-1ubuntu22.04_amd64.deb
$ sudo dpkg -i mysql-community-client_${VERSION}-1ubuntu22.04_amd64.deb
$ sudo dpkg -i mysql-client_${VERSION}-1ubuntu22.04_amd64.deb

# 安装依赖和mysql-server (按提示输入root密码)
$ sudo apt-get -y install libmecab2  # https://pkgs.org/download/libmecab2
$ sudo apt-get -y install libaio1	 # https://pkgs.org/download/libaio1
$ sudo dpkg -i mysql-community-server-core_${VERSION}-1ubuntu22.04_amd64.deb
$ sudo dpkg -i mysql-community-server_${VERSION}-1ubuntu22.04_amd64.deb
$ sudo dpkg -i mysql-server_${VERSION}-1ubuntu22.04_amd64.deb

# 查看版本
$ mysql -V
mysql  Ver 8.3.0 for Linux on x86_64 (MySQL Community Server - GPL)
```



## 服务配置

- **查看默认配置文件**

```shell
# 配置文件加载优先级
$ mysql --help | grep "/etc/my.cnf"
/etc/my.cnf /etc/mysql/my.cnf ~/.my.cnf
```

- **修改监听IP和端口**

```shell
# 如果未找到bind-address等配置项，bind-address=0.0.0.0, 则允许远程访问
$ cat /etc/mysql/my.cnf|grep bind-address
  bind-address = 0.0.0.0
  port = 3306
 
# 重启服务
$ sudo service mysql restart
```
- **查看Mysql相关参数**

```sql
SHOW VARIABLES LIKE 'bind_address';					-- 服务监听IP
SHOW VARIABLES LIKE 'port';  						-- 显示MySQL服务器监听的端口号
SHOW VARIABLES LIKE 'datadir';
SHOW VARIABLES LIKE 'log_error';

SHOW VARIABLES LIKE 'innodb_data_home_dir';  		-- 显示InnoDB数据文件的主目录
SHOW VARIABLES LIKE 'innodb_log_group_home_dir';    -- 显示InnoDB日志文件组的主目录
SHOW VARIABLES LIKE 'innodb_log_files_in_group';    -- 显示InnoDB日志文件组中的文件数量
```



## 授权访问

```shell
# 登录mysql，允许root远程访问
$ mysql -uroot -p

# 允许root用户localhost无密码访问
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY '';
mysql> GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
mysql> FLUSH PRIVILEGES;

# 允许root用户远程密码访问
mysql> CREATE USER 'root'@'%' IDENTIFIED WITH caching_sha2_password BY '<YOUR_PASSWORD>';
mysql> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
mysql> FLUSH PRIVILEGES;

# 创建admin(工作账号),并授予全部权限(推荐)
mysql> CREATE USER 'admin'@'%' IDENTIFIED BY '<YOUR_PASSWORD>';
mysql> GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
mysql> FLUSH PRIVILEGES;

# 查看用户信息
mysql> SELECT user,host,plugin,authentication_string FROM mysql.user;
+------------------+-----------+-----------------------+-------------------------------+
| user             | host      | plugin                | authentication_string         |
+------------------+-----------+-----------------------+-------------------------------+
| admin            | %         | caching_sha2_password | $A$005$)PU6U{~%}|ds\9...xGR9  |
| root             | %         | caching_sha2_password | $A$005$q<O%K,RtoZ!OEr...Y8u0  |
| root             | localhost | caching_sha2_password |                               |
| mysql.infoschema | localhost | caching_sha2_password | $A$005$THISISAC...ERBRBEUSED  |
| mysql.session    | localhost | caching_sha2_password | $A$005$THISISAC...ERBRBEUSED  |
| mysql.sys        | localhost | caching_sha2_password | $A$005$THISISAC...ERBRBEUSED  |
+------------------+-----------+-----------------------+-------------------------------+
```




## 卸载Mysql

```shell
sudo apt-get -y remove --purge mysql-server mysql-client mysql-common
sudo apt-get -y autoremove
sudo apt-get -y clean
sudo apt-get -y purge mysql*
sudo apt-get -y autoclean
sudo apt-get -y dist-upgrade
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/mysql
sudo rm -rf /var/log/mysql
```



## 参考链接

> https://repo.mysql.com/
> 
> https://dev.mysql.com/downloads/mysql

