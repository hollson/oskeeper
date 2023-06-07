# 一.Kafka 基础知识

## 1.1 什么是 Kafka

　　Kafka是最初由Linkedin公司开发，是一个分布式、支持分区的（partition）、多副本的  （replica），基于zookeeper协调的分布式消息系统，它的最大的特性就是可以实时的处理  大量数据以满足各种需求场景：比如基于hadoop的批处理系统、低延迟的实时系统、  Storm/Spark流式处理引擎，web/nginx日志、访问日志，消息服务等等，用scala语言编写，Linkedin于2010年贡献给了Apache基金会并成为顶级开源项目。



## 1.2 Kafka 应用场景

- 日志收集：一个公司可以用Kafka收集各种服务的log，通过kafka以统一接口服务的方式开放给各种consumer，例如hadoop、Hbase、Solr等。
- 消息系统：解耦和生产者和消费者、缓存消息等。
- 用户活动跟踪：Kafka经常被用来记录web用户或者app用户的各种活动，如浏览网⻚、搜索、点击等活动，这些活动信息被各个服务器发布到kafka的topic中，然后订阅者通过订阅这些topic来做实时的监控分析，或者装载到hadoop、数据仓库中做离线分析和挖掘。
- 运营指标：Kafka也经常用来记录运营监控数据。包括收集各种分布式应用的数据，生产各种操作的集中反馈，比如报警和报告。



| 特性         | Kafka      | RabbitMQ       | RocketMQ    | ActiveMQ  | ZeroMQ |
| ------------ | ---------- | -------------- | ----------- | --------- | ------ |
| 开发语言      | Scala/Java | Erlang         | Java        | Java      | C++    |
| 消息传输模型   | **Pub/Sub** | AMQP           | TCP协议     | JMS       | Socket |
| 消息持久化     | 可选        | 是             | 是          | 是        | 否     |
| 集群管理      | ZooKeeper | 必须依赖Erlang  | 自带Namesrv | ZooKeeper | 无     |
| 性能         | 非常高      || 高              高          | 一般      | 非常高 |
| 可靠性        | 可靠       | 非常可靠        | 非常可靠    | 可靠      | 不可靠 |
| 社区活跃度     | 非常高       | 较高           | 较高        | 较高      | 较高   |



## 1.3 Kafka 基础架构

**点对点消息系统**

![](http://www.yiibai.com/uploads/images/201803/1203/557140303_65226.jpg)

**发布-订阅消息系统**

![](http://www.yiibai.com/uploads/images/201803/1203/432140304_23172.jpg)







经典案例- 登录，订单处理











# 二. Kafka 安装配置

学习如何安装和配置Kafka环境，包括Zookeeper、Kafka Broker和Kafka Producer/Consumer等组件。

## 2.1 Kafka单机安装



## 2.2 Kafka集群部署



## 2.3 Kafka容器部署

推荐

```yaml
# 文件名： docker-compose-kafka-cluster.yml
# docker-compose -f docker-compose-kafka-cluster.yml down
# docker-compose -f docker-compose-kafka-cluster.yml up -d

version: "3.7"

networks:
  docker_net:
    external: true

services:
  kfk1:
    image: wurstmeister/kafka
    restart: unless-stopped
    container_name: kfk1
    ports:
      - "19092:9092"
    external_links:
      - zk1
      - zk2
      - zk3
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ADVERTISED_HOST_NAME: 192.168.2.3 ## 修改:宿主机IP
      KAFKA_ADVERTISED_PORT: 19092 ## 修改:宿主机映射port
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://192.168.2.3:19092 ## 绑定发布订阅的端口。修改:宿主机IP
      KAFKA_ZOOKEEPER_CONNECT: "zk1:2181,zk2:2181,zk3:2181"
    volumes:
      - "./.data/kfk1/docker.sock:/var/run/docker.sock"
      - "./.data/kfk1/data/:/kafka"
    networks:
      - docker_net

  kfk2:
    image: wurstmeister/kafka
    restart: unless-stopped
    container_name: kfk2
    ports:
      - "19093:9092"
    external_links:
      - zk1
      - zk2
      - zk3
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ADVERTISED_HOST_NAME: 192.168.2.3 ## 修改:宿主机IP
      KAFKA_ADVERTISED_PORT: 19093 ## 修改:宿主机映射port
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://192.168.2.3:19093 ## 修改:宿主机IP
      KAFKA_ZOOKEEPER_CONNECT: "zk1:2181,zk2:2181,zk3:2181"
    volumes:
      - "./.data/kfk2/docker.sock:/var/run/docker.sock"
      - "./.data/kfk2/data/:/kafka"
    networks:
      - docker_net

  kfk3:
    image: wurstmeister/kafka
    restart: unless-stopped
    container_name: kfk3
    ports:
      - "19094:9092"
    external_links:
      - zk1
      - zk2
      - zk3
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ADVERTISED_HOST_NAME: 192.168.2.3 ## 修改:宿主机IP
      KAFKA_ADVERTISED_PORT: 19094 ## 修改:宿主机映射port
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://192.168.2.3:19094 ## 修改:宿主机IP
      KAFKA_ZOOKEEPER_CONNECT: "zk1:2181,zk2:2181,zk3:2181"
    volumes:
      - "./.data/kfk3/docker.sock:/var/run/docker.sock"
      - "./.data/kfk3/data/:/kafka"
    networks:
      - docker_net

  # 可视化工具1
  kafka-manager:
    image: sheepkiller/kafka-manager:latest
    restart: unless-stopped
    container_name: kafka-manager
    hostname: kafka-manager
    ports:
      - "9000:9000"
    links: # 连接本compose文件创建的container
      - kfk1
      - kfk2
      - kfk3
    external_links: # 连接本compose文件以外的container
      - zk1
      - zk2
      - zk3
    environment:
      ZK_HOSTS: zk1:2181,zk2:2181,zk3:2181 ## 修改:宿主机IP
      TZ: CST-8
    networks:
      - docker_net
```





## 2.4 测试





# 三. Kafka 核心概念

> 假设有一个电商系统，用户可以购买商品，下单后进行支付，然后等待发货。在这个过程中，Kafka充当了什么角色呢？

## 3.1 Topic (主题)

> 可以将不同类型的消息归为不同的主题，例如订单消息、支付消息和物流消息等。

### 3.1.1 顺序存储

　　生产者把消息发送到broker中，消息会 **按顺序进行存储**。因此消费者在读取消息时可指明消息的**偏移量**。

### 3.1.2 单播消息

> 单播消息：一个消费组里 只会有一个消费者能消费到某一个topic中的消息。于是可以创建多个消费者，这些消费者在同一个消费组中。

```
./kafka-console-consumer.sh --bootstrap-server 10.31.167.10:9092 --consumer-property group.id=testGroup --topic test
```

### 3.1.3 多播消息

在一些业务场景中需要让一条消息被多个消费者消费，那么就可以使用多播模式。

kafka实现多播，只需要让不同的消费者处于不同的消费组即可。

```
./kafka-console-consumer.sh --bootstrap-server 10.31.167.10:9092 --consumer-property group.id=testGroup1 --topic test

./kafka-console-consumer.sh --bootstrap-server 10.31.167.10:9092 --consumer-property group.id=testGroup2 --topic test
```

### 3.1.4 消费者组

```
# 查看当前主题下有哪些消费组
./kafka-consumer-groups.sh --bootstrap-server 10.31.167.10:9092 --list
# 查看消费组中的具体信息：比如当前偏移量、最后一条消息的偏移量、堆积的消息数量
./kafka-consumer-groups.sh --bootstrap-server 172.16.253.38:9092 --describe --group testGroup
```

![输入图片说明](https://gitee.com/bright-boy/technical-notes/raw/master/study-notes/kafka/images/QQ%E6%88%AA%E5%9B%BE20220110125233.png)

- Currennt-offset: 当前消费组的已消费偏移量
- Log-end-offset: 主题对应分区消息的结束偏移量(HW)
- Lag: 当前消费组未消费的消息数





## 3.2 Partition (分区）

> 每个主题可以被分成多个分区，例如订单消息可以按照不同的地区或者时间进行分区。



## 3.3 Offset (偏移量)

> 每个分区里面的消息都有一个偏移量，用来记录这个分区里面的消息发送和接收情况。



## 3.4 Producer (生产者)

> 当用户下单后，订单服务可以作为生产者将订单消息发送到Kafka中。



## 3.5 Consumer (消费者)

> 支付服务和物流服务可以作为消费者从Kafka中接收订单消息，并进行相应的处理。



## Consumer Group (消费者组)

> 支付服务和物流服务可以组成一个消费者组，一起接收订单消息，提高消息处理效率。





## 3.6 Broker (代理)

> Kafka集群中的Broker节点就像是邮局，负责把消息从生产者传递给消费者。

> Kafka集群中包含的服务器，有一个或多个服务器，这种服务器被称为 Broker。
>
> Broker 端不维护数据的消费状态，提升了性能。直接使用磁盘进行存储，线性读写，速度快。避免了在JVM 内存和系统内存之间的复制，减少耗性能的创建对象和垃圾回收。



## 3.7Leader和Follower

每个分区都会有一个领导者，它负责处理这个分区的消息。例如订单消息分区中的领导者可以负责处理这个分区里面的所有订单消息。



每个分区还会有一些跟随者，它们负责备份领导者的消息。例如订单消息分区中的跟随者可以负责备份领导者的订单消息，确保消息不会丢失。





# 四. Kafka Api应用

学习Kafka提供的API，包括Java API、Scala API和Python API等。



**实战SSL**





# 五.Kafka 实践案例

通过实践一些Kafka案例，例如Kafka消息发送和接收、Kafka消息分区、Kafka消息消费者组等，来加深对Kafka的理解。



# 六.Kafka 高级特性

## 6.1 Kafka事务

分布式事务





## 6.2 Kafka Connect



## 6.3 Kafka Streams



# 七.Kafka 运维监控

学习如何进行Kafka的运维和监控，包括Kafka集群的部署和管理、Kafka Broker的故障处理、Kafka消息的监控和性能调优等。





# 八. Kafka 常见问题



## 8.1 如何防止消息丢失

- 发送方： ack是`1`或者`-1/all`可以防止消息丢失，如果要做到99.9999%，ack设成all，把`min.insync.replicas`配置成分区备份数
- 消费方：把自动提交改为手动提交。



## 8.2 如何防止重复消费

> 一条消息被消费者消费多次。如果为了消息的不重复消费，而把生产端的重试机制关闭、消费端的手动提交改成自动提交，这样反而会出现消息丢失，那么可以直接在防治消息丢失的手段上再加上消费消息时的幂等性保证，就能解决消息的重复消费问题。



幂等性如何保证：

- mysql 插入业务id作为主键，主键是唯一的，所以一次只能插入一条
- 使用redis或zk的分布式锁（主流的方案）



## 8.3 如何做到顺序消费

- 发送方：在发送时将ack不能设置 0 ，关闭重试，使用同步发送，等到发送成功再发送下一条。确保消息是顺序发送的。
- 接收方：消息是发送到一个分区中，只能有一个消费组的消费者来接收消息。因此，kafka的顺序消费会牺牲掉性能。



## 8.4 解决消息积压问题

> 消息积压会导致很多问题，比如磁盘被打满、生产端发消息导致kafka性能过慢，就容易出现服务雪崩，就需要有相应的手段：

- 方案一：在一个消费者中启动多个线程，让多个线程同时消费。——提升一个消费者的消费能力（增加分区增加消费者）。
- 方案二：如果方案一还不够的话，这个时候可以启动多个消费者，多个消费者部署在不同的服务器上。其实多个消费者部署在同一服务器上也可以提高消费能力——充分利用服务器的cpu资源。
- 方案三：让一个消费者去把收到的消息往另外一个topic上发，另一个topic设置多个分区和多个消费者 ，进行具体的业务消费。



## 8.5 如何解决延迟队列

> 延迟队列的应用场景：在订单创建成功后如果超过 30 分钟没有付款，则需要取消订单，此时可用延时队列来实现

- 创建多个topic，每个topic表示延时的间隔
    - topic_5s: 延时5s执行的队列
    - topic_1m: 延时 1 分钟执行的队列
    - topic_30m: 延时 30 分钟执行的队列
- 消息发送者发送消息到相应的topic，并带上消息的发送时间
- 消费者订阅相应的topic，消费时轮询消费整个topic中的消息
    - 如果消息的发送时间，和消费的当前时间超过预设的值，比如 30 分钟
    - 如果消息的发送时间，和消费的当前时间没有超过预设的值，则不消费当前的offset及之后的offset的所有消息都消费
    - 下次继续消费该offset处的消息，判断时间是否已满足预设值
