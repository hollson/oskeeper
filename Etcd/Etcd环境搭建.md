## 一. 单机安装

> 具体安装过程可参考[ETCD官方文档](https://etcd.io/docs/v3.6/)

## Binary

```bash
# 下载&并解安装到/usr/local/etcd目录下
# wget -L https://github.com/etcd-io/etcd/releases/download/v3.5.12/etcd-v3.5.12-darwin-amd64.zip
$ wget -L https://github.com/etcd-io/etcd/releases/download/v3.5.12/etcd-v3.5.12-linux-amd64.tar.gz

# 添加软链
$ sudo ln -s /usr/local/etcd/etcd /usr/local/bin/etcd
$ sudo ln -s /usr/local/etcd/etcdctl /usr/local/bin/etcdctl
$ sudo ln -s /usr/local/etcd/etcdutl /usr/local/bin/etcdutl

# 启动进程
# 注意⚠️ ：advertise-client-urls是可以被客户端公开访问的地址
$ mkdir -p /opt/etcd
$ nohup etcd --data-dir /opt/etcd \
--listen-client-urls http://0.0.0.0:2379 \
--advertise-client-urls http://172.16.1.1:2379 &

# 查看信息
etcd --version
etcdctl version
etcdutl version
etcdctl endpoint health
etcdctl member list -w=table

# 数据测试
etcdctl put greet HelloWorld
etcdctl get greet
etcdctl --endpoints=172.16.1.1:2379 get --prefix ''
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
