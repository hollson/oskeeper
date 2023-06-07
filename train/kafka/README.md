### Broker

```shell
# 查看broker列表
zookeeper-shell.sh zk1:2181,zk2:2181,zk3:2181 ls /brokers/ids

# 查看broker详情
zookeeper-shell.sh zk1:2181,zk2:2181,zk3:2181 get /brokers/ids/<broker-id>
```



### Topic

```shell
# 配置命令别名
alias kafka-topics.sh='kafka-topics.sh --zookeeper zk1:2181,zk2:2181,zk3:2181'
alias kafka-configs.sh='kafka-configs.sh --zookeeper zk1:2181,zk2:2181,zk3:2181'

# 查看topic列表
kafka-topics.sh --list

# 创建topic(3个副本3个分区)
kafka-topics.sh --create --replication-factor 3 --partitions 3 --topic test

# 查看topic详情
kafka-topics.sh --describe --topic test

# 删除topic
kafka-topics.sh --delete --topic test

# 修改topic配置(修改消息最大字节数)
kafka-configs.sh --entity-type topics --entity-name test --alter --add-config max.message.bytes=64000
```



### Message

```shell
# 生产者发送消息
kafka-console-producer.sh --broker-list kfk1:9092,kfk2:9092,kfk3:9092 --topic test

# 消费者消费消息
kafka-console-consumer.sh --bootstrap-server kfk1:9092 --topic test --from-beginning
kafka-console-consumer.sh --bootstrap-server kfk2:9092 --topic test --from-beginning
kafka-console-consumer.sh --bootstrap-server kfk1:9092,kfk2:9092 --topic test --from-beginning ?

# 查看消费者组信息
kafka-consumer-groups.sh --bootstrap-server kfk1:9092 --list

# 查看消费者组消费详情
kafka-consumer-groups.sh --bootstrap-server kfk1:9092 --group test-group --describe
```



```shell
kafka-topics.sh --create --replication-factor 1 --partitions 2 --topic testA
kafka-topics.sh --create --replication-factor 2 --partitions 2 --topic testB
kafka-topics.sh --create --replication-factor 3 --partitions 3 --topic testC

kafka-topics.sh --describe --topic testA
kafka-topics.sh --describe --topic testB
kafka-topics.sh --describe --topic testC
```



## 在Docker Compose读取命令行参数和环境变量。

1. 读取命令行参数

可以使用`${VAR_NAME}`语法来读取命令行参数，其中`VAR_NAME`是命令行参数的名称。例如，假设我们有一个`docker-compose.yml`文件，需要在启动时传递一个`PORT`参数，可以在命令行中使用以下命令：

```
docker-compose up --build --port=8080
```

然后，在`docker-compose.yml`文件中可以使用`${PORT}`语法来读取这个参数，例如：

```yaml
version: '3'
services:
  web:
    build: .
    ports:
      - "${PORT}:80"
```

这样就可以将命令行传递的端口号赋值给`web`服务的端口号。

2. 读取环境变量

可以使用`${ENV_VAR}`语法来读取环境变量，其中`ENV_VAR`是环境变量的名称。例如，假设我们有一个环境变量`DB_PASSWORD`，可以在`docker-compose.yml`文件中使用以下语法来读取这个变量：

```yaml
version: '3'
services:
  db:
    image: mysql
    environment:
      MYSQL_ROOT_PASSWORD: "${DB_PASSWORD}"
```

这样就可以将环境变量`DB_PASSWORD`的值作为MySQL的root密码。

如果环境变量不存在，可以使用`${VAR_NAME:-default}`语法来设置默认值，例如：

```yaml
version: '3'
services:
  web:
    build: .
    environment:
      APP_PORT: "${PORT:-8080}"
    ports:
      - "${APP_PORT}:80"
```

这样，如果没有传递`PORT`参数，就会使用默认值`8080`来作为`APP_PORT`环境变量的值。









https://gitee.com/bright-boy/technical-notes/blob/master/study-notes/kafka/kafka.md#%E4%B8%80kafka%E4%BB%8B%E7%BB%8D

https://blog.csdn.net/qq_39938758/article/details/108047840



https://www.jianshu.com/p/bacc8eb03c4b/



