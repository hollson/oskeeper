# awesome

### Docker基础镜像

| 标签     | 说明   |
| :------- | :------- |
| bookworm | [Debian 12](https://wiki.debian.org/DebianBookworm) 下一代版本，预计2023年发布 |
| bullseye | [Debian 11](https://wiki.debian.org/DebianBullseye) 稳定(stable)版 2021 |
| buster   | [Debian 10](https://wiki.debian.org/DebianBuster)，当前的稳定(stable)版 2019  |
| stretch  | [Debian 9](https://wiki.debian.org/DebianStretch)，旧的稳定版, 长期支持 2017, 除LTS其他版本已经不再支持 |
| jessie   | [Debian 8](https://wiki.debian.org/DebianJessie)，旧的稳定版，即将淘汰 2015 |
| alpine   | [Alpine操作系统](https://alpinelinux.org/) 是一个独立发行版本，更加轻巧 |
| slim     | 瘦身版，删除了许多非必需软件|

```shell
docker pull ubuntu:20.04
docker pull ubuntu:18.04

docker pull debian:bullseye-slim
docker pull debian:buster-slim
docker pull debian:bullseye
docker pull debian:buster
docker pull debian:stretch

docker pull centos:centos8.3.2011
docker pull centos:centos7.9.2009

docker pull alpine:latest
docker pull alpine:edge
```

```shell
docker image prune -f
docker images|grep deepin|xargs docker prune -fa
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

# Dockerfile

```shell
# copy: 拷贝目录下的内容
COPY ./deploy .

# add: 1.下载远程文件; 2.添加本地文件并解压
ADD http://download.redis.io/releases/redis-5.0.4.tar.gz .
ADD nginx-1.22.0.tar.gz .
```

## Docker命令

```shell
# 指定多个端口
docker run -d --name hello -p 8080:8080 -p 1443:443 hello:v1.0
# 使用随机端口
docker run -d --name hello -P hello:v1.0

# 查看容器端口
docker port hello

# 查看完整信息
docker history hello --no-trunc=true
```

## 端口

```shell
https://www.cnblogs.com/wang_yb/p/14593606.html
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

时区：https://www.cnblogs.com/yqmcu/p/16080476.html
https://www.jianshu.com/p/d770a19e39c3




## 参考链接
https://blog.csdn.net/pengzhouzhou/article/details/81740491

https://blog.csdn.net/xchenhao/article/details/122765083



```shell
docker search mysql --limit 5 --filter 'is-official=true' --no-trunc
```
<!-- docker安装Harbor -->
http://www.dockone.io/article/8163
https://www.cnblogs.com/andyxie/p/16531567.html


// docker push hollson/hello:v1.0
// https://www.cnblogs.com/andyxie/p/16531567.html
// https://github.com/goharbor/harbor/releases/
// https://www.jianshu.com/p/2204b8285abe
// https://blog.csdn.net/qq_27022339/article/details/121356730
// https://blog.csdn.net/weixin_44491423/article/details/123328511
// http://www.srcmini.com/23626.html
// https://blog.csdn.net/weixin_41020960/article/details/119757505