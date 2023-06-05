
4lw.commands.whitelist=stat
The Four Letter Words

docker-compose -f docker-compose-zookeeper-cluster.yml down
#docker-compose -f docker-compose-zookeeper-cluster.yml build
docker-compose -f docker-compose-zookeeper-cluster.yml up -d


输入 ​mntr​命令，查看所有节点的服务状态

echo ruok | nc 127.0.0.1 2184
echo stat | nc 127.0.0.1 2182
echo connf | nc 127.0.0.1 2182
echo mntr | nc 127.0.0.1 2182|grep state





https://zhuanlan.zhihu.com/p/110677319
https://blog.csdn.net/a1053765496/article/details/127877009

https://blog.csdn.net/Gusand/article/details/104336646




```shell
以下是一些常用的Docker Compose命令：

1. 启动Compose文件中的所有服务：`docker-compose up -d`

2. 启动Compose文件中的指定服务：`docker-compose up -d <service_name>`

3. 停止Compose文件中的所有服务：`docker-compose stop`

4. 停止Compose文件中的指定服务：`docker-compose stop <service_name>`

5. 重启Compose文件中的所有服务：`docker-compose restart`

6. 重启Compose文件中的指定服务：`docker-compose restart <service_name>`

7. 更新Compose文件中的配置：`docker-compose build`

8. 删除Compose文件中的所有服务、网络和卷：`docker-compose down`

9. 删除Compose文件中的指定服务、网络和卷：`docker-compose down <service_name>`

10. 查看Compose文件中的所有服务状态：`docker-compose ps`

11. 查看Compose文件中的指定服务状态：`docker-compose ps <service_name>`

请注意，以上命令中的`<service_name>`应替换为Compose文件中要操作的服务的名称。
```