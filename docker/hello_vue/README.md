# HelloVue
Vue项目镜像构建示例，可用于CICD


# 构建
```shell
docker build -t hello_vue:1.0 .
docker run -p 8080:80 --name hello_vue  -d  hello_vue:1.0
```


# 验证
```shell
curl http://localhost:8080
```