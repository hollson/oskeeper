# HelloDotnet
Dotnet项目镜像构建示例，可用于CICD

<br/>

## 构建镜像
> 
```shell
docker build -t hello_dotnet:1.0 .
docker run -d --name hello_dotnet -p 1080:80 hello_dotnet:1.0

# 自定义网络
# docker network create --driver bridge --subnet 192.168.0.0/16 --gateway 192.168.0.1 mynet
```

<br/>

## 容器信息
```shell
docker exec -ti hello_dotnet ls -lh
docker exec -ti hello_dotnet env
```

<br/>

## 验证服务
- [http://localhost:1080](http://localhost:1080)
- [http://localhost:1080/inspect](http://localhost:1080/inspect)
- [http://localhost:1080/swagger](http://localhost:1080/swagger)