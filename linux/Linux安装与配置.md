[TOC]

##  1. Linux家族

- [Unix家族](http://blog.chinaunix.net/attachment/201104/16/16361381_13029678418s7r.gif)成员包括`Unix(惠普、IBM)`、`BSD(gnu、sun、macos)`和`UnixLike(minix、Linux)`
- [Linux家族](https://blog.csdn.net/qq_29753285/article/details/81455782)包括`Redhat（redhat、fodara[费多拉]、centos）`和`Debian（ubuntu、Kali）`



## 2. 安装虚拟机

- **安装Centos虚拟机：** [虚拟机安装参考1](http://www.cnblogs.com/sanduzxcvbnm/p/5948158.html)、[虚拟机安装参考2](https://blog.csdn.net/tiandixuanwuliang/article/details/81283316)

- **安装Macos虚拟机：** [Macos虚拟机安装参考1](https://www.jianshu.com/p/ee59b95e391a)、[Macos虚拟机安装参考2](https://www.jianshu.com/p/dea92fbf00a4) 

- 下载Centos镜像：http://mirrors.aliyun.com/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso
  



##  3. 升级内核

>   **仅限Centos7**，更过信息可参考：[Linux内核官网](https://www.kernel.org/)或https://github.com/torvalds/linux/releases。

```shell
# 查看内核版本 
uname -r

# 导入KEY
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

# 安装elrepo的yum源
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

# 安装内核
yum --enablerepo=elrepo-kernel install kernel-ml-devel kernel-ml -y

# 调整启动顺序
awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
grub2-set-default 0

# 重启
reboot

# 删除旧版本
$ yum remove kernel
```



## 4. 配置Gcc

```shell
yum install -y readline readline-devel
yum install -y gcc-c++
yum install -y pcre pcre-devel
yum install -y zlib zlib-devel
yum install -y openssl openssl-devel
```



##  5. 修改时区
```shell
# 设置时区
timedatectl set-timezone Asia/Shanghai
# timedatectl set-time '2020-01-04 15:05:05'  #手动设置时间
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


## 6. 更改yum源

```shell
$ cd /etc/yum.repos.d/ && cp ./CentOS-Base.repo ./CentOS-Base.repo.bak #备份
# wget http://mirrors.163.com/.help/CentOS7-Base-163.repo -O CentOS-Base.repo  #163源
$ wget http://mirrors.aliyun.com/repo/Centos-7.repo -O CentOS-Base.repo  #阿里源
$ yum clean all  #清理旧包
$ yum makecache && yum update #生成缓存并更新
```



## 7. 修改主机名

```shell
$ hostnamectl --help
$ hostnamectl  #查看主机信息
$ hostnamectl set-hostname myserver  #同时更改三种主机名
$ reboot  #重启后永久生效

$ hostname  #查看主机名
$ hostname -i  #查看本机对应的IP
```



## 参考链接：

> 参考：
> https://www.kernel.org  Linux内核发行版







