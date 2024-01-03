etcdutl
========

> etcdutl 提供了一些额外的功能，如**性能测试**、**备份/恢复**等。比 etcdctl 更灵活，可使用更多的高级功能。

_🤮: etcd的官方文档与实际功能有大量的不同步,请以实际情况。_



## DEFRAG

对etcd数据目录进行**碎片整理**。

```shell
# 须在etcd未运行时进行碎片整理
etcdutl defrag --data-dir default.etcd
```

​    

## SNAPSHOT

SNAPSHOT RESTORE 根据后端数据库快照和新的集群配置为 etcd 集群成员创建一个 etcd 数据目录。  将快照恢复到新集群配置的每个成员中将初始化由快照数据预加载的新 etcd 集群。 

- data-dir -- 数据目录的路径。  如果没有给出，则使用 <name>.etcd。 
- wal-dir -- WAL 目录的路径。  如果没有给出，则使用数据目录。 
- 初始集群——恢复的 etcd 集群的初始集群配置。 
- 初始集群令牌——已恢复的 etcd 集群的初始集群令牌。 
- initial-advertise-peer-urls -- 正在恢复的成员的对等 URL 列表。 
- name -- 正在恢复的 etcd 集群成员的人类可读名称。 
- Skip-hash-check -- 忽略快照完整性哈希值（如果从数据目录复制则需要） 
- Bump-re vision -- 恢复后最新版本增加多少 
- mark-compacted -- 将恢复后的最新版本标记为计划压缩点（如果 --bump-revision > 0 则需要，否则不允许） 

#### 例子 

保存快照，恢复到新的 3 节点集群，然后启动集群： 

```shell
# save snapshot
etcdctl snapshot save snapshot.db

# 数据备份
ROOT="${HOME}/tmp/etcd"
etcdctl snapshot save ${ROOT}/backup/$(date +'%Y%m%d%H%M').db


# restore members
etcdutl snapshot restore snapshot.db --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls http://127.0.0.1:12380  --name sshot1 --initial-cluster 'sshot1=http://127.0.0.1:12380,sshot2=http://127.0.0.1:22380,sshot3=http://127.0.0.1:32380'

etcdutl snapshot restore snapshot.db --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls http://127.0.0.1:22380  --name sshot2 --initial-cluster 'sshot1=http://127.0.0.1:12380,sshot2=http://127.0.0.1:22380,sshot3=http://127.0.0.1:32380'

etcdutl snapshot restore snapshot.db --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls http://127.0.0.1:32380  --name sshot3 --initial-cluster 'sshot1=http://127.0.0.1:12380,sshot2=http://127.0.0.1:22380,sshot3=http://127.0.0.1:32380'

# launch members
etcd --name sshot1 --listen-client-urls http://127.0.0.1:2379 --advertise-client-urls http://127.0.0.1:2379 --listen-peer-urls http://127.0.0.1:12380 &

etcd --name sshot2 --listen-client-urls http://127.0.0.1:22379 --advertise-client-urls http://127.0.0.1:22379 --listen-peer-urls http://127.0.0.1:22380 &

etcd --name sshot3 --listen-client-urls http://127.0.0.1:32379 --advertise-client-urls http://127.0.0.1:32379 --listen-peer-urls http://127.0.0.1:32380 &
```

   

SNAPSHOT STATUS 列出有关给定后端数据库快照文件的信息。  

```shell
etcdutl snapshot status file.db
# cf1550fb, 3, 3, 25 kB
```

```shell
etcdutl --write-out=json snapshot status file.db
# {"hash":3474280699,"revision":3,"totalKey":3,"totalSize":24576}
```

```shell
etcdutl --write-out=table snapshot status file.db
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| cf1550fb |        3 |          3 | 25 kB      |
+----------+----------+------------+------------+
```

​    

## VERSION

```shell
./etcdutl version
# etcdutl version: 3.5.0
# API version: 3.1
```

   

