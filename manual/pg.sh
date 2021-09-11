Hello    # 服务器握手
Role     # 实例角色
Time     # 当前时间
Shutdown # 关闭服务器

Debug Object   # 获取 key 的调试信息
Debug Segfault # 让 Redis 服务崩溃
Monitor        # 实时打印出 Redis 服务器接收到的命令，调试用
Flushdb        # 删除当前数据库的所有key
Showlog        # 管理 redis 的慢日志
Lastsave       # 返回最近一次 Redis 成功将数据保存到磁盘上的时间，以 UNIX 时间戳格式表示
Save           # 异步保存数据到硬盘
Bgsave

Slaveof       # 将当前服务器转变为指定服务器的从属服务器(slave server)
Flushall      # 删除所有数据库的所有key
Dbsize        # 返回当前数据库的 key 的数量
Bgrewriteaof  # 异步执行一个 AOF（AppendOnly File） 文件重写操作
Cluster Slots # 获取集群节点的映射数组

Sync # 用于复制功能(replication)的内部命令

Command         # 获取 Redis 命令详情数组
Command Count   # 获取 Redis 命令总数
Command Getkeys # 获取给定命令的所有键
Command Info    # 获取指定 Redis 命令描述的数组

Info # 获取 Redis 服务器的各种信息和统计数值

# 配置信息
Config Set       # 修改 redis 配置参数，无需重启
Config Get       # 获取指定配置参数的值
Config rewrite   # 对启动 Redis 服务器时所指定的 redis.conf 配置文件进行改写
Config Resetstat # 重置 INFO 命令中的某些统计数据

# 链接信息
Client Setname # 设置当前连接的名称
Client Getname # 获取连接的名称
Client List    # 获取连接到服务器的客户端连接列表
Client Pause   # 在指定时间内终止运行来自客户端的命令
Client Kill    # 关闭客户端连接
