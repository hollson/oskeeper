









## 安装Consul

```shell
docker pull hashicorp/consul:latest
mkdir -p /Users/sybs/data/consul

# -agent: 以代理模式(集群)启动
# -server: 服务器模式(否则将作为客户端运行)
# -bind: Consul绑定的网络接口
# -client: 允许访问的客户端网段
# -bootstrap: 作为引导节点(只用于引导和初始化，在引导完成后，将变为普通节点)
# -bootstrap-expect: 期望的服务器数量(与bootstrap配合使用)
# -encrypt: 通信密钥(可用consul keygen生成)
docker run --name=consul \
-p 8500:8500 \
--restart=always \
--privileged=true \
-v /Users/sybs/consul/data:/consul/data \
-d hashicorp/consul:latest \
agent -server -ui \
-bind=0.0.0.0 \
-client=0.0.0.0 \
-bootstrap \
-bootstrap-expect=1 \
-log-level=info \
-encrypt=ka0ViPLMbmf403lmjmgNsP4Qr8mZZAgwj4dj3Xfn5bQ= \
-node=node001

docker exec -ti consul bash
docker rm -f consul
```

```shell
# 查看agent参数(包括启动参数等)
consul agent -h
consul info
consul config list -kind service-defaults
```



http://127.0.0.1:8500





## 参考资料

https://www.consul.io/





