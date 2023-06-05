以下是一个 Redis 集群 Docker Compose 文件示例，其中包含 6 个 Redis 节点。这个示例使用了 Redis 官方提供的 `redis:6.2.4` 镜像，并使用了 Redis Sentinel 来实现高可用性：

```
version: '3'

services:
  redis-master:
    image: redis:6.2.4
    command: redis-server --requirepass password --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - redis-master-data:/data
    networks:
      redis-net:

  redis-slave1:
    image: redis:6.2.4
    command: redis-server --slaveof redis-master 6379 --masterauth password --appendonly yes
    volumes:
      - redis-slave1-data:/data
    networks:
      redis-net:

  redis-slave2:
    image: redis:6.2.4
    command: redis-server --slaveof redis-master 6379 --masterauth password --appendonly yes
    volumes:
      - redis-slave2-data:/data
    networks:
      redis-net:

  redis-sentinel1:
    image: redis:6.2.4
    command: redis-sentinel /usr/local/etc/redis/sentinel.conf
    volumes:
      - sentinel1-conf:/usr/local/etc/redis/sentinel.conf
    ports:
      - "26379:26379"
    networks:
      redis-net:

  redis-sentinel2:
    image: redis:6.2.4
    command: redis-sentinel /usr/local/etc/redis/sentinel.conf
    volumes:
      - sentinel2-conf:/usr/local/etc/redis/sentinel.conf
    ports:
      - "26380:26379"
    networks:
      redis-net:

  redis-sentinel3:
    image: redis:6.2.4
    command: redis-sentinel /usr/local/etc/redis/sentinel.conf
    volumes:
      - sentinel3-conf:/usr/local/etc/redis/sentinel.conf
    ports:
      - "26381:26379"
    networks:
      redis-net:

networks:
  redis-net:

volumes:
  redis-master-data:
  redis-slave1-data:
  redis-slave2-data:
  sentinel1-conf:
  sentinel2-conf:
  sentinel3-conf:
```

在这个示例中，我们定义了 1 个 Redis 主节点、2 个 Redis 从节点和 3 个 Redis Sentinel 节点。每个 Redis 节点都使用了 `redis:6.2.4` 镜像，并指定了不同的角色和参数。

此外，我们创建了一个名为 `redis-net` 的 Docker 网络，并将所有 Redis 节点连接到该网络。我们还定义了一些数据卷，用于持久化 Redis 数据和 Sentinel 配置文件等数据。

注意，这只是一个简单的示例文件，实际生产环境中可能需要更多的配置和参数。你可以根据自己的需求进行修改和扩展。