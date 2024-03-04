



```shell
# 下载镜像
$ docker pull mysql:latest

# 挂载数据目录
$ export MY_VOLUME=$HOME/data/mysql

# 启动Mysql容器
$ docker run -d -p 3306:3306 \
-v $MY_VOLUME/data:/mysql_data \
-v $MY_VOLUME/conf/my.cnf:/etc/mysql/my.cnf \
-v $MY_VOLUME/logs:/logs \
-e MYSQL_ROOT_PASSWORD=123456 \
--name mysqldb \
mysql:latest

# 查看Mysql版本
$ docker exec -ti mysqldb mysql -uroot -p123456 -e "select @@version;"
+-----------+
| @@version |
+-----------+
| 8.3.0     |
+-----------+

# 删除容器
$ docker rm -f mysqldb
```

https://hub.docker.com/_/mysql



