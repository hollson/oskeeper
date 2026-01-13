### zabbix脚本化安装注意事项

### 1.一体化安装部署

#### 1.1.运行脚本前

在执行脚本前，需要将本地电脑的微软雅黑字体上传到于脚本在同一个目录

微软雅黑字体在C:\Windows\Fonts

名称：（以Windows10为例）

```html
msyh.ttc
msyhbd.ttc
msyhl.ttc
```

上传完毕后增加执行权限，运行脚本

#### 1.2.运行脚本后

6.0LTS和5.0LTS版本，脚本执行完毕后运行以下参数，无需重启服务和操作系统以及数据库

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

