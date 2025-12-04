```shell
# 下载安装
https://github.com/redis-windows/redis-windows

# 创建服务
# --service-run:可选
sc.exe create RedisService binPath= "D:\program\Redis\redis-server.exe --service-run D:\program\Redis\redis.windows.conf" start= auto
sc.exe description RedisService "这是一个运行在Windows上的Redis服务实例。"

# 启动服务
redis-server.exe --service-start
redis-server.exe --service-stop
redis-cli --version
redis-cli ping

# 停止服务
sc stop "RedisService"
sc delete "RedisService"
```

