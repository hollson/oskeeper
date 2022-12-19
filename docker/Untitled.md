

## 一. 基础命令：

**3. `RUN`**：指定`镜像构建时的指令`

- shell模式：`RUN <command>`
- exec模式：`RUN ["executable","param1","param2"] `
- 每一条run指令都会构建一层新镜像

```shell
# shell模式
RUN echo hello


# exec模式(可以指定其他形式的shell)
RUN ["/bin/bash","-c","echo hello"]
```
**4. `EXPOSR`**：指定容器端口

- 可以指定多个端口，如`EXPOSE <port> [<port>...]`，也可以使用`多个EXPOSE`命令。
- EXPOSE只是指定了容器会使用的特定端口，但不会自动打开，仍需在运行时添加端口的映射。

**5. `CMD`**：指定`容器运行时命令`
- shell模式：`CMD <command> param1 param2`
- exec模式：`CMD ["executable","param1","param2"] `
- 参数模式：`CMD ["param1","param2"]`,作为`ENTRYPOINT`的默认参数。
- CMD命令指定了容器运行时的`默认行为`，会被`docker run`指定的命令覆盖。


**6. `ENTRYPOINT`**：指定`容器运行时命令` 
- shell模式：`ENTRYPOINT <command> param1 param2`
- exec模式：`ENTRYPOINT ["executable","param1","param2"] `
- **与CMD命令一致**，只是默认不会被`docker run` 覆盖，强行覆盖用`docker run --entrypoint`。


_组合使用案例1:_
```shell
FROM centos
MAINTAINER allocator
RUN yum install -y nginx
RUN echo 'hello world' > /usr/share/nginx/html/index.html
EXPOSE 80
ENTRYPOINT ["/usr/sbin/nginx"]
```
```shell
docker run --name test -p 5000:80 -it test_nginx -g "daemon off"
```
_组合使用案例2:_
```shell
ENTRYPOINT ["/usr/sbin/nginx"]
# CMD只提供参数
CMD ["-h"]
```

**7. `ADD`**：文件拷贝
- `ADD <src> ...<dest>`或`ADD ["<src>"..."<dest>"]`
- **src**是本地`相对地址`或远程URL(一般建议使用CURL等命令获取远程文件)，**dest**指向容器的`绝对路径`。
- ADD包含类似tar的解压功能，单纯的文件复制，**推荐使用COPY命令**。


**8. `COPY`**：文件拷贝
- `COPY <src> ...<dest>`或`COPY ["<src>"..."<dest>"]`



**9. `VOLUME`**：向容器添加数据卷



**10. `WORKDIR`**：设定容器内的工作目录

- CMD命令和ENTRYPOINT命令都在此目录下执行。
- WORKDIR使用绝对路径(使用相对路径，工作目录会向下传递)。


**11. `ENV`**：设置容器内环境变量

- `ENV <key> <value>`
- `ENV <key>=<value> ...`


**12. `USER`**：指定用户(默认root)

-  指定用户：`USER daemon`，`USER nginx`
- 指定用户与组的组合：如`USER user:group`，可以是`user，uid，group，gid`的任意组合。


**13. `ONBUILD`**：触发器
- `ONBUILD [INSTRUCTION]`,当被作为基础镜像，在子镜像构建时触发执行。


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
**3. 构建缓存**

- Docker的构建会将上一层镜像视为缓存，每一次的构建会看到“Using cache”的标识。
- 使用`docker build --no-cache`可设置不使用缓存。
- 使用`ENV REFRESH 2019-01-01`, 通过修改刷新时间，跳过缓存
```shell
FROM alpine:latest
RUN ...
ENV REFRESH 2019-01-01`        #从这条命令以后，不使用缓存

...
```
**4. 构建历史**

```shell
docker history <image-id>    #查看完整的镜像构建过程
```
<br/>

## 三. 忽略文件

```shell
$ touch .dockerignore
```
```shell
#comment


#代表根目录（上下文环境目录中）中以abc开头的任意直接子目录或者直接子文件将被忽略
#如/abc abc.txt
/abc*


#代表根目录（上下文环境目录中）中任意直接子目录中以abc开头的任意直接子目录或者直接子文件将被忽略
#如 /file/abc /file/abc.txt
*/abc*


#代表根目录（上下文环境目录中）中任意两级目录下以abc开头的任意直接子目录或者直接子文件将被忽略
#如 /file1/file2/abc /file1/file2/abc.txt
*/*/abc*


#排除根目录中的文件和目录，其名称是单字符扩展名temp。例如，/tempa与/tempb被排除在外。
temp? 


#Docker还支持一个**匹配任意数量目录（包括零）的特殊通配符字符串
**/abc*


# 以感叹号表示不忽略
!README.md


#异常规则的放置位置会影响行为
*.md
!README*.md
README-secret.md
#README-secret.md 仍然会被忽略
    
*.md
README-secret.md
!README*.md
#README-secret.md 不会被忽略


您甚至可以使用该.dockerignore文件来排除Dockerfile和.dockerignore文件。这些文件仍然发送到守护程序，因为它需要它们来完成它的工作。但是ADD和COPY命令不会将它们复制到图像中。
```
```txt

## 忽略文件
**/
!/*linux.amd64.prod
!/conf

*.md
!README.md
.dockerignore

```
<br/>





```shell
docker run --rm alpine echo 'hello world'
docker run --rm -ti alpine sh

echo "https://mirror.tuna.tsinghua.edu.cn/alpine/edge/main" > /etc/apk/repositories
echo "https://mirror.tuna.tsinghua.edu.cn/alpine/edge/releases" >> /etc/apk/repositories


echo "https://dl-4.alpinelinux.org/alpine/edge/releases" >> /etc/apk/repositories

 https://dl-cdn.alpinelinux.org/alpine/v3.16/main
 
```




> 参考：
> https://blog.csdn.net/Allocator/article/details/70490218