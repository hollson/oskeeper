

# 一. 基础命令

## 2. ADD/COPY
```shell
COPY [--chown=<user>:<group>] <src> ... <dest>
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]
```
```dockerfile
FROM ubuntu:latest
WORKDIR /app

COPY ./asset .			# 拷贝目录下的内容到容器
COPY ./a.txt ./b.txt ./	# 拷贝多个文件到容器

# ADD: 两种方式 
# 1.下载远程文件; 
# 2.添加本地文件并解压
ADD http://download.redis.io/releases/redis-5.0.4.tar.gz .
ADD deploy.tar.gz .
```
> 切换目录并压缩：`tar -zcvf deploy.tar.gz -C ./deploy ./`

<br/>

## 3. ENV
```shell
FROM alpine

# 环境变量(两种格式)
#ENV <key> <value>
#ENV <key>=<value> ...
ENV APP_NAME=Awesome APP_VERSION="1.0.0"
```
```shell
docker build -t hello .
docker run --rm hello env
```

<br/>

## 4. ARG
> ARG不会进入构建映像。所以可能，不应该担心由 ARG 引起的层数。
```dockerfile
FROM alpine

# 定义变量
ARG APP_HOME=/app

# 传入变量
ARG Version
ARG Commit
# ARG Built

WORKDIR ${APP_HOME}
COPY ./deploy .

RUN touch ${APP_HOME}/a.txt && \
    echo ${Commit} >> ${APP_HOME}/a.txt && \
    echo ${Version} >> ${APP_HOME}/a.txt
```

```shell
docker build --build-arg Version=v1.0 --build-arg Commit=$(git rev-parse --short HEAD) -t hello .
docker run --rm hello cat ./a.txt
```

<br/>

## 5. EXPOSR
```shell
# 1.查看镜像内应用端口
# 2.随机端口映射必须设定
EXPOSE 1443 8080
```
```shell
# 要启动容器，但不知道镜像内端口怎么办？
docker inspect hello:1.0 -f {{.Config.ExposedPorts}}
docker history hello:1.0|grep EXPOSE
```

<br/>



## 6. VOLUME

```shell
VOLUME ./asset ./asset
VOLUME ["/opt","/opt"]

#在宿主机/var/lib/docker/volumes目录下创建匿名卷，并映射到容器
VOLUME ["/app/data"]
```

<br/>



## 7. RUN

> 构建时命令
```dockerfile
# 默认命令解释器
RUN touch hello.txt

# 特定命令解释器
RUN ["/bin/sh","-c","echo 'hello world' >/opt/hello.txt"]
```

```shell
docker run --rm hello cat /opt/hello.txt
```



<br/>

## 8. CMD/ENTRYPOINT
> `CMD`是**运行时(默认)命令或参数**，会被命令行参数覆盖
>
> `ENTRYPOINT`是**强制运行时命令**,其他CMD都会失效

```Dockerfile
# 默认运行时命令
CMD echo "hello docker"

# 强制运行时命令
ENTRYPOINT echo "hello god"
```
_运行时命令只会执行最后一条, 即存在多条CMD时，仅后有一条有效_
```shell
docker run --rm hello:latest				# 默认CMD命令
docker run --rm hello:latest echo "hello world"		# 覆盖默认命令
docker run --rm hello:latest sh -c "echo hello world"	# 脚本解析
```
<br/>

> `ENTRYPOINT`和`CMD`可**组合使用**，`CMD`仅提供默认参数

```shell
FROM alpine
ENTRYPOINT ["/bin/ls","/"]

# CMD仅提供默认参数
CMD ["-l"]
```

```shell
docker run --rm hello -lh	#进覆盖默认CMD参数
```

<br/>



## 9. LABEL
> LABEL为镜像增加**元数据**，一个LABEL是键值对，多个键值对之间使用空格分开，命令换行时是使用反斜杠。
>
> 格式：`LABEL <key>=<value> <key>=<value> <key>=<value> ...`

```dockerfile
FROM scratch

LABEL "nick"="hollson"
LABEL email="hollson@qq.com"
LABEL addr="中国 \
 北京"

LABEL app.Name="hello" app.Version="v1.0.0" app.Arch="amd64"
LABEL server.Name="Hello-Server" \
      server.Host="192.168.1.11" \
      server.Port="8080"

# 维护者(推荐)
LABEL Maintainer="Microsoft"
```

```shell
docker build -t hello:latest .
docker inspect hello
docker inspect hello -f {{".Config.Labels"}}
docker inspect hello -f {{".Config.Labels.Maintainer"}}
```

```shell
# 构建者(废弃)
# docker inspect hello:1.0 -f {{.Author}}
MAINTAINER Microsoft

# 系统用户，默认为root
# docker inspect hello:1.0 -f {{.Config.User}}
USER postgres
```



<br/>

<br/>



# 二. 多阶段构建

## 1. 最小构建

```shell
# 构建阶段
FROM golang:alpine AS builder
WORKDIR /app
COPY ./main.go ./go.mod ./
RUN go build -ldflags="-s -w" -o hello-server main.go

# 发布阶段
FROM scratch
WORKDIR /app
COPY --from=builder /app/hello-server /app/
CMD ["./hello-server"]
```
```shell
docker build -t hello:latest .
docker run --rm hello
```

<br/>



## 2. 完整实例

> **多阶段构建ARG参数:**
>
>  1. 先在顶部定义ARG参数
>  2. 分别在每个阶段引用ARG

```dockerfile
# 全局参数
ARG version=1.0.0

# 构建阶段
FROM golang:alpine AS builder
WORKDIR /app
COPY ./main.go ./go.mod ./
RUN go build -ldflags="-s -w" -o hello-server main.go

# 发布阶段
FROM alpine
WORKDIR /app
ARG version
RUN echo "${version}" > version
COPY --from=builder /app/hello-server /app/
CMD ["./hello-server"]
```

```shell
docker build -t hello:latest .
docker run --rm hello
docker run --rm hello ls .
docker run --rm hello cat version
```
