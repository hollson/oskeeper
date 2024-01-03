
[toc]

## Http接口

可将 [ETCD API文档](https://github.com/etcd-io/etcd/tree/main/Documentation/dev-guide/apispec/swagger) 的URL导入 [在线Swagger工具](https://editor-next.swagger.io/)，查看完整文档。

```shell
# 版本信息
curl http://127.0.0.1:2379/version

# 测试数据
KEY=$(echo "/hello"|base64)
VAL=$(echo "Hello World"|base64)

# 写入(KV需要base64编码),否则会乱码 
# echo "/hello"|base64
# echo "Hello World"|base64
curl -X POST http://localhost:2379/v3/kv/put -d "{\"key\":\"${KEY}\", \"value\":\"${VAL}\"}"

#查询
curl -X POST http://localhost:2379/v3/kv/range -d "{\"key\": \"${KEY}\"}"

# 范围查询(Etcd中，键是按字典顺序排序的),如:在[a,b,c,d,e,f]中查询b到d
curl -X POST http://localhost:2379/v3/kv/range -d '{"key": "Ygo=", "range_end": "ZAo="}'


# 删除
curl -X 'POST' \
  'https://raw.githubusercontent.com/v3/kv/deleterange' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "key": "string",
  "range_end": "string",
  "prev_kv": true
}'

```

```shell
curl -N http://localhost:2379/v3/watch \
  -X POST -d '{"create_request": {"key":"Zm9v"} }' &

curl -L http://localhost:2379/v3/kv/put \
  -X POST -d '{"key": "Zm9v", "value": "YmFy"}' >/dev/null 2>&1

# target CREATE
curl -L http://localhost:2379/v3/kv/txn -X POST \
  -d '{"compare":[{"target":"CREATE","key":"Zm9v","createRevision":"2"}],"success":[{"requestPut":{"key":"Zm9v","value":"YmFy"}}]}'


# target VERSION
curl -L http://localhost:2379/v3/kv/txn \
  -X POST \
  -d '{"compare":[{"version":"4","result":"EQUAL","target":"VERSION","key":"Zm9v"}],"success":[{"requestRange":{"key":"Zm9v"}}]}'

# create root user
curl -L http://localhost:2379/v3/auth/user/add \
  -X POST -d '{"name": "root", "password": "pass"}'

# create root role
curl -L http://localhost:2379/v3/auth/role/add \
  -X POST -d '{"name": "root"}'

# grant root role
curl -L http://localhost:2379/v3/auth/user/grant \
  -X POST -d '{"user": "root", "role": "root"}'
  
# enable auth
curl -L http://localhost:2379/v3/auth/enable -X POST -d '{}'



# get the auth token for the root user
curl -L http://localhost:2379/v3/auth/authenticate -X POST -d '{"name": "root", "password": "pass"}'

curl -L http://localhost:2379/v3/kv/put \
  -H 'Authorization : sssvIpwfnLAcWAQH.9' \
  -X POST -d '{"key": "Zm9v", "value": "YmFy"}'
```



**集群操作**

```shell
# 获取成员列表：
curl -X POST http://localhost:2379/v3/cluster/member/list -d '{"linearizable": true}'

# 添加成员(学习者，无投票权)
curl -X POST http://localhost:2379/v3/cluster/member/add \
-d '{"peerURLs": ["http://<new_member_host>:2380"],"isLearner": true}'

# 更新成员
curl -X POST http://localhost:2379/v3/cluster/member/update \
-d '{"ID": "string","peerURLs": ["string"]}'

# 提升为投票成员
curl -X POST http://localhost:2379/v3/cluster/member/promote -d '{"ID": "string"}'

# 移除成员
curl -X POST http://localhost:2379/v3/cluster/member/remove -d '{"ID": "string"}'
```



10. 原子操作（事务）：
```shell
curl -X POST http://localhost:2379/v3/kv/txn -d '{
    "success": [
        {"request_put": {"key": "key1", "value": "123"}},
        {"compare_and_swap": {"key": "key2", "prev_kv": true, "value": "456"}}
    ],
    "failure": [
        {"request_range": {"key": "nonexistent"}}
    ]
}'
```





## 用户权限

```shell
# 用户列表
etcdctl user list

# 添加root/work用户
etcdctl user add root --new-user-password="123456"
etcdctl user add work --new-user-password="123456"

# 查看用户
etcdctl user get root

# 查看角色
etcdctl role get root

# 开启认证(即需要身份验证才能访问)
etcdctl auth enable

# 开启认证后会多一个guest角色(不能删)
etcdctl --username root:123456 role list

# guest拥有超级权限
etcdctl --username root:123456 role get guest

# 添加自定义用户
etcdctl --username root:123456 user add leader    #领导
etcdctl --username root:123456 user add member    #成员

# 定义角色(conf读写角色)
etcdctl --username root:123456 role add conf100    #只读角色
etcdctl --username root:123456 role add conf110    #读写角色

# 定义角色权限
etcdctl --username root:123456 role grant --read --path /conf/* conf100       #只读权限
etcdctl --username root:123456 role grant --readwrite --path /conf/* conf110  #读写权限

# 给用户赋予角色
etcdctl --username root:123456 user grant --roles conf110 leader
etcdctl --username root:123456 user grant --roles conf100 member

# 测试权限
etcdctl --username member:123456 set /conf/my.ini  root:xxx@127.0.0.1:3306/demo
etcdctl --username leader:123456 set /conf/my.ini  root:xxx@127.0.0.1:3306/demo
etcdctl --username member:123456 get /conf/my.ini
etcdctl --endpoint=192.168.100.214:2379 --username member:123456 get /conf/my.ini
etcdctl --username leader:123456 --endpoints http://192.168.100.214:2379 set /conf/app.yml xxx

# 查看用户权限
etcdctl --username root:123456 user get leader

#关闭认证
etcdctl --username root:123456 auth disable

#删除用户
etcdctl --username root:123456 user remove userx

# 用户撤销角色
etcdctl --username root:123456 user revoke rolex

#修改用户密码
etcdctl --username root:123456 user passwd userx
```


```shell
etcdctl --user=root:123456 user list
etcdctl --user=root:123456 --endpoints=192.168.1.3:2379 put shi 史布斯
```



**动态配置**
```shell
# 使用IP作为节点名称
IP=`/sbin/ifconfig -a|grep "inet "|grep "1[9,7]2."|awk '{print $2}'|tail -n 1|tr -d "addr:"`
echo 当前IP:$IP

# 使用md5(IP)作为Etcd的Token
TOKEN=`echo $IP| md5sum | cut -d ' ' -f 1` 
echo $TOKEN
```



## Proto协议接口

https://github.com/etcd-io/etcd/blob/v3.3.25/mvcc/mvccpb/kv.proto

https://github.com/etcd-io/etcd/blob/v3.3.25/mvcc/mvccpb/kv.proto





## clientGo

https://github.com/etcd-io/etcd/tree/main/client/v3





## Base64

```shell
echo "/hello" | base64
echo "L2hlbGxvCg==" | base64 -D
```



http://play.etcd.io/play


https://blog.csdn.net/u010278923/article/details/71727682
https://blog.csdn.net/Sherry_zh2017/article/details/79162344
https://blog.csdn.net/leftwukaixing/article/details/78252691

https://www.e-learn.cn/content/qita/1601591
https://blog.csdn.net/hxpjava1/article/details/78275995

https://godoc.org/go.etcd.io/etcd/clientv3#pkg-index
https://blog.csdn.net/warrior_0319/article/details/80223947

https://www.orchome.com/620

https://blog.51cto.com/liuzhengwei521/2411731?source=dra





