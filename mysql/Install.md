@[toc]
**1.准备环境：** 下载与操作系统相兼容的[Mysql版本](https://repo.mysql.com/yum/)，[查看安装向导](https://dev.mysql.com/doc/refman/5.7/en/linux-installation-yum-repo.html) 。
```shell
# 查看服务器操作系统版本信息
$ uname -r          #lunix内核版本 3.10.0...x86_64
$ lsb_release -d    #linux发行版本 7.6.1810
```

**2.安装YUM库(`在线安装`)：**（获取最新yum包：https://repo.mysql.com/yum/）
```shell
# wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm     #v8.0
$ wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm    #v5.7
$ yum localinstall -y mysql57-community-release-el7-11.noarch.rpm           
```
**3.安装数据库**
```shell
$ rpm -qa|grep mysql        #是否安装了Mysql
$ yum install -y mysql-community-server

$ service mysqld start    #启动
$ service mysqld status   #查看运行状态
$ mysql --version         #查看版本
```
**4.重置root密码**，否则无法进行下一步。
```shell
$ grep 'temporary password' /var/log/mysqld.log   #查看初始密码
$ mysql -uroot -p                                 #初始密码登录
mysql> SET PASSWORD = PASSWORD('My#123.com');     #设置新密码
mysql> ALTER USER 'root'@'localhost' PASSWORD EXPIRE NEVER;
mysql> FLUSH PRIVILEGES;
```
_设置简单密码：_
```shell
# 不同Mysql版本的全局变量名有差异
mysql> SHOW VARIABLES LIKE '%validate%';              #查看安全策略
mysql> SET GLOBAL validate_password_policy=0;         #最低密码策略（0，1，2）
mysql> SET GLOBAL validate_password_length=4;         #密码长度(最短为4位)
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';  
mysql> FLUSH PRIVILEGES; 
```
**5.远程访问**
```shell
mysql> SELECT USER,HOST,PLUGIN FROM mysql.user;
mysql> UPDATE mysql.user SET HOST='%' WHERE USER='root'; #修改root域
mysql> FLUSH PRIVILEGES;
```
**6.验证MySQL**
```shell
$ mysql -V        #查看版本
$ mysql -h192.168.xxx.xxx -uroot -p
Enter password: 
mysql> select version();
+-----------+
| version() |
+-----------+
| 5.7.18    |
+-----------+
1 row in set (0.00 sec)
```


<br/>

> 参考：
> 下载地址：https://dev.mysql.com/downloads/mysql/
> Mac版安装：https://www.jianshu.com/p/e5c9e8ef8ccb
> 离线安装：https://blog.csdn.net/ai_64/article/details/100557530





## Ubuntu

```shell
# 安装数据库(可指定版本)
sudo apt list -a mysql-server
sudo apt install -y mysql-server=8.0.28-0ubuntu4
systemctl status mysql

# 修改密码（初始为空）
$ sudo mysql -uroot
> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Pass@1234';
> FLUSH PRIVILEGES;

# 改变访问策略
sudo mysql_secure_installation


# 卸载重装
sudo apt-get -y remove --purge mysql-server mysql-client mysql-common
sudo apt-get -y autoremove
sudo apt-get -y clean
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/mysql
sudo rm -rf /var/log/mysql
sudo apt-get -y install mysql-server
```



















