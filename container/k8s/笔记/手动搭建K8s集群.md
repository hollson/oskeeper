## 准备工作





### 5. 禁用swap分区

_Kubernetes v1.8+要求关闭系统 Swap，Swap指虚拟内存分区_

```shell
# 永久关闭
sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

# 临时关闭
swapoff -a
free -h
```



### 6. 配置网桥转发???

_将桥接的IPv4流量传递到iptables的链_

```shell
cat <<EOF >/etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system             # 重新加载
modprobe br_netfilter       # 加载过滤模块
lsmod | grep br_netfilter   # 查看是否成功
```

- 配置阿里云yum仓库

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





### 8. 配置ipvs功能

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
# 设置下次开机自动加载
cat > /etc/modules-load.d/ip_vs.conf << EOF 
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
EOF
```

```shell
# 最后重启服务器
reboot
```



## 安装containerd服务

在所有节点上安装 **docker/containerd** 服务，参考[**Docker安装教程**](https://blog.csdn.net/Gusand/article/details/102714104)，并做如下修改：

> containerd配置文件为: `/etc/containerd/config.toml`
>
> docker配置文件为：`/etc/docker/daemon.json`
>
> containerd的**SystemdCgroup = true** 配置项优先级高于docker 中的**cgroupdriver**。

```shell
# 停止docker、containerd服务，修改配置
systemctl stop containerd.service
cp /etc/containerd/config.toml /etc/containerd/config.toml.bak
containerd config default > /etc/containerd/config2.toml

sed -i "s#registry.k8s.io/pause#registry.cn-hangzhou.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml
sed -i "s#SystemdCgroup = false#SystemdCgroup = true#g" /etc/containerd/config.toml


# 修改sandbox_image 镜像源，1.24以下k8s.gcr.io 、1.25 改成了registry.k8s.io
sed -i "s#registry.k8s.io/pause#registry.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml


# containerd 忽略证书验证的配置
#      [plugins."io.containerd.grpc.v1.cri".registry.configs]
#        [plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.0.12:8001".tls]
#          insecure_skip_verify = true

# 镜像加速
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://qclq5rqa.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl daemon-reload
systemctl enable --now containerd.service
systemctl enable --now docker.service
systemctl enable --now docker.socket

systemctl list-unit-files | grep docker

docker info|grep Cgroup
systemctl status docker.service
systemctl status containerd.service
```



## 安装Kubernetes

在所有服务节点上安装**kubeadm,  kubelet和kubectl**。

- 安装K8s服务

_kubernetes 1.24+版本之后，docker必须要加装cir-docker,dockershim已经从kubelet中移除。_

```shell
# 查看可用的版本：
# yum --showduplicates list kubelet --nogpgcheck
# yum --showduplicates list kubeadm --nogpgcheck
# yum --showduplicates list kubectl --nogpgcheck
# yum --showduplicates list  cri-tools --nogpgcheck

# OK
yum install -y kubelet-1.22.6-0 kubeadm-1.22.6-0 kubectl-1.22.6-0 --disableexcludes=kubernetes --nogpgcheck

yum install -y kubelet-1.23.8-0 kubeadm-1.23.8-0 kubectl-1.23.8-0 --disableexcludes=kubernetes --nogpgcheck

# 2023-02-07，经过测试，版本号：1.24.0，同样适用于本文章
# sudo yum install -y kubelet-1.24.0-0 kubeadm-1.24.0-0 kubectl-1.24.0-0 --disableexcludes=kubernetes --nogpgcheck

# 2023-03-02，经过测试，版本号：1.26.2，同样适用于本文章
# disableexcludes=kubernetes: 禁掉除了这个kubernetes之外的别的仓库
yum install -y kubelet-1.26.2-0 kubeadm-1.26.2-0 kubectl-1.26.2-0 --disableexcludes=kubernetes --nogpgcheck

# 安装最新版，生产时不建议
# sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck

systemctl daemon-reload
systemctl enable --now kubelet

# 卸载
# yum -y remove kubeadm kubelet kubectl
```
- 查看服务状态
```shell
# 提示⚠️: 
# K8s当前还未做初始化，所以会提示"kubelet.service: main process exited, code=exited, status=1/FAILURE"错误,
# 在后续"kubeadm init"或"kubeadm join"后会自动解决。
systemctl status kubelet
journalctl -xefu kubelet

# 查看版本
kubeadm version --output=yaml
kubectl version --output=yaml
kubelet --version
```





## 配置Master服务

```shell
# 查看kubeadm使用的镜像
kubeadm config images list

# 可预先拉取镜像，或下一步init时自动拉取
kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers

docker images|grep google_containers
```

```shell
kubeadm reset
rm -fr ~/.kube/  /etc/kubernetes/* var/lib/etcd/*

kubeadm init --image-repository=registry.aliyuncs.com/google_containers

# kubernetes-version:   指定kubenets版本号，默认值是stable-1
# apiserver-advertise-address: 指明用Master的哪个interface与Cluster的其他节点通信。
# pod-network-cidr:     指定Pod网络的范围,10.244.0.0/16即使用flannel网络方案。
# control-plane-endpoint:     cluster-endpoint 是映射到该 IP 的自定义 DNS 名称
kubeadm init \
  --apiserver-advertise-address=$(hostname -i) \
  --image-repository registry.aliyuncs.com/google_containers \
  --kubernetes-version v1.26.2 \
  --service-cidr=10.1.0.0/16 \
  --pod-network-cidr=10.244.0.0/16 \
  --v=5
  

  
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

- fff

```sh
    The connection to the server 10.0.0.11:6443 was refused - did you specify the right host or port?
```

​    

## 参考资料

https://huangzhongde.cn/istio/Chapter2/Chapter2-4.html

https://www.cnblogs.com/xuweiweiwoaini/p/13884112.html

https://gitee.com/ylp657/kubernetes/tree/master#kubernetes

https://github.com/liuyi01/kubernetes-starter

