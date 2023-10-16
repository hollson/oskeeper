# HelloDotnet
Dotnet项目镜像构建示例，可用于CICD

<br/>

## 构建
```shell
docker build -t hello_dotnet:1.0 .
docker run -d --name hello_dotnet -p 1080:80 hello_dotnet:1.0


#默认网络docker0，它不能用域名访问，所以要创建自定义网络。
docker network create --driver bridge --subnet 192.168.0.0/16 --gateway 192.168.0.1 mynet
```
<br/>

## 验证
- [http://localhost:1080](http://localhost:1080)
```shell
curl http://localhost:1080/hello
curl http://localhost:1080/time
```

docker run -d --name hello_dotnet -p 1080:80 hello_dotnet:1.0