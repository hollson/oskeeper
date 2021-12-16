# K8s手动安装过程
+++
title= "📒 K8s笔记二.  - 搭建K8s环境"
url= "/posts/k8sea795d75f38c02/"
aliases = ["/posts/k8s003"]
description= "Kubernetes 是用于自动部署,扩展和管理容器化应用程序的开源系统。 它将组成应用程序的容器组合成逻辑单元,以便于管理和服务发现。"
image= "/img/res/blog.jpg"
date= 2020-06-27T08:22:31+08:00
lastmod= 2020-06-27T08:22:31+08:00
categories= ["K8s"]
tags= ["K8s"]
archives= "2020"
author= "史布斯"
height= 1587401551
draft= false

+++

[TOC]






## 手动安装

###  1. 准备工作

| 系统类型 | IP地址    | 节点角色 | CPU  | Memory | Hostname |
| -------- | --------- | -------- | ---- | ------ | -------- |
| Centos7  | 10.0.0.11 | master   | 1    | 2G     | s001.k8s.com |
| Centos7  | 10.0.0.12 | worker   | 1    | 2G     | s002.k8s.com |
| Centos7  | 10.0.0.13 | worker   | 1    | 2G     | s003.k8s.com |

-   **1.1 关闭防火墙**

```bash
systemctl stop firewalld
systemctl disable firewalld
firewall-cmd --state
```

-   **1.2 配置hosts**

```bash
cat <<EOF >> /etc/hosts
10.0.0.11 s001.k8s.com
10.0.0.12 s002.k8s.com
10.0.0.13 s003.k8s.com
EOF
```

-   **1.3 设置系统参数**

```bash
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
 
#生效配置文件
sysctl -p /etc/sysctl.d/k8s.conf
```

-   **1.4 设置环境变量**

```bash
cat <<EOF > ~/.bash_profile
	export K8S_IP=10.0.0.11
	export K8S_ROLE=MASTER 或 WORKER	#服务器角色
EOF
```

-   **1.5 准备K8s组件**

>   官方下载:[参考地址一](https://github.com/kubernetes/kubernetes/blob/master/staging/README.md) 或 [参考地址二](https://www.downloadkubernetes.com)  　　　　　
>
>   百度网盘：https://pan.baidu.com/s/19nG82wks5A4w7VJ0uqk-HA 提取码: pci7

_所需组件如下：_

```bash
[root@vm k8s]# tree
├── calico
├── calicoctl
├── calico-ipam
├── etcd
├── etcdctl
├── kube-apiserver
├── kube-controller-manager
├── kubectl
├── kubelet
├── kube-proxy
├── kube-scheduler
├── loopback
└── VERSION.md
```



### 2. 安装Docker(All)

```bash
VERSION=docker-ce-18.06.1.ce-3.el7.x86_64.rpm
wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/${VERSION}
yum install -y ./${VERSION}

systemctl enable docker
systemctl start docker
docker version

# docker run hello-world
```



### 3. 安装Etcd(Master)

```shell
cp target/master-node/etcd.service /lib/systemd/system/
systemctl enable etcd.service
mkdir -p /var/lib/etcd
service etcd start

ps -ef|grep etcd
# journalctl -f -u etcd.service
```



### 4. 安装ApiServer(Master)

```shell
cp target/master-node/kube-apiserver.service /lib/systemd/system/
systemctl enable kube-apiserver.service
service kube-apiserver start
ps -ef|grep kube-apiserver
# journalctl -f -u kube-apiserver
```

```bash
[Unit]
Description=Kubernetes API Server
...
[Service]
#可执行文件的位置
ExecStart=/home/michael/bin/kube-apiserver \
#非安全端口(8080)绑定的监听地址 这里表示监听所有地址
--insecure-bind-address=0.0.0.0 \
#不使用https
--kubelet-https=false \
#kubernetes集群的虚拟ip的地址范围
--service-cluster-ip-range=10.68.0.0/16 \
#service的nodeport的端口范围限制
--service-node-port-range=20000-40000 \
#很多地方都需要和etcd打交道，也是唯一可以直接操作etcd的模块
--etcd-servers=http://192.168.1.102:2379 \
```



### 5. 安装ControllerManager(Master)

```bash
cp target/master-node/kube-controller-manager.service /lib/systemd/system/
systemctl enable kube-controller-manager.service
service kube-controller-manager start
ps -ef|grep kube-controller-manager
#journalctl -f -u kube-controller-manager
```

**重点配置说明:**

```bash
$ cat /lib/systemd/system/kube-controller-manager.service

[Unit]
Description=Kubernetes Controller Manager
...
[Service]
ExecStart=/home/michael/bin/kube-controller-manager \
\#对外服务的监听地址，这里表示只有本机的程序可以访问它
--address=127.0.0.1 \
\#apiserver的url
--master=http://127.0.0.1:8080 \
\#服务虚拟ip范围，同apiserver的配置
--service-cluster-ip-range=10.68.0.0/16 \
\#pod的ip地址范围
--cluster-cidr=172.20.0.0/16 \
\#下面两个表示不使用证书，用空值覆盖默认值
--cluster-signing-cert-file= \
--cluster-signing-key-file= \
...
```





### 6. 安装Scheduler(Master)

>   `kube-scheduler`负责分配调度Pod到集群内的节点上，它监听kube-apiserver，查询还未分配Node的Pod，然后根据调度策略为这些Pod分配节点。我们前面讲到的kubernetes的各种调度策略就是它实现的。

**安装命令：**

```bash
cp target/master-node/kube-scheduler.service /lib/systemd/system/
systemctl enable kube-scheduler.service
service kube-scheduler start
ps -ef|grep kube-scheduler
# journalctl -f -u kube-scheduler
```

**配置说明：**

```bash
[Unit]
Description=Kubernetes Scheduler
...
[Service]
ExecStart=/home/michael/bin/kube-scheduler \
\#对外服务的监听地址，这里表示只有本机的程序可以访问它
--address=127.0.0.1 \
\#apiserver的url
--master=http://127.0.0.1:8080 \
...
```



### 7. 部署CalicoNode(All)

>   Calico实现了CNI接口，是kubernetes网络方案的一种选择，它一个纯三层的数据中心网络方案（不需要Overlay），并且与OpenStack、Kubernetes、AWS、GCE等IaaS和容器平台都有良好的集成。 Calico在每一个计算节点利用Linux  Kernel实现了一个高效的vRouter来负责数据转发，而每个vRouter通过BGP协议负责把自己上运行的workload的路由信息像整个Calico网络内传播——小规模部署可以直接互联，大规模下可通过指定的BGP route reflector来完成。 这样保证最终所有的workload之间的数据流量都是通过IP路由的方式完成互联的。

**calico是通过系统服务+docker方式完成的**

```bash
cp target/all-node/kube-calico.service /lib/systemd/system/
systemctl enable kube-calico.service
service kube-calico start
# journalctl -f -u kube-calico
```

**查看容器运行情况**

```bash
$ docker ps
CONTAINER ID   IMAGE                COMMAND        CREATED ...
4d371b58928b   calico/node:v2.6.2   "start_runit"  3 hours ago...
```

**查看节点运行情况**

```bash
[root@vm01 kubernetes-starter]# /root/k8s/calicoctl node status
Calico process is running.

IPv4 BGP status
+--------------+-------------------+-------+----------+-------------+
| PEER ADDRESS |     PEER TYPE     | STATE |  SINCE   |    INFO     |
+--------------+-------------------+-------+----------+-------------+
| 10.0.0.12    | node-to-node mesh | up    | 20:23:22 | Established |
| 10.0.0.13    | node-to-node mesh | up    | 20:23:37 | Established |
+--------------+-------------------+-------+----------+-------------+

IPv6 BGP status
No IPv6 peers found.
```

**查看端口BGP 协议是通过TCP 连接来建立邻居的，因此可以用netstat 命令验证 BGP Peer**

```bash
$ netstat -natp|grep ESTABLISHED|grep 179
tcp        0      0 192.168.1.102:60959     192.168.1.103:179       ESTABLISHED 29680/bird
```

**查看集群ippool情况**

```
$ calicoctl get ipPool -o yaml
- apiVersion: v1
  kind: ipPool
  metadata:
    cidr: 172.20.0.0/16
  spec:
    nat-outgoing: true
```

5.4 重点配置说明

```bash
[Unit]
Description=calico node
...
[Service]
\#以docker方式运行
ExecStart=/usr/bin/docker run --net=host --privileged --name=calico-node \
\#指定etcd endpoints（这里主要负责网络元数据一致性，确保Calico网络状态的准确性）
-e ETCD_ENDPOINTS=http://192.168.1.102:2379 \
\#网络地址范围（同上面ControllerManager）
-e CALICO_IPV4POOL_CIDR=172.20.0.0/16 \
\#镜像名，为了加快大家的下载速度，镜像都放到了阿里云上
registry.cn-hangzhou.aliyuncs.com/imooc/calico-node:v2.6.2
```





### 8. 配置kubectl命令(Aay)

>   kubectl是Kubernetes的命令行工具，是Kubernetes用户和管理员必备的管理工具。 kubectl提供了大量的子命令，方便管理Kubernetes集群中的各种功能。

**kubectl初始化：**

使用kubectl的第一步是配置Kubernetes集群以及认证方式，包括：

-   cluster信息：api-server地址
-   用户信息：用户名、密码或密钥
-   Context：cluster、用户信息以及Namespace的组合

我们这没有安全相关的东西，只需要设置好api-server和上下文就好啦：

```bash
#指定apiserver地址（ip替换为你自己的api-server地址）
kubectl config set-cluster kubernetes  --server=http://10.0.0.11:8080
#指定设置上下文，指定cluster
kubectl config set-context kubernetes --cluster=kubernetes
#选择默认的上下文
kubectl config use-context kubernetes
```

>   通过上面的设置最终目的是生成了一个配置文件：~/.kube/config，当然你也可以手写或复制一个文件放在那，就不需要上面的命令了。



### 9. 配置kubelet(Worker)

>   每个工作节点上都运行一个kubelet服务进程，默认监听10250端口，接收并执行master发来的指令，管理Pod及Pod中的容器。每个kubelet进程会在API Server上注册节点自身信息，定期向master节点汇报节点的资源使用情况，并通过cAdvisor监控节点和容器的资源。

```bash
#确保相关目录存在
mkdir -p /var/lib/kubelet
mkdir -p /etc/kubernetes
mkdir -p /etc/cni/net.d

#复制kubelet服务配置文件
cp target/worker-node/kubelet.service /lib/systemd/system/
#复制kubelet依赖的配置文件
cp target/worker-node/kubelet.kubeconfig /etc/kubernetes/
#复制kubelet用到的cni插件配置文件
cp target/worker-node/10-calico.conf /etc/cni/net.d/

systemctl enable kubelet.service
service kubelet start
ps -ef|grep kubelet
#journalctl -f -u kubelet
```

**重点配置说明:**

```bash
[Unit]
Description=Kubernetes Kubelet
[Service]
\#kubelet工作目录，存储当前节点容器，pod等信息
WorkingDirectory=/var/lib/kubelet
ExecStart=/home/michael/bin/kubelet \
\#对外服务的监听地址
--address=192.168.1.103 \
\#指定基础容器的镜像，负责创建Pod 内部共享的网络、文件系统等，这个基础容器非常重要：K8S每一个运行的 POD里面必然包含这个基础容器，如果它没有运行起来那么你的POD 肯定创建不了
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/imooc/pause-amd64:3.0 \
\#访问集群方式的配置，如api-server地址等
--kubeconfig=/etc/kubernetes/kubelet.kubeconfig \
\#声明cni网络插件
--network-plugin=cni \
\#cni网络配置目录，kubelet会读取该目录下得网络配置
--cni-conf-dir=/etc/cni/net.d \
\#指定 kubedns 的 Service IP(可以先分配，后续创建 kubedns 服务时指定该 IP)，--cluster-domain 指定域名后缀，这两个参数同时指定后才会生效
--cluster-dns=10.68.0.2 \
...
```



**kubelet.kubeconfig**
kubelet依赖的一个配置，格式看也是我们后面经常遇到的yaml格式，描述了kubelet访问apiserver的方式

>   apiVersion: v1
>    clusters:
>    \- cluster:
>    \#跳过tls，即是kubernetes的认证
>    insecure-skip-tls-verify: true
>    \#api-server地址
>    server: http://192.168.1.102:8080
>    ...

**10-calico.conf**
calico作为kubernets的CNI插件的配置

```conf
{  
  "name": "calico-k8s-network",  
  "cniVersion": "0.1.0",  
  "type": "calico",  
    <!--etcd的url-->
    "ed_endpoints": "http://192.168.1.102:2379",  
    "logevel": "info",  
    "ipam": {  
        "type": "calico-ipam"  
   },  
    "kubernetes": {  
        <!--api-server的url-->
        "k8s_api_root": "http://192.168.1.102:8080"  
    }  
}  
```



### 10. 增加kube-proxy(Worker)

>    每台工作节点上都应该运行一个kube-proxy服务，它监听API server中service和endpoint的变化情况，并通过iptables等来为服务配置负载均衡，是让我们的服务在集群外可以被访问到的重要方式。

```bash
#确保工作目录存在
mkdir -p /var/lib/kube-proxy
#复制kube-proxy服务配置文件
cp target/worker-node/kube-proxy.service /lib/systemd/system/
#复制kube-proxy依赖的配置文件
cp target/worker-node/kube-proxy.kubeconfig /etc/kubernetes/

systemctl enable kube-proxy.service
service kube-proxy start
#journalctl -f -u kube-proxy
```

**重点配置说明:**

**kube-proxy.service**

```bash
[Unit]
Description=Kubernetes Kube-Proxy Server ...
[Service]
\#工作目录
WorkingDirectory=/var/lib/kube-proxy
ExecStart=/home/michael/bin/kube-proxy \
\#监听地址
--bind-address=192.168.1.103 \
\#依赖的配置文件，描述了kube-proxy如何访问api-server
--kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig \
...
```



**kube-proxy.kubeconfig** 配置了kube-proxy如何访问api-server，内容与kubelet雷同，不再赘述。

刚才我们在基础集群上演示了pod，deployments。下面就在刚才的基础上增加点service元素。具体内容见[《Docker+k8s微服务容器化实践》](https://coding.imooc.com/class/198.html)。



### 11. 添加dns功能

>   kube-dns为Kubernetes集群提供命名服务，主要用来解析集群服务名和Pod的hostname。目的是让pod可以通过名字访问到集群内服务。它通过添加A记录的方式实现名字和service的解析。普通的service会解析到service-ip。headless service会解析到pod列表。

```bash
# 到kubernetes-starter目录执行命令
kubectl create -f target/services/kube-dns.yaml
```

_通过dns访问服务:具体内容请看[《Docker+k8s微服务容器化实践》](https://coding.imooc.com/class/198.html)_



<br/>


## Kubeadmin安装

### 第 1 步 - 初始化 Master

```bash
kubeadm init --token=102952.1a7dd4cc8d1f4cc5 --kubernetes-version $(kubeadm version -o short)

sudo cp /etc/kubernetes/admin.conf $HOME/
sudo chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
```



### 第 2 步 - 部署容器网络接口 (CNI)

容器网络接口 (CNI) 定义了不同节点及其工作负载应如何通信, some are listed [here](https://kubernetes.io/docs/admin/addons/).

```bash
kubectl apply -f /opt/weave-kube.yaml
kubectl get pod -n kube-system
```
_weave-kube.yaml_
```yaml
apiVersion: v1
kind: List
items:
  - apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: weave-net
      annotations:
        cloud.weave.works/launcher-info: |-
          {
            "original-request": {
              "url": "/k8s/v1.10/net.yaml?k8s-version=v1.16.0",
              "date": "Mon Oct 28 2019 18:38:09 GMT+0000 (UTC)"
            },
            "email-address": "support@weave.works"
          }
      labels:
        name: weave-net
      namespace: kube-system
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: weave-net
      annotations:
        cloud.weave.works/launcher-info: |-
          {
            "original-request": {
              "url": "/k8s/v1.10/net.yaml?k8s-version=v1.16.0",
              "date": "Mon Oct 28 2019 18:38:09 GMT+0000 (UTC)"
            },
            "email-address": "support@weave.works"
          }
      labels:
        name: weave-net
    rules:
      - apiGroups:
          - ''
        resources:
          - pods
          - namespaces
          - nodes
        verbs:
          - get
          - list
          - watch
      - apiGroups:
          - networking.k8s.io
        resources:
          - networkpolicies
        verbs:
          - get
          - list
          - watch
      - apiGroups:
          - ''
        resources:
          - nodes/status
        verbs:
          - patch
          - update
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: weave-net
      annotations:
        cloud.weave.works/launcher-info: |-
          {
            "original-request": {
              "url": "/k8s/v1.10/net.yaml?k8s-version=v1.16.0",
              "date": "Mon Oct 28 2019 18:38:09 GMT+0000 (UTC)"
            },
            "email-address": "support@weave.works"
          }
      labels:
        name: weave-net
    roleRef:
      kind: ClusterRole
      name: weave-net
      apiGroup: rbac.authorization.k8s.io
    subjects:
      - kind: ServiceAccount
        name: weave-net
        namespace: kube-system
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: weave-net
      annotations:
        cloud.weave.works/launcher-info: |-
          {
            "original-request": {
              "url": "/k8s/v1.10/net.yaml?k8s-version=v1.16.0",
              "date": "Mon Oct 28 2019 18:38:09 GMT+0000 (UTC)"
            },
            "email-address": "support@weave.works"
          }
      labels:
        name: weave-net
      namespace: kube-system
    rules:
      - apiGroups:
          - ''
        resourceNames:
          - weave-net
        resources:
          - configmaps
        verbs:
          - get
          - update
      - apiGroups:
          - ''
        resources:
          - configmaps
        verbs:
          - create
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: weave-net
      annotations:
        cloud.weave.works/launcher-info: |-
          {
            "original-request": {
              "url": "/k8s/v1.10/net.yaml?k8s-version=v1.16.0",
              "date": "Mon Oct 28 2019 18:38:09 GMT+0000 (UTC)"
            },
            "email-address": "support@weave.works"
          }
      labels:
        name: weave-net
      namespace: kube-system
    roleRef:
      kind: Role
      name: weave-net
      apiGroup: rbac.authorization.k8s.io
    subjects:
      - kind: ServiceAccount
        name: weave-net
        namespace: kube-system
  - apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      name: weave-net
      annotations:
        cloud.weave.works/launcher-info: |-
          {
            "original-request": {
              "url": "/k8s/v1.10/net.yaml?k8s-version=v1.16.0",
              "date": "Mon Oct 28 2019 18:38:09 GMT+0000 (UTC)"
            },
            "email-address": "support@weave.works"
          }
      labels:
        name: weave-net
      namespace: kube-system
    spec:
      minReadySeconds: 5
      selector:
        matchLabels:
          name: weave-net
      template:
        metadata:
          labels:
            name: weave-net
        spec:
          containers:
            - name: weave
              command:
                - /home/weave/launch.sh
              env:
                - name: IPALLOC_RANGE
                  value: 10.32.0.0/24
                - name: HOSTNAME
                  valueFrom:
                    fieldRef:
                      apiVersion: v1
                      fieldPath: spec.nodeName
              image: 'docker.io/weaveworks/weave-kube:2.6.0'
              readinessProbe:
                httpGet:
                  host: 127.0.0.1
                  path: /status
                  port: 6784
              resources:
                requests:
                  cpu: 10m
              securityContext:
                privileged: true
              volumeMounts:
                - name: weavedb
                  mountPath: /weavedb
                - name: cni-bin
                  mountPath: /host/opt
                - name: cni-bin2
                  mountPath: /host/home
                - name: cni-conf
                  mountPath: /host/etc
                - name: dbus
                  mountPath: /host/var/lib/dbus
                - name: lib-modules
                  mountPath: /lib/modules
                - name: xtables-lock
                  mountPath: /run/xtables.lock
            - name: weave-npc
              env:
                - name: HOSTNAME
                  valueFrom:
                    fieldRef:
                      apiVersion: v1
                      fieldPath: spec.nodeName
              image: 'docker.io/weaveworks/weave-npc:2.6.0'
              resources:
                requests:
                  cpu: 10m
              securityContext:
                privileged: true
              volumeMounts:
                - name: xtables-lock
                  mountPath: /run/xtables.lock
          hostNetwork: true
          hostPID: true
          restartPolicy: Always
          securityContext:
            seLinuxOptions: {}
          serviceAccountName: weave-net
          tolerations:
            - effect: NoSchedule
              operator: Exists
          volumes:
            - name: weavedb
              hostPath:
                path: /var/lib/weave
            - name: cni-bin
              hostPath:
                path: /opt
            - name: cni-bin2
              hostPath:
                path: /home
            - name: cni-conf
              hostPath:
                path: /etc
            - name: dbus
              hostPath:
                path: /var/lib/dbus
            - name: lib-modules
              hostPath:
                path: /lib/modules
            - name: xtables-lock
              hostPath:
                path: /run/xtables.lock
                type: FileOrCreate
      updateStrategy:
        type: RollingUpdate
```
>   When installing Weave on your cluster, visit https://www.weave.works/docs/net/latest/kube-addon/ for details.



### 第 3 步 - 加入集群

一旦 Master 和 CNI 初始化，其他节点只要有正确的令牌就可以加入集群。  令牌可以通过以下方式管理  `kubeadm token`， 例如  `kubeadm token list`.

在第二个节点上，运行命令加入集群，提供主节点的 IP 地址。

```bash
kubeadm join --discovery-token-unsafe-skip-ca-verification --token=102952.1a7dd4cc8d1f4cc5 172.17.0.87:6443
```

这与 Master 初始化后提供的命令相同。

这  `--discovery-token-unsafe-skip-ca-verification`标签用于绕过 Discovery Token 验证。  由于此令牌是动态生成的，因此我们无法将其包含在步骤中。  在生产中，使用提供的令牌  `kubeadm init`.



### 第 4 步 - 查看节点

```bash
kubectl get nodes
```



### 第 5 步 - 部署 Pod

```
kubectl create deployment http --image=katacoda/docker-http-server:latest
kubectl get pods
docker ps | grep docker-http-server
```



### 第 6 步 - 部署仪表板

Kubernetes 有一个基于 Web 的仪表板 UI，提供对 Kubernetes 集群的可见性。

使用命令部署仪表板 yaml  `kubectl apply -f dashboard.yaml`

仪表板部署到 *kube-system* 命名空间中。 查看部署状态 `kubectl get pods -n kube-system`

需要 ServiceAccount 才能登录。 ClusterRoleBinding 用于为新的 ServiceAccount ( 分配 *admin-user* ) 角色 *集群 -admin* 上的 cluster 。

```
cat <<EOF | kubectl create -f - 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF
```

这意味着他们可以控制 Kubernetes 的所有方面。 通过 ClusterRoleBinding 和 RBAC，可以根据安全要求定义不同级别的权限。 有关为仪表板创建用户的更多信息，请参见 [仪表板文档 ](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user)。

创建 ServiceAccount 后，可以通过以下方式找到登录令牌：

```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

部署仪表板时，它使用 externalIPs 将服务绑定到端口 8443。这使得仪表板可供集群外部使用，并可在 查看 [https://2886795352-8443-cykoria04.environments.katacoda.com/ ](https://2886795352-8443-cykoria04.environments.katacoda.com/)

使用 *管理员用户* 令牌访问仪表板。

对于生产，建议使用而不是 externalIPs  `kubectl proxy`访问仪表板。 在 查看更多详细信息 [https://github.com/kubernetes/dashboard 上 ](https://github.com/kubernetes/dashboard)。



---



```bash
$ kubeadm init --token=102952.1a7dd4cc8d1f4cc5 --kubernetes-version $(kubeadm version -o short)
[init] Using Kubernetes version: v1.14.0
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [controlplane kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.17.0.56]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [controlplane localhost] and IPs [172.17.0.56 127.0.0.1 ::1]
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [controlplane localhost] and IPs [172.17.0.56 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 20.504376 seconds
[upload-config] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.14" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --experimental-upload-certs
[mark-control-plane] Marking the node controlplane as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node controlplane as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: 102952.1a7dd4cc8d1f4cc5
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

$ kubeadm join 172.17.0.56:6443 --token 102952.1a7dd4cc8d1f4cc5 \
    --discovery-token-ca-cert-hash sha256:1769836f75a258befcb5d79dcc6624b159157771176321492e67e4304bcd5dc1 
controlplane $ 

$ sudo cp /etc/kubernetes/admin.conf $HOME/
$ sudo chown $(id -u):$(id -g) $HOME/admin.conf
$ export KUBECONFIG=$HOME/admin.conf


$ kubectl apply -f /opt/weave-kube.yaml
serviceaccount/weave-net created
clusterrole.rbac.authorization.k8s.io/weave-net created
clusterrolebinding.rbac.authorization.k8s.io/weave-net created
role.rbac.authorization.k8s.io/weave-net created
rolebinding.rbac.authorization.k8s.io/weave-net created
daemonset.apps/weave-net created

$ kubectl get pod -n kube-system
NAME                                   READY   STATUS    RESTARTS   AGE
coredns-fb8b8dccf-nq4sc                1/1     Running   0          2m41s
coredns-fb8b8dccf-wwb25                1/1     Running   0          2m41s
etcd-controlplane                      1/1     Running   0          98s
kube-apiserver-controlplane            1/1     Running   0          110s
kube-controller-manager-controlplane   1/1     Running   0          98s
kube-proxy-8tvbq                       1/1     Running   0          2m41s
kube-scheduler-controlplane            1/1     Running   1          118s
weave-net-xx6dc                        2/2     Running   0          34s

# On the second node, run the command to join the cluster providing the IP address of the Master node.
$ kubeadm join --discovery-token-unsafe-skip-ca-verification --token=102952.1a7dd4cc8d1f4cc5 172.17.0.56:6443
 
$ kubectl create deployment http --image=katacoda/docker-http-server:latest
```









## 参考链接

https://kubernetes.io/zh/docs/tasks/tools/install-kubectl/
https://blog.csdn.net/wangtonglin2009/article/details/79024820
https://blog.csdn.net/weixin_43420337/article/details/88571744
https://blog.csdn.net/wt334502157/article/details/83992120
https://blog.csdn.net/liuyunshengsir/article/details/89525458
https://blog.csdn.net/liumiaocn/article/details/104144132

https://blog.csdn.net/weixin_30649641/article/details/96451363



> https://github.com/liuyi01/kubernetes-starter

