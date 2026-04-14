# 准备工作

所有集群节点都进行配置，服务器环境如下： 

| 主机名| IP|系统|内核|最小配置|
| -- | -- |--|--|--|
| k8s-master| 10.0.0.11 |centos7.9|5.15.5-1.el7.elrepo.x86_64|2核2G|
| K8s-node01 | 10.0.0.12 |centos7.9|5.15.5-1.el7.elrepo.x86_64| 1核1G |
| K8s-node02 | 10.0.0.13 |centos7.9|5.15.5-1.el7.elrepo.x86_64|1核1G|


## 1. 解析主机名

_在每个集群节点中的hosts中加入主机名映射：_

```shell
cat <<EOF >> /etc/hosts
10.0.0.11 k8s-master    # master节点
10.0.0.12 k8s-node01    # worker节点
10.0.0.13 k8s-node02    # worker节点
EOF

cat /etc/hosts
```
_分别修改主机名：_
```shell
hostnamectl set-hostname k8s-master	 # 在master上执行
hostnamectl set-hostname k8s-node01	 # 在node01上执行
hostnamectl set-hostname k8s-node02	 # 在node02上执行
```



## 2. 同步系统时间

```shell
# 设置时区
timedatectl set-timezone Asia/Shanghai
timedatectl

# 安装chrony同步工具
yum makecache fast
yum -y install chrony
systemctl start chroynd
systemctl enable --now chronyd

# 强制同步时间
chronyc -a makestep
date
```



## 3. 关闭防火墙

_关闭`firewalld`或`iptables`服务_

```shell
# firewalld
systemctl stop firewalld 
systemctl disable firewalld

systemctl start firewalld 
firewall-cmd --zone=public --list-ports
systemctl stop firewalld 

# iptables
systemctl stop iptables
systemctl disable iptables
```



## 4. 禁用selinux

_selinux是linux系统下的一个安全服务，可能引发一些问题_

```shell
# 永久关闭
sed -i 's/^SELINUX=.*/SELINUX=Permissive/g' /etc/selinux/config

# 临时关闭
setenforce 0
getenforce
```



## 5. 禁用swap分区

_Kubernetes v1.8+要求关闭系统 Swap，Swap指虚拟内存分区_

```shell
# 永久关闭
sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

# 临时关闭
swapoff -a
free -h
```



## 6. 配置K8s网桥

_将桥接的IPv4流量传递到iptables的链_

```shell
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
vm.swappiness=0
EOF

sysctl --system                   # 重新加载
modprobe br_netfilter             # 加载过滤模块

sysctl -p /etc/sysctl.d/k8s.conf  #使之生效
lsmod | grep br_netfilter         # 查看是否成功
```



## 7.  配置K8s.Yum源

```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```



# 安装配置Docker

在所有节点主机上安装 **docker/containerd** 服务，参考[**Docker安装教程**](https://blog.csdn.net/Gusand/article/details/102714104)，并做如下修改

- 配置Docker服务

```shell
cat <<-'EOF' > /etc/docker/daemon.json
{
  "registry-mirrors": ["https://qclq5rqa.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
```
- 配置Containerd服务
```shell
# 重新生成(覆盖)配置文件
containerd config default > /etc/containerd/config.toml

# 将sandbox_image镜像源设置为阿里云google_containers镜像源
# sed -i "s#registry.k8s.io/pause#registry.aliyuncs.com/google_containers/pause#g" 
sed -i "s#registry.k8s.io/pause#registry.cn-hangzhou.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml

# 并启动SystemdCgroup
sed -i '/SystemdCgroup/s/false/true/g' /etc/containerd/config.toml
```
- 重启服务
```shell
systemctl daemon-reload
systemctl restart containerd.service
systemctl restart docker.service
systemctl restart docker.socket

docker info|grep Cgroup
systemctl status docker.service
systemctl status containerd.service
```

_当前实验版本：Docker：`v20.10.22`；Containerd：`v1.6.18`_



# 安装Kubernetes ???

在**所有服务节点**上安装**kubeadm,  kubelet和kubectl**

_kubernetes 1.24+版本之后，docker必须要加装cir-docker,dockershim已经从kubelet中移除。_

```shell
# 查看可用的版本：
# yum --showduplicates list kubelet --nogpgcheck
# yum --showduplicates list kubeadm --nogpgcheck
# yum --showduplicates list kubectl --nogpgcheck
# yum --showduplicates list  cri-tools --nogpgcheck

# disableexcludes=kubernetes: 禁掉除了这个kubernetes之外的别的仓库
yum install -y kubelet-1.26.2-0 kubeadm-1.26.2-0 kubectl-1.26.2-0 --disableexcludes=kubernetes --nogpgcheck

# 使docker的cgroupdriver与kubelet的cgroup保持一致。
cat <<EOF > /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
EOF

# 启动服务
systemctl daemon-reload
systemctl enable --now kubelet

# 查看版本
kubeadm version --output=json
kubectl version --output=json
kubelet --version

# 卸载
# yum -y remove kubeadm kubelet kubectl
```
- 查看服务状态
```shell
# 提示⚠️: 
# K8s当前还未做初始化，所以会提示"kubelet.service: main process exited, code=exited, status=1/FAILURE"错误,
# 在后续"kubeadm init"或"kubeadm join"后会自动解决。
systemctl status kubelet
# journalctl -xefu kubelet
```



# 集群初始化(Master)

> 初始化控制平面(control-plane) ,及Master服务。

```shell
# 查看kubeadm使用的镜像
kubeadm config images list

# ⚠️ 可预先拉取镜像，或下一步init时自动拉取
kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers
docker images|grep google_containers

# 或使用docker下载
docker pull registry.aliyuncs.com/google_containers/kube-apiserver:v1.24.1
docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:v1.24.1
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:v1.24.1
docker pull registry.aliyuncs.com/google_containers/kube-proxy:v1.24.1
docker pull registry.aliyuncs.com/google_containers/pause:3.7
docker pull registry.aliyuncs.com/google_containers/etcd:3.5.3-0
docker pull registry.aliyuncs.com/google_containers/coredns:v1.8.6
```

```shell
# 简单初始化
kubeadm init --image-repository=registry.aliyuncs.com/google_containers

# 自定义初始化
# kubernetes-version:   	   指定kubenets版本号，默认值是stable-1
# apiserver-advertise-address: 指明用Master的哪个interface与Cluster的其他节点通信。
# pod-network-cidr:     	   指定Pod网络的范围,10.244.0.0/16即使用flannel网络方案。
# control-plane-endpoint:      cluster-endpoint 是映射到该IP的自定义DNS名称
kubeadm init \
  --apiserver-advertise-address=$(hostname -i) \
  --image-repository registry.aliyuncs.com/google_containers \
  --kubernetes-version v1.26.2 \
  --service-cidr=10.1.0.0/16 \
  --pod-network-cidr=10.244.0.0/16 \
  --v=5

# 使用kubectl工具
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```
_初始化成功后输出如下:_

```txt
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.0.11:6443 --token pktv1w.ey1kyzfc0mkiks6d --discovery-token-ca-cert-hash sha256:1da76a7330ca8c2f46b0cd23ffa479cc02d5b8ce5fa656ac187dc64d879c8fd8
```



# 加入Node节点

_在Node节点执行`kubeadm join`命令，将node加入集群。_

```shell
# 提示⚠️：在控制平面(master)上查询Join信息
kubeadm token create --print-join-command --ttl 0

kubeadm join 10.0.0.11:6443 --token xxx --discovery-token-ca-cert-hash sha256:xxx
```

_在Master上查看Node信息：_

```txt
[root@k8s-master ~]# kubectl get nodes
NAME         STATUS     ROLES                  AGE     VERSION
k8s-master   NotReady   control-plane,master   21m     v1.22.6
k8s-node01   NotReady   <none>                 6m13s   v1.22.6
k8s-node02   NotReady   <none>                 3m55s   v1.22.6
```



# 部署CNI网络组件

_Kubernetes支持多种网络组件，如 **flannel、calico、canal**等。_

## flannel

```shell
# master上操作
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 查看pods节点信息（所有节点的状态为：Running，说明正常）
kubectl get pods -n kube-system
kubectl get nodes
```
_查看集群健康状态：_
```shell
kubectl get cs
kubectl cluster-info
```
_示例数据：_
```txt
[root@k8s-master ~]# kubectl get pods -n kube-system
NAME                                 READY   STATUS              RESTARTS   AGE
coredns-7f6cbbb7b8-2gzbl             0/1     ContainerCreating   0          27m
coredns-7f6cbbb7b8-jnl8f             0/1     ContainerCreating   0          27m
etcd-k8s-master                      1/1     Running             0          27m
kube-apiserver-k8s-master            1/1     Running             0          27m
kube-controller-manager-k8s-master   1/1     Running             0          27m
kube-proxy-5p596                     1/1     Running             0          10m
kube-proxy-r2s2q                     1/1     Running             0          27m
kube-proxy-rkfsg                     1/1     Running             0          12m
kube-scheduler-k8s-master            1/1     Running             0          27m
[root@k8s-master ~]# kubectl get nodes
NAME         STATUS     ROLES                  AGE   VERSION
k8s-master   Ready      control-plane,master   28m   v1.22.6
k8s-node01   NotReady   <none>                 12m   v1.22.6
k8s-node02   NotReady   <none>                 10m   v1.22.6
```



## calico

https://www.yuque.com/xuxiaowei-com-cn/gitlab-k8s/k8s-install?singleDoc=#B7zUb

```shell
# 下载
wget --no-check-certificate https://projectcalico.docs.tigera.io/archive/v3.25/manifests/calico.yaml
# 修改 calico.yaml 文件
vim calico.yaml
```

```txt
# 在 - name: CLUSTER_TYPE 下方添加如下内容
- name: CLUSTER_TYPE
  value: "k8s,bgp"
  # 下方为新增内容
- name: IP_AUTODETECTION_METHOD
  value: "interface=网卡名称"

# INTERFACE_NAME=ens33
# sed -i '/k8s,bgp/a \            - name: IP_AUTODETECTION_METHOD\n              value: "interface=INTERFACE_NAME"' calico.yaml
# sed -i "s#INTERFACE_NAME#$INTERFACE_NAME#g" calico.yaml
```

```shell
# 配置网络
kubectl apply -f calico.yaml
```

```shell
[root@k8s ~]# kubectl get nodes -o wide
NAME            STATUS     ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION           CONTAINER-RUNTIME
centos-7-9-16   NotReady   <none>          7m58s   v1.25.3   192.168.0.18    <none>        CentOS Linux 7 (Core)   3.10.0-1160.el7.x86_64   containerd://1.6.9
k8s             NotReady   control-plane   10m     v1.25.3   192.168.80.60   <none>        CentOS Linux 7 (Core)   3.10.0-1160.el7.x86_64   containerd://1.6.9
[root@k8s ~]#
```



# 测试Nginx服务

https://www.yuque.com/xuxiaowei-com-cn/gitlab-k8s/k8s-install?singleDoc=#B7zUb

```shell
[root@k8s-master ~]# kubectl create deployment nginx --image=nginx
deployment.apps/nginx created
[root@k8s-master ~]# kubectl expose deployment nginx --port=80 --type=NodePort
service/nginx exposed
[root@k8s-master ~]# kubectl get pod,svc
NAME                         READY   STATUS              RESTARTS   AGE
pod/nginx-6799fc88d8-6nl9d   0/1     ContainerCreating   0          4s

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        48m
service/nginx        NodePort    10.97.165.25   <none>        80:30211/TCP   4s

# 也可以修改服务配置
[root@k8s-master ~]# export KUBE_EDITOR="vim"
[root@k8s-master ~]# kubectl edit svc nginx
```

访问任意节点上Nginx的Web服务，都会看到熟悉的`Welcome to nginx!` 页面！
> http://10.0.0.11:30211/ 
> http://10.0.0.12:30211/ 
> http://10.0.0.13:30211/



# 常见问题

> 安装异常，可执行`journalctl -xefu kubelet` 查看日志

-   master推荐最小配置为**1核心2G**，否则会出现以下错误！

```shell
[ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
[ERROR Mem]: the system RAM (947 MB) is less than the minimum 1700 MB
```

-   必须配置hostname和hosts，且名称必须对应一致 !

```shell
[WARNING Hostname]: hostname "XXX" could not be reached
[WARNING Hostname]: hostname "XXX": lookup vm02 on 114.114.114.114:53: no such host
```



# 附: 下载离线包

```shell
# 指定版本
sudo yum install kubelet-1.26.2-0 kubectl-1.26.2-0 kubeadm-1.26.2-0 --downloadonly --downloaddir=./k8s-rpm.v1.26.2

# 最新版本
sudo yum install kubelet kubectl kubeadm --downloadonly --downloaddir=./k8s-rpm.latest
```



# 参考资料

https://huangzhongde.cn/istio/Chapter2/Chapter2-4.html

https://www.cnblogs.com/xuweiweiwoaini/p/13884112.html

https://gitee.com/ylp657/kubernetes/tree/master#kubernetes

https://github.com/liuyi01/kubernetes-starter
