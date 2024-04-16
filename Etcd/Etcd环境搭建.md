## 一. 单机安装

> 具体安装过程可参考[ETCD官方文档](https://etcd.io/docs/v3.6/)


### MacOS
```shell
# 下载
ETCD_VER=v3.6.0
ETCD_URL=https://github.com/etcd-io/etcd/releases/download
curl -LO ${ETCD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-darwin-amd64.zip
unzip etcd-${ETCD_VER}-darwin-amd64.zip

# 安装
sudo mkdir -p /usr/local/etcd
sudo mv ./etcd-${ETCD_VER}-darwin-amd64/etcd* /usr/local/etcd
sudo ln -s /usr/local/etcd/etcd /usr/local/bin/etcd
sudo ln -s /usr/local/etcd/etcdctl /usr/local/bin/etcdctl
sudo ln -s /usr/local/etcd/etcdutl /usr/local/bin/etcdutl

# 启动进程
cd ${HOME} && mkdir default.etcd
nohup etcd > ./default.etcd/etcd.log 2>&1 &
```

### Linux

```bash
# 下载
ETCD_VER=v3.6.0
ETCD_URL=https://github.com/etcd-io/etcd/releases/download
wget -L ${ETCD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf ./etcd-${ETCD_VER}-linux-amd64.tar.gz

# 安装
mkdir -p /usr/local/etcd
mv ./etcd-${ETCD_VER}-linux-amd64/etcd* /usr/local/etcd
ln -s /usr/local/etcd/etcd /usr/local/bin/etcd
ln -s /usr/local/etcd/etcdctl /usr/local/bin/etcdctl
ln -s /usr/local/etcd/etcdutl /usr/local/bin/etcdutl

# 启动进程
cd /opt && mkdir default.etcd
nohup etcd > ./default.etcd/etcd.log 2>&1 &
```

### Docker

```shell
docker network create app-tier --driver bridge

docker run -d --name etcd \
    --network app-tier \
    --publish 2379:2379 \
    --publish 2380:2380 \
    --env ALLOW_NONE_AUTHENTICATION=yes \
    --env ETCD_ADVERTISE_CLIENT_URLS=http://etcd-server:2379 \
    bitnami/etcd:latest
```



```shell
mkdir -p /var/etcd-data-docker
ETCD_VER=v3.5.11
TOKEN=$(uuidgen)

## 单实例集群
docker run \
 --name etcd -p 2379:2379 -p 2380:2380 \
 --mount type=bind,source=/var/etcd-data-docker,destination=/etcd-data \
 quay.io/coreos/etcd:v3.4.4 /usr/local/bin/etcd \
 --name "etcd-01" \
 --data-dir /var/etcd-data \
 --listen-client-urls http://0.0.0.0:2379 \
 --advertise-client-urls http://0.0.0.0:2379 \
 --listen-peer-urls http://0.0.0.0:2380 \
 --initial-advertise-peer-urls http://0.0.0.0:2380 \
 --initial-cluster "etcd-01"=http://0.0.0.0:2380 \
 --initial-cluster-token ${TOKEN} \
 --initial-cluster-state new \
 --log-level info \
 --logger zap \
 --log-outputs stderr

$ docker exec etcd /bin/sh -c "etcd --version"
$ docker exec etcd /bin/sh -c "etcdctl version"
$ docker exec etcd /bin/sh -c "etcdutl version"
$ docker exec etcd /bin/sh -c "etcdctl endpoint health"
$ docker exec etcd /bin/sh -c "etcdctl put foo 'hello world'"
$ docker exec etcd /bin/sh -c "etcdctl get foo"  
```



```shell
# 启动Etcd服务
ROOT="${HOME}/tmp/etcd"
etcd --listen-client-urls=http://localhost:2379,http://localhost:4001 \
--advertise-client-urls=http://localhost:2379,http://localhost:4001 \
--data-dir=${ROOT}/data \
# --config-file=${ROOT}/config/etcd.conf \
--log-output=${ROOT}/logs/etcd.log
```

_**客户端测试：**_
```shell
# 查看版本
etcd --version
etcdctl version
etcdutl version

# 数据测试
curl 127.0.0.1:2379/version
etcdctl --endpoints=localhost:2379 put hello "Hello World"
etcdctl --endpoints=localhost:2379 get hello
```



## 三. ETCD配置

Etcd服务的参数包括`Member`、`Cluster`、`Security`、`Auth`、`Logging`、`Profiling`等模块。

```shell
$ etcd --help #查看帮助(不同版本的帮助文档有差异)
$ etcd --help| awk 'BEGIN {RS = "";ORS = "\n\n"} /Member/ {print $0}' #Member配置
$ etcd --help| awk 'BEGIN {RS = "";ORS = "\n\n"} /Cluster/ {print $0}' #Cluster配置
...
```



**Ymal文件配置**

```shell
[root@shs ~]# vim /etc/etcd.yml
```
```yml
name: "etcd-01"
data-dir: "/var/etcd-data"/
initial-cluster: "etcd-01=http://localhost:2380"
listen-client-urls: "http://localhost:2379"
advertise-client-urls: "http://localhost:2379"
initial-advertise-peer-urls: "http://localhost:2380"
listen-peer-urls: "http://localhost:2380"
```
```shell
## 启动服务，指定配置文件
$ nohup etcd --config-file /etc/etcd.yml >/var/etcd.log 2>&1 &

## 查看节点成员信息
$ etcdctl --endpoints=localhost:2379 member list -w table
```



<br/>



## 四. 搭建集群

### 1. 初始化集群

- Etcd遵循`先规划，再挂载`的原则，所以不管是初始化集群，还是新增节点，都必须先设定好集群列表。

_**先规初始化两个集群节点服务**_

```shell
## 集群列表,注意点：
## 1.只有在初始预设中的节点，接回包含在集群
## 2.初始化集群中的节点状态都为new
## 3.集群列表中的【名称】和【主机名】必须和启动的服务信息一致
$ CLUSTERS=etcd01=http://localhost:2380,etcd02=http://localhost:2480
```

```shell
## 将第一个节点挂载到集群中（端口：2379）
$ nohup etcd --name "etcd01" \
--listen-client-urls http://localhost:2379 \
--advertise-client-urls http://localhost:2379 \
--initial-advertise-peer-urls http://localhost:2380 \
--listen-peer-urls http://localhost:2380 \
--initial-cluster ${CLUSTERS} \
--initial-cluster-state new \
>./etcd01.log 2>&1 &
```

```shell
## 将第二个节点挂载到集群中（端口：2479）
$ nohup etcd --name "etcd02" \
--listen-client-urls http://localhost:2479 \
--advertise-client-urls http://localhost:2479 \
--initial-advertise-peer-urls http://localhost:2480 \
--listen-peer-urls http://localhost:2480 \
--initial-cluster ${CLUSTERS} \
--initial-cluster-state new \
>./etcd02.log 2>&1 &

```

_**查看服务结果**_

```shell
## 查询
$ export ETCDCTL_API=3

#终结点信息和集群列表信息一致(注意【格式】和【端口】不同)
$ ENDPOINTS=localhost:2379,localhost:2479

## 查看节点成员信息
$ etcdctl --endpoints=$ENDPOINTS member list -w table

## 查看节点状态信息
$ etcdctl --endpoints=$ENDPOINTS endpoint status -w table
```

_查询结果：_

```shell
[root@shs ~]# etcdctl --endpoints=$ENDPOINTS member list -w table
+------------------+---------+--------+-----------------------+-----------------------+------------+
|  ID  | STATUS | NAME |  PEER ADDRS  |  CLIENT ADDRS  | IS LEARNER |
+------------------+---------+--------+-----------------------+-----------------------+------------+
| b71f75320dc06a6c | started | etcd01 | http://localhost:2380 | http://localhost:2379 |  false |
| 11bff47b8baf3ee9 | started | etcd02 | http://localhost:2480 | http://localhost:2479 |  false |
+------------------+---------+--------+-----------------------+-----------------------+------------+

```

```shell
[root@shs ~]# etcdctl --endpoints=$ENDPOINTS endpoint status -w table
+----------------+------------+---------+---------+-----------+------------+-----------+------------+...
| ENDPOINT  |  ID  | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX |...
+----------------+------------+---------+---------+-----------+------------+-----------+------------+...
| localhost:2379 | b71f320... | 3.4.4 | 20 kB |  true |  false |  11 |   6 |...
| localhost:2479 | 11b47b8... | 3.4.4 | 20 kB |  false |  false |  11 |   6 |...
+----------------+------------+---------+---------+-----------+------------+-----------+------------+...
```



### 2. 增加集群节点

_**先添加集群成员**_

```shell
## 添加节点（节点名称与集群成员名称一致）
$ etcdctl --endpoints=$ENDPOINTS member add "etcd03" --peer-urls=http://localhost:2580

## 查看集群成员，注意【STATUS】字段
$ etcdctl --endpoints=$ENDPOINTS member list -w table
```

```txt
[root@vm02 etcd]# etcdctl --endpoints=$ENDPOINTS member list -w table
+------------------+-----------+--------+-----------------------+-----------------------+------------+
|  ID  | STATUS | NAME |  PEER ADDRS  |  CLIENT ADDRS  | IS LEARNER |
+------------------+-----------+--------+-----------------------+-----------------------+------------+
| 3949aab25068a95f | unstarted |  | http://localhost:2580 |      |  false |
| 8e9e05c52164694d | started | etcd01 | http://localhost:2380 | http://localhost:2379 |  false |
| f228da3d709012fc | started | etcd02 | http://localhost:2480 | http://localhost:2479 |  false |
+------------------+-----------+--------+-----------------------+-----------------------+------------+
```

_**最后扩展集群列表，并启动服务**_

```shell
## 声明集群列表
$ CLUSTERS=etcd01=http://localhost:2380,etcd02=http://localhost:2480,etcd03=http://localhost:2580

## 至于集群状态变为【existing】
$ nohup etcd --name "etcd03" \
--listen-client-urls http://localhost:2579 \
--advertise-client-urls http://localhost:2579 \
--listen-peer-urls http://127.0.0.1:2580 \
--initial-advertise-peer-urls http://localhost:2580 \
--initial-cluster-state existing \
--initial-cluster ${CLUSTERS} \
--initial-cluster-token etcd-cluster-1 \
>./etcd03.log 2>&1 &
```
_**再次查看服务结果：**_

```shell
$ ENDPOINTS=localhost:2379,localhost:2479,localhost:2579
$ etcdctl --endpoints=$ENDPOINTS member list -w table
$ etcdctl --endpoints=$ENDPOINTS endpoint status -w table
```



### 3. 删除集群节点

```shell
## 试着删除leader节点，会发现leader转移到其他节点上
$ etcdctl --endpoints=$ENDPOINTS member remove 8e9e05c52164694d
```

> 温馨提示：删除服务的同时，请删除数据文件，否则再次创建服务的时候会加载旧的状态数据



## 五. Golang管理集群

```go
package main

import (
 "github.com/coreos/etcd/clientv3"
 "log"
 "fmt"
 "context"
 "time"
)
var (
 dialTimeout = 5 * time.Second
 requestTimeout = 2 * time.Second
 endpoints  = []string{"127.0.0.1:2379"}
)
func main() {

 cli, err := clientv3.New(clientv3.Config{
  Endpoints: endpoints,
  DialTimeout: dialTimeout,
 })
 if err != nil {
  log.Fatal(err)
 }
 defer cli.Close()

 resp, err := cli.MemberList(context.Background())
 if err != nil {
  log.Fatal(err)
 }
 fmt.Println("members:", resp.Members)


 //添加member
 //addMember(cli)


 // 删除节点
 //delMember(cli,uint64(7438291228984697304))

}

func addMember(cli *clientv3.Client) {
 peerURLs := []string{"http://127.0.0.1:2180"}

 mresp, err := cli.MemberAdd(context.Background(), peerURLs)
 if err != nil {
  log.Fatal(err)
 }
 fmt.Println("added member.PeerURLs:", mresp.Member.PeerURLs)
 resp, err := cli.MemberList(context.Background())
 if err != nil {
  log.Fatal(err)
 }
 fmt.Println("添加后 members:", resp.Members)
}

// 删除节点
func delMember (cli *clientv3.Client, memberId uint64) {

 resp, err := cli.MemberList(context.Background())
 if err != nil {
  log.Fatal(err)
 }

 _, err = cli.MemberRemove(context.Background(), memberId)
 if err != nil {
  log.Fatal(err)
 }

 resp, err = cli.MemberList(context.Background())
 if err != nil {
  log.Fatal(err)
 }
 fmt.Println("删除后 members:", resp.Members)
}
```


<br/>



https://developer.aliyun.com/article/1385959?spm=a2c6h.12873639.article-detail.25.54d11ec1w7RytC&scm=20140722.ID_community@@article@@1385959._.ID_community@@article@@1385959-OR_rec-V_1-RL_community@@article@@1025089





> 参考：
> https://www.jianshu.com/p/2966b6ef5d10
>
> https://mritd.me/2016/09/01/Etcd-%E9%9B%86%E7%BE%A4%E6%90%AD%E5%BB%BA/
>
> https://blog.csdn.net/ShouTouDeXingFu/article/details/81167302
>
> https://blog.csdn.net/bbwangj/article/details/82584988
>
> https://www.liwenzhou.com/posts/Go/go_etcd/
>
> http://www.iigrowing.cn/etcd_shi_yong_ru_men.html
>
> https://www.jianshu.com/p/8e4bbe7e276c
>
> https://segmentfault.com/a/1190000014045625
>
> https://www.cnblogs.com/davygeek/p/7154780.html
>
> https://www.cnblogs.com/zhenghongxin/p/7029173.html
>
> https://blog.csdn.net/zhaominpro/article/details/82630528
>
> https://blog.csdn.net/weixin_34080571/article/details/93621638
>
> https://www.orchome.com/620
>
> https://www.cnblogs.com/linuxws/p/11194403.html 配置
>
> https://www.jianshu.com/p/71f4af1815d9
