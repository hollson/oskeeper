### zabbix脚本化安装注意事项

### 1.一体化安装部署

#### 1.1.支持的操作系统

```bash
zabbix7.0 LTS 服务端支持：
CentOS8-Stream系列 CentOS9-Stream系列 CentOS8.0-8.5系列 OracleLinux8系列 OracleLinux9系列 RedhatLinux8系列 RedhatLinux9系列 rocky Linux8系列 rocky Linux9系列 ubuntu2204系列 ubuntu2404系列
#注意：因红帽部分源被移除，请使用RedhatLinux8.6或者以上的系统

zabbix6.0 LTS 服务端支持
CentOS8-Stream系列 CentOS9-Stream系列 CentOS8.0-8.5系列 OracleLinux8系列 OracleLinux9系列 RedhatLinux8系列 RedhatLinux9系列 rocky Linux8系列 rocky Linux9系列 ubuntu2204系列 ubuntu2004系列

zabbix5.0 LTS 服务端支持
CentOS8系列 CentOS7系列 OracleLinux7系列 OracleLinux8系列 RedhatLinux7系列 RedhatLinux8系列 rocky Linux8系列  ubuntu2004系列 ubuntu1804系列
```

#### 1.2运行脚本前的配置

```bash
A：固定的IP地址
B：虚拟机或者物理机
C：需要互联网连接
D：配置好网络源
E：执行脚本需要root权限
F：脚本需要可执行权限
```

#### 1.3.字体

在执行脚本前，需要将本地电脑的微软雅黑字体上传到于脚本在同一个目录

微软雅黑字体在C:\Windows\Fonts

名称：（以Windows10为例）

```html
msyhbd.ttc
#或者修改脚本中字体的变量名称，替换为自己喜欢的字体，并将自己喜欢的字体同脚本上传到服务器
```

上传完毕后增加执行权限，运行脚本

#### 1.5.脚本运行过程

```bash
[root@localhost ~]# ./install_zabbix_server7 
为RHEL\CentOS\OL\Rocky Linux关闭SElinux...
SELinux配置文件已更改为禁用状态
SELinux的永久更改需要重启系统才能生效
为RHEL\CentOS\OL\Rocky Linux配置防火墙...
success
success
success
success
配置防火墙完成
安装MariaDB源...
安装并初始化MariaDB数据库...
Created symlink /etc/systemd/system/multi-user.target.wants/mariadb.service → /usr/lib/systemd/system/mariadb.service.
MariaDB数据库准备完成
针对CentOS8和RHEL8系统使用remi源安装PHP8...
PHP 8.0 安装和配置完成
安装zabbix服务端...
YUM仓库准备完成
配置zabbix服务端...
Created symlink /etc/systemd/system/multi-user.target.wants/zabbix-server.service → /usr/lib/systemd/system/zabbix-server.service.
Created symlink /etc/systemd/system/multi-user.target.wants/zabbix-agent.service → /usr/lib/systemd/system/zabbix-agent.service.
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
Created symlink /etc/systemd/system/multi-user.target.wants/php-fpm.service → /usr/lib/systemd/system/php-fpm.service.

ZABBIX-7.0安装完成!
-------------------------------------------------------------------
请访问: http://192.168.56.58/zabbix  默认用户名密码:  Admin / zabbix 数据库密码 123456
```



#### 1.4.运行脚本后

6.0LTS和5.0LTS版本，脚本执行完毕后运行以下参数，无需重启服务和操作系统以及数据库，7.0LTS版本无需设置，脚本会自动修改

```mysql
# mysql -uroot -p
password
mysql> set global log_bin_trust_function_creators = 0;
mysql> quit;

#说明：
#对于 Zabbix 6.0.11 及更新版本，需要在导入模式期间创建确定性触发器。 在 MySQL 和 MariaDB 上，如果启用了二进制日志记录并且没有超级用户权限同时未在MySQL配置文件中配置 log_bin_trust_function_creators = 1 ，则需要设置 GLOBAL log_bin_trust_function_creators = 1。
```

### 2.分离安装部署

#### 2.1.LTS5.0版本

##### 数据库

```bash
上传文件install_config_zabbix5.0_DBserver.sh到准备安装zabbix5.0数据库的服务器
执行前修改脚本变量
MYSQL_ZABBIX_USER="zabbix@'%'"           #修改为数据库zabbix的用户名称
MYSQL_ZABBIX_PASS='123456'               #修改为数据库zabbix用户的密码
MYSQL_ROOT_PASS='123456'                 #修改为数据库的root密码
修改后脚本会自动执行数据库的安装、配置、以及导入
```

##### 服务端

```bash
上传文件install_config_zabbix5.0_without_DBserver.sh到准备安装zabbix5.0服务端的服务器
执行前修改脚本变量
MYSQL_HOST=172.16.128.15                #修改为数据库的IP地址
MYSQL_ZABBIX_USER="zabbix@'%'"          #修改为数据库zabbix的用户名称
MYSQL_ZABBIX_PASS='123456'              #修改为数据库zabbix用户的密码
MYSQL_ROOT_PASS='123456'                #修改为数据库的root密码
```

##### 服务端web初始化

```html
在web初始化界面注意如下事项：
填写数据库服务器的IP地址和zabbix数据库的用户名和密码
在CentOS7系列的版本中不要勾选TLS加密连接，其余保持默认即可
因CentOS7系列的版本的版本使用的是MySQL5的版本，CentOS8系列的系统使用的是MySQL8的版本，不存在以下问题
```

#### 2.2LTS6.0版本

##### 数据库

```bash
先在任意服务器执行install_config_zabbix6.0_dbserver.sh
执行前修改脚本变量
MYSQL_ZABBIX_USER="zabbix@'%'"           #修改为数据库zabbix的用户名称
MYSQL_ZABBIX_PASS='123456'               #修改为数据库zabbix用户的密码
MYSQL_ROOT_PASS='123456'                 #修改为数据库的root密码
修改后脚本会自动执行数据库的安装、配置、以及导入
```

##### 服务端

```bash
上传文件install_config_zabbix6.0_without_DBserver.sh到准备安装zabbix6.0服务端的服务器
执行前修改脚本变量
MYSQL_HOST=172.16.128.15                #修改为数据库的IP地址
MYSQL_ZABBIX_USER="zabbix@'%'"          #修改为数据库zabbix的用户名称
MYSQL_ZABBIX_PASS='123456'              #修改为数据库zabbix用户的密码
MYSQL_ROOT_PASS='123456'                #修改为数据库的root密码
```

##### 服务端web初始化

```html
在web初始化界面注意如下事项：
填写数据库服务器的IP地址和zabbix数据库的用户名和密码，其余保持默认即可
```

### 3.客户端

运行脚本前需要自定义服务端的IP或者域名，需要修改脚本的第14行

```bash
ZABBIX_SERVER=zabbix.li.org
ZABBIX_SERVER=172.16.1.25
```

Agent与agent2对比

```html
https://www.zabbix.com/documentation/5.0/zh/manual/appendix/agent_comparison
```

下载地址

```html
https://www.zabbix.com/download
```

