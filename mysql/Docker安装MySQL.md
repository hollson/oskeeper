



```shell
# 下载镜像
$ docker pull mysql:latest

# 挂载数据目录
$ export MY_VOLUME=$HOME/data/mysql

# 启动Mysql容器(Airacer版本)
sudo docker run -d -p 3306:3306 \
--privileged=true \
--restart=unless-stopped \
-v /opt/mysql/conf:/etc/my.cnf.d \
-v /opt/mysql/logs:/var/log/mysql \
-v /opt/mysql/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=123456 \
--name mysqldb \
mysql:8.0.36

# 最新版本
sudo docker run -d -p 3306:3306 \
--privileged=true \
--restart=unless-stopped \
-v /opt/mysql/conf:/etc/my.cnf.d \
-v /opt/mysql/logs:/var/log/mysql \
-v /opt/mysql/data:/var/lib/mysql \
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



