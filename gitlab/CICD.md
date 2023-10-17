## 安装Runner
```shell
docker pull gitlab/gitlab-runner:latest

mkdir -p /data/etc/gitlab-runner
```
```shell
docker run \
--detach \
--name gitlab-runner \
--restart always \
--volume /data/etc/gitlab-runner:/etc/gitlab-runner \
--volume /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest
```

```shell
# 进入gitlab-runner容器
docker exec -it gitlab-runner bash

# 查看gitlab-runner版本
gitlab-runner -v

# 注册
gitlab-runner register
```











https://blog.csdn.net/weixin_39246554/article/details/130749706

https://zhuanlan.zhihu.com/p/652503159