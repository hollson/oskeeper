



```shell
# 下载镜像
$ docker pull mysql:latest
$ sudo mkdir -p /opt/mysql


# 最新版本
sudo docker run -d -p 3306:3306 \
--privileged=true \
--restart=unless-stopped \
-v ${HOME}:/home \
-v /opt/mysql/conf:/etc/my.cnf.d \
-v /opt/mysql/logs:/var/log/mysql \
-v /opt/mysql/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=123456 \
--name mysqldb \
mysql:latest


# 启动Mysql容器(Airacer版本)
docker run -d -p 3306:3306 \
--privileged=true \
--restart=always \
-v ${HOME}:/home \
-v /opt/mysql/conf/my.cnf:/etc/mysql/my.cnf \
-v /opt/mysql/logs:/logs \
-v /opt/mysql/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=123456 \
--name mysqldb \
mysql:8.0.36


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



