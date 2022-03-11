## 准备工作

所有集群节点都进行配置，服务器环境如下： 

-   虚拟机：`VMware Fusion12.1.2`； 
-   操作系统：`CentOS7.6.18`;
-   系统内核：`5.4.173-1.el7.elrepo.x86_64`

| 主机名| IP地址|配置|
| -- | -- |--|
| k8s-master| 10.0.0.11 |2核2G|
| K8s-node1 | 10.0.0.12 | 1核1G |
| K8s-node2 | 10.0.0.13 |1核1G|



### 1. 解析主机名

_在每个集群节点中的hosts中加入主机名映射：_

```shell
cat <<EOF >> /etc/hosts
10.0.0.11 k8s-master	# K8s主节点
10.0.0.12 k8s-node1		# K8s从节点
10.0.0.13 k8s-node2		# K8s从节点
EOF
```
_分别修改主机名：_
```shell
hostnamectl set-hostname k8s-master	 # 在master上执行
hostnamectl set-hostname k8s-node1	 # 在node1上执行
hostnamectl set-hostname k8s-node2	 # 在node2上执行
```



### 2. 同步时间

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



### 3. 关闭防火墙

_关闭`firewalld`或`iptables`服务_

```shell
# firewalld
systemctl stop firewalld 
systemctl disable firewallld

# iptables
systemctl stop iptables
systemctl disable iptables
```



### 4. 禁用selinux

_selinux是linux系统下的一个安全服务，可能引发一些问题_

```shell
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
setenforce 0
```



### 5. 禁用swap分区

_Kubernetes v1.8+要求关闭系统 Swap，Swap指虚拟内存分区_

```shell
# 注释swap相关的行
sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a
sysctl -w vm.swappiness=0
```



### 6. 配置网桥转发

_将桥接的IPv4流量传递到iptables的链_

```shell
cat <<EOF >/etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# 重新加载
sysctl --system

# 加载过滤模块
modprobe br_netfilter

# 查看是否成功
lsmod | grep br_netfilter	
```



### 7. 配置ipvs功能

_在K8s中kube-proxy有**iptables**和**ipvs**两种代理模型，ipvs性能较高，但需要手动载入ipset和ipvsadm模块_

```shell
# ⚠️ 系统内核为4.19+时，执行此操作
yum install -y ipset ipvsadm
cat <<EOF > /etc/sysconfig/modules/ipvs.modules
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules
bash /etc/sysconfig/modules/ipvs.modules
lsmod|grep -e ip_vs -e nf_conntrack
```

```shell
# ⚠️ 系统内核低于4.19，执行此操作
yum install -y ipset ipvsadm
cat <<EOF > /etc/sysconfig/modules/ipvs.modules
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
nf_conntrack
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules
bash /etc/sysconfig/modules/ipvs.modules 
lsmod|grep -e ip_vs -e nf_conntrack_ipv4
```

```shell
# 最后重启服务器
reboot
```



## 安装Docker

_docker是K8s集群的基础服务组件，需在每个集群节点上安装docker服务，安装流程可参考[**Docker安装教程**](https://blog.csdn.net/Gusand/article/details/102714104#t3)。_

K8s推荐的Cgroup是`systemd`, 修改Docker的`Cgroup Driver`：

```shell
# 查看docker的Cgroup Driver，默认为cgroupfs
docker info|grep Cgroup

# 修改Cgroup,若daemon.json不存在，则手动创建
cat /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}

# 重启服务
systemctl daemon-reload
systemctl restart docker
```



## 安装Node组件

_在所有服务节点上安装**kubeadm,  kubelet和kubectl**。_

```shell
# 配置阿里云yum仓库
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 查看可用的版本
yum list kubectl --showduplicates

# 注意⚠️：如果仅安装kubeadm，则会自动安装最新版本kubelet和kubectl
yum -y install kubeadm-1.22.6 kubelet-1.22.6 kubectl-1.22.6

# 注意⚠️：将添加到启动项，无需启动
systemctl enable kubelet
systemctl status kubelet

# 查看版本
kubeadm version
kubectl version
kubelet --version
```
_修改kubelet的Cgroup:_
```shell
# 修改kubelet的Cgroup
cat <<EOF > /etc/sysconfig/kubelet
KUBELET_CGROUP_ARGS="--cgroup-driver=systemd"
KUBE_PROXY_MODE="ipvs"
EOF
```



## 配置Master服务

```shell
# 查看kubeadm使用的镜像
kubeadm config images list

# 可预先拉取镜像，或下一步init时自动拉取
# kubeadm config images pull
kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers
```

```shell
# 注意⚠️：只需修改第一项的IP，其余不用动
kubeadm init \
--apiserver-advertise-address=10.0.0.11 \
--image-repository registry.aliyuncs.com/google_containers \
--kubernetes-version=v1.22.6 \
--pod-network-cidr=10.244.0.0/16 \
--service-cidr=10.96.0.0/12

# 🔔 此时，会得到「kubeadm join」的token信息😊😊😊

# 使用kubectl工具
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```



## 加入Node节点

_在Node节点执行`kubeadm join`命令，将node加入集群。_

```shell
# 在master节点获取token，同「kubeadm init」得到的token信息
kubeadm token create --print-join-command --ttl 0

kubeadm join 10.0.0.11:6443 --token 05mmas.1kl...dz --discovery-token-ca-cert-hash sha256:16752bf...9c1e2f3c6
```



## 部署CNI网络组件

_Kubernetes支持多种网络插件，如 **flannel、calico、canal**等，这里选择使用「**flannel**」_

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



## 测试Nginx服务

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



## 总结
> 安装异常，可执行`journalctl -xefu kubelet` 查看日志

-   master推荐最小配置为**1核心2G**，否则会出现以下错误！

```shell
[ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
[ERROR Mem]: the system RAM (947 MB) is less than the minimum 1700 MB
```

-   必须配置hostname和hosts，且名称必须对应一致。

```shell
[WARNING Hostname]: hostname "XXX" could not be reached
[WARNING Hostname]: hostname "XXX": lookup vm02 on 114.114.114.114:53: no such host
```



## 参考资料

https://huangzhongde.cn/istio/Chapter2/Chapter2-4.html

https://www.cnblogs.com/xuweiweiwoaini/p/13884112.html

https://gitee.com/ylp657/kubernetes/tree/master#kubernetes

