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

# 创建topic
kafka-topics.sh --create --replication-factor 1 --partitions 1 --topic test

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
# 创建3副本，3分区的Topic
kafka-topics.sh --create --zookeeper 10.0.0.11:2181 --replication-factor 3 --partitions 3 --topic mytest

# 查看Topic
kafka-topics.sh --describe --zookeeper 10.0.0.11:2181 --topic mytest
Topic: mytest	TopicId: V53dtJUDSYqZTxC8N2kj5w	PartitionCount: 3	ReplicationFactor: 3	Configs:
	Topic: mytest	Partition: 0	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: mytest	Partition: 1	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: mytest	Partition: 2	Leader: 0	Replicas: 0,1,2	Isr: 0,1,2

# 生产者
kafka-console-producer.sh --broker-list 10.0.0.11:9092,10.0.0.11:9093,10.0.0.11:9094 --topic mytest

# 消费者
kafka-console-consumer.sh --bootstrap-server 10.0.0.11:9092,10.0.0.11:9093,10.0.0.11:9094 --from-beginning --topic mytest

```



```shell

Kafka提供了多种API操作，下面是一些常用的命令：

1. 创建主题(topic)：`docker exec kafka1 kafka-topics.sh --create --zookeeper zk1:2181 --replication-factor 1 --partitions 1 --topic test_topic`

2. 查看主题列表：`docker exec kafka1 kafka-topics.sh --list --zookeeper zk1:2181`

3. 发送消息：`docker exec kafka1 kafka-console-producer.sh --broker-list localhost:9092 --topic test_topic`

4. 消费消息：`docker exec kafka1 kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test_topic --from-beginning`

5. 查看分区信息：`docker exec kafka1 kafka-topics.sh --describe --zookeeper zk1:2181 --topic test_topic`

6. 删除主题：`docker exec kafka1 kafka-topics.sh --delete --zookeeper zk1:2181 --topic test_topic`

7. 修改主题配置：`docker exec kafka1 kafka-configs.sh --zookeeper zk1:2181 --entity-type topics --entity-name test_topic --alter --add-config max.message.bytes=64000`

8. 查看消费者组信息：`docker exec kafka1 kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group test_group`

9. 重置消费者偏移量：`docker exec kafka1 kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group test_group --reset-offsets --to-earliest --execute --topic test_topic`
```

这些命令只是常用的一部分，Kafka还提供了更多的API操作，您可以查看Kafka文档来了解更多信息。







https://gitee.com/bright-boy/technical-notes/blob/master/study-notes/kafka/kafka.md#%E4%B8%80kafka%E4%BB%8B%E7%BB%8D

https://blog.csdn.net/qq_39938758/article/details/108047840



https://www.jianshu.com/p/bacc8eb03c4b/



