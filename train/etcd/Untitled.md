以下是一个简单的 etcd 集群 Docker Compose 文件示例，其中包含 3 个 etcd 节点：

```
version: '3'

services:
  etcd1:
    image: quay.io/coreos/etcd:v3.4.14
    command: etcd --name etcd1 --initial-advertise-peer-urls http://etcd1:2380 --listen-peer-urls http://0.0.0.0:2380 --advertise-client-urls http://etcd1:2379 --listen-client-urls http://0.0.0.0:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380 --initial-cluster-state new
    ports:
      - "2379:2379"
      - "2380:2380"
    networks:
      etcd-net:
        ipv4_address: 172.20.0.2

  etcd2:
    image: quay.io/coreos/etcd:v3.4.14
    command: etcd --name etcd2 --initial-advertise-peer-urls http://etcd2:2380 --listen-peer-urls http://0.0.0.0:2380 --advertise-client-urls http://etcd2:2379 --listen-client-urls http://0.0.0.0:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380 --initial-cluster-state new
    ports:
      - "2379:2379"
      - "2380:2380"
    networks:
      etcd-net:
        ipv4_address: 172.20.0.3

  etcd3:
    image: quay.io/coreos/etcd:v3.4.14
    command: etcd --name etcd3 --initial-advertise-peer-urls http://etcd3:2380 --listen-peer-urls http://0.0.0.0:2380 --advertise-client-urls http://etcd3:2379 --listen-client-urls http://0.0.0.0:2379 --initial-cluster-token etcd-cluster-1 --initial-cluster etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380 --initial-cluster-state new
    ports:
      - "2379:2379"
      - "2380:2380"
    networks:
      etcd-net:
        ipv4_address: 172.20.0.4

networks:
  etcd-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

在这个示例中，我们定义了 3 个 etcd 节点，分别命名为 `etcd1`、`etcd2` 和 `etcd3`。每个节点都使用了 `quay.io/coreos/etcd:v3.4.14` 镜像，并指定了不同的节点名称、地址和端口等参数。

此外，我们创建了一个名为 `etcd-net` 的 Docker 网络，并配置了 IP 地址范围为 `172.20.0.0/16`。每个 etcd 节点都连接到该网络，并分配了一个唯一的 IP 地址。

注意，这只是一个简单的示例文件，实际生产环境中可能需要更多的配置和参数。你可以根据自己的需求进行修改和扩展。