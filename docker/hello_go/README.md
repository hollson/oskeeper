# HelloGo
Golang项目镜像构建示例，可用于CICD


# 构建
```shell
# 查看基础镜像中的Go版本
docker run -ti --rm golang:alpine go version

# 构建Docker镜像
docker build -t hello_go:1.0 .
docker run -d --name hello_go -p 1080:80 hello_go:1.0
```


# 验证
```shell
curl http://localhost:1080
```