

# 1. 创建CentOS容器

```shell
# 启动容器，privileged：特权
docker run -tid --privileged=true --name centos -p 2022:22 \
--hostname cent -e TZ=Asia/Shanghai centos /usr/sbin/init

# 进入容器
docker exec -ti centos /bin/bash
```



# 2. 配置yum源

- 配置baseos

```shell
vi /etc/yum.repos.d/CentOS-Linux-BaseOS.repo
```

```ini
[baseos]
name=CentOS Linux $releasever - BaseOS
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=BaseOS&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/BaseOS/$basearch/os/
baseurl=https://vault.centos.org/centos/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
```

- 配置appstream

```shell
vi /etc/yum.repos.d/CentOS-Linux-AppStream.repo
```

```ini
[appstream]
name=CentOS Linux $releasever - AppStream
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=AppStream&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/AppStream/$basearch/os/
baseurl=https://vault.centos.org/centos/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
```



# 3. 安装基础软件

```shell
# 安装ssh、passwd、net-tool和vim等
yum install -y openssl openssh-server initscripts passwd net-tools vim
```



# 4. 修改密码

```shell
passwd root
#New password: 123456
```



# 5. 配置sshd

```shell
vi /etc/ssh/sshd_config
```

```shell
PubkeyAuthentication yes 					#启用公钥私钥配对认证方式
AuthorizedKeysFile .ssh/authorized_keys 	#公钥文件路径
PermitRootLogin yes 						#root能使用ssh登录


# 待验证
# Port 22
# AddressFamily any
# ListenAddress 0.0.0.0
```

```shell
# 重启sshd
systemctl restart sshd.service
```

**测试ssh**

```shell
ssh root@0.0.0.0 -p 2022
#123456

ssh-copy-id -i .ssh/id_rsa.pub root@0.0.0.0 -p 2022
```



# 6. 保存镜像

```shell
# https://blog.csdn.net/qq_14945437/article/details/106135369
docker commit -m="个性化扩展" -a="hollson" centos centos:shs
```

```shell
docker run -tid --privileged=true --name centos -p 2022:22 \
--hostname osx centos:shs /usr/sbin/init
```



> 警告⚠️ ：**容器内不可再容器化**

```shell
'overlay' is not supported over overlayfs
```



# 其他操作

**增加端口**

https://blog.csdn.net/lypeng_/article/details/98176138

https://yixiu.blog.csdn.net/article/details/107078157

> 按此方法，是不是也能加label(提示默认密码 default_password)



**瘦身**

```shell
/usr/share/zoneinfo/Asia/Shanghai
```



时区

```shell
docker exec alpine /bin/sh -c "mkdir -p /etc/localtime"
docker cp /usr/share/zoneinfo/Asia/Shanghai alpine:/etc/localtime
docker restart alpine
docker exec alpine /bin/sh -c "date -R"  #查看时间和时区


或
docker run -tid --name alpine -e TZ="Asia/Shanghai" alpine /bin/sh

Dockerfile
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone
```

