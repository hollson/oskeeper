[TOC]







## Ubuntu镜像

```shell
# 下载镜像并查看Ubuntu版本(大概78M)
docker pull ubuntu
docker run --rm ubuntu:latest cat /etc/os-release|grep VERSION

# 启动容器
# privileged: 特权模式，可以访问主机的所有资源
docker run --privileged -itd --name ubuntu -p 2222:22 --hostname dev -e TZ=Asia/Shanghai ubuntu:latest

# 执行容器命令
docker exec -ti ubuntu bash

# 安装必要的软件
apt update
apt install -y initscripts  	# 系统初始化和服务管理
apt install -y openssh-server
apt install -y passwd
apt install -y ntpdate  		# 同步时间
apt install -y net-tools
apt install -y iputils-ping
apt install -y vim
apt install -y curl
apt install -y netcat
apt install -y tree

# 多个服务待验证
apt install -y nginx
apt install -y redis


docker exec ubuntu date -R  #查看时间和时区
```



## Debain系统

| 系统代号 | 版本说明 |
| :------- | :------- |
| bookworm | [Debian 12](https://wiki.debian.org/DebianBookworm) 最新版本，2023年6月发布 |
| bullseye | [Debian 11](https://wiki.debian.org/DebianBullseye) 稳定(stable)版 2021 |
| buster   | [Debian 10](https://wiki.debian.org/DebianBuster) 稳定(stable)版 2019  |
| slim     | 瘦身版，删除了许多非必需软件|

```shell
# 下载镜像
docker pull debian:bookworm
docker pull debian:bookworm-slim

# 查看版本即代号
docker run --rm debian:bookworm cat /etc/os-release|grep VERSION
```



```shell
# 镜像分层
docker image inspect -f {{.RootFS}} alpine
{layers [sha256:994393dc58e7931862558d06e46aa2bb17487044f670f310dffe1d24e4d1eec7] }

# 容器分层
docker inspect alpine --format={{.GraphDriver}}
{map[
    MergedDir:/var/lib/docker/overlay2/f69a7dcea...ea2403/merged 
    UpperDir:/var/lib/docker/overlay2/f69a7dcea...ea2403/diff 
    WorkDir:/var/lib/docker/overlay2/f69a7dcea...ea2403/work] overlay2}
```

```shell
$ docker image ls --format "{{.ID}} {{.Size}}"
$ docker image ls --format "{{.Repository}}:{{.Tag}}"
$ docker image ls --filter=reference="*:latest"
$ docker image ls --filter dangling=true  # 悬空镜像
```



## Docker命令

```shell
# 查看完整信息
docker history hello --no-trunc=true
```



## 安装软件

```shell
RUN apk --update add --no-cache
apk add openssl curl ca-certificates

RUN echo "https://mirror.tuna.tsinghua.edu.cn/alpine/edge/releases" >> /etc/apk/repositories
RUN apk add vim


#https://www.cnblogs.com/youxin/p/16182107.html
#//https://blog.csdn.net/W_LTCY/article/details/121901862
#RUN echo "https://mirrors.ustc.edu.cn/alpine/edge/releases" >> /etc/apk/repositories
#RUN echo "https://mirrors.aliyun.com/alpine/edge/releases" >> /etc/apk/repositories
#RUN echo "https://mirror.tuna.tsinghua.edu.cn/alpine/edge/releases" >> /etc/apk/repositories
#RUN echo "https://dl-4.alpinelinux.org/alpine/edge/releases" >> /etc/apk/repositories
```





## 时区

```dockerfile
# 在线安装(龟速)
ENV TZ=Asia/Shanghai
RUN apk add tzdata --no-install-recommends \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && apk del tzdata

# 拷贝宿主机(推荐)
# Docker只能读取当前目录，所以提前将zonneinfo拷贝到当前相关目录
ADD ./asset/Shanghai /usr/share/zoneinfo/Asia/Shanghai
ENV TZ=Asia/Shanghai
RUN echo ${TZ} > /etc/timezone
```

```shell
# 外部添加
docker cp /usr/share/zoneinfo/Asia/Shanghai <container>:/usr/share/zoneinfo/Asia/Shanghai

docker run -d --name hello \
	-v  /usr/share/zoneinfo:/usr/share/zoneinfo \
	-v  /etc/timezone:/etc/timezone \
	-p 8080:8080 \
	hello:v1.0 
```

时区：

https://www.cnblogs.com/yqmcu/p/16080476.html

https://www.jianshu.com/p/d770a19e39c3







## 参考链接

https://blog.csdn.net/pengzhouzhou/article/details/81740491

https://blog.csdn.net/xchenhao/article/details/122765083

https://cloud.tencent.com/developer/article/1367035


```shell
docker search mysql --limit 5 --filter 'is-official=true' --no-trunc
```


http://www.dockone.io/article/8163

https://www.cnblogs.com/andyxie/p/16531567.html

https://www.cnblogs.com/andyxie/p/16531567.html

https://github.com/goharbor/harbor/releases/

https://www.jianshu.com/p/2204b8285abe

https://blog.csdn.net/qq_27022339/article/details/121356730

https://blog.csdn.net/weixin_44491423/article/details/123328511

http://www.srcmini.com/23626.html

https://blog.csdn.net/weixin_41020960/article/details/119757505

