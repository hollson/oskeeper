```shell
# 启动容器，privileged：特权
docker run -itd --privileged --name ubt -p 2000:22 \
--hostname shs -e TZ=Asia/Shanghai ubuntu

# 进入容器
docker exec -ti ubt /bin/bash
```

