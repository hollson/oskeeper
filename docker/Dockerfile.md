

## 一. 基础命令：

## 1. RUN

> 构建时命令

```dockerfile
# 默认命令解释器
RUN touch hello.txt

# 特定命令解释器
RUN ["/bin/bash","-c","touch hello.txt"]
```



## 2. CMD/ENTRYPOINT

> `CMD`是**默认运行时命令**，会被命令行参数覆盖
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
docker run -ti hello:1.0								# 默认CMD命令
docker run -ti hello:1.0 echo "hello world"				# 覆盖默认命令
docker run -ti hello:1.0 sh -c "echo hello world"		# 脚本解析
```
<br/>

> `ENTRYPOINT`和`CMD`可**组合使用**，`CMD`仅提供默认参数

```shell
FROM alpine
ENTRYPOINT ["/bin/ls","/"]
CMD ["-l"]	# CMD仅提供默认参数
```

```shell
docker run -ti hello:1.0 -lh	#进覆盖默认CMD参数
```



## 3. EXPOSR

```shell
# 1.查看镜像内应用端口
# 2.随机端口映射必须设定
EXPOSE 1443 8080

# 要启动容器，但不知道镜像内端口怎么办？
docker inspect hello:1.0 -f {{.Config.ExposedPorts}}
docker history hello:1.0|grep EXPOSE
```



## ADD/COPY

```dockerfile
FROM ubuntu:latest
WORKDIR /app

# COPY: 拷贝目录下的内容
COPY ./asset .

# ADD: 两种方式 
# 1.下载远程文件; 
# 2.添加本地文件并解压
ADD http://download.redis.io/releases/redis-5.0.4.tar.gz .
ADD deploy.tar.gz .
```

> 切换目录并压缩：`tar -zcvf deploy.tar.gz -C ./deploy ./`



**9. `VOLUME`**：向容器添加数据卷

```shell
VOLUME ./asset ./asset
VOLUME ["/opt","/opt"]

#在宿主机/var/lib/docker/volumes目录下创建匿名卷，并映射到容器
VOLUME ["/app/data"]
```




**11. `ENV`**：设置容器内环境变量

- `ENV <key> <value>`
- `ENV <key>=<value> ...`





```shell
# 构建者
# docker inspect hello:1.0 -f {{.Author}}
MAINTAINER Microsoft

# 系统用户，默认为root
# docker inspect hello:1.0 -f {{.Config.User}}
USER postgres
```



<br/>


## 二. 构建镜像
**1. 构建过程**
```txt
从基础镜像运行容器
执行一条命令，对容器作出修改
执行commit，构建一个新的镜像层
基于刚提交的镜像运行一个新容器
再执行下一条命令，反复直至所有命令执行完毕。
```
**2. 构建调试**
- `docker build`会删除中间层容器，但不会删除中间层镜像。
- 可以基于中间层镜像执行`docker run`命令，实现镜像调试。
```shell
docker run -it ea15d18dfeb5 /bin/sh    #ea15d18dfeb5是中间层镜像ID
```




**4. 构建历史**

```shell
docker history <image-id>    #查看完整的镜像构建过程
```
<br/>




