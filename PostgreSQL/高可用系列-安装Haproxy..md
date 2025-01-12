[TOC]
## Haproxy概念

Haproxy提供高可用性、负载均衡以及基于TCP和HTTP应用的代理，支持虚拟主机,类似于`Nginx`。

## 安装配置

**1. 下载安装haproxy**

```shell
HP_Version=2.1.2
wget http://www.haproxy.org/download/2.1/src/haproxy-${HP_Version}.tar.gz
tar -zxvf haproxy-${HP_Version}.tar.gz
cd haproxy-${HP_Version}
```
```shell
uname -r
#根据当前系统配置编译参数(内核版本[x.y.z]、系统架构和安装目录)
make TARGET=linux3100 ARCH=x86_64 PREFIX=/usr/local/haproxy
make install PREFIX=/usr/local/haproxy
```
```shell
# 设置环境变量
cat >> /etc/profile <<EOF
export HAPROXY_HOME=/usr/local/haproxy/
export PATH=\$HAPROXY_HOME/sbin:\$PATH
EOF
source /etc/profile
```

**2. 配置haproxy.cfg**

```shell
vim $HAPROXY_HOME/haproxy.cfg
```

```nginx
global
        maxconn 4096 #默认最大连接数
        daemon  #以后台形式运行harpoxy
        #chroot      /var/lib/haproxy
        pidfile     /var/run/haproxy.pid #haproxy 进程PID文件
        #debug
        #quiet
        nbproc 2 #设置进程数量  
 
defaults
        log     global
        mode    http #默认的模式mode { tcp|http|health }，tcp是4层，http是7层，health只会返回OK  
        option  httplog #日志类别,采用httplog  
        option  dontlognull  #不记录健康检查日志信息  
        log 127.0.0.1 local0 #[日志输出配置，所有日志都记录在本机，通过local0输出]  
        retries 3 #3次连接失败就认为是服务器不可用，也可以通过后面设置  
        option redispatch  #当serverId对应的服务器挂掉后，强制定向到其他健康的服务器，以后将不支持  
        maxconn 2000
        #contimeout      5000
        #clitimeout      50000
        #srvtimeout      50000
        timeout http-request    10s
        timeout queue           1m
        timeout connect         10s
        timeout client          1m
        timeout server          1m
        timeout http-keep-alive 10s
        timeout check           10s
 
listen  admin_stats bind 0.0.0.0:8888 #管理页面端口
        mode        http
        stats uri   /dbs
        stats realm     Global\ statistics
        stats auth  admin:admin #登录帐号密码
 
listen  proxy-mysql bind 0.0.0.0:23306
        mode tcp
        #roundrobin #轮询方式
　　     #source #类似于nginx的ip_hash
　　     #leastconn #最小连接数
        #static-rr，表示根据权重
        #balance leastconn #轮训机制
        option tcplog
        option mysql-check user haproxy #在mysql中创建无任何权限用户haproxy，且无密码
        server MySQL1 47.52.231.211:3306 check weight 1 maxconn 2000
        server MySQL2 47.52.160.124:3306 check weight 1 maxconn 2000 backup #备用机，主机不档不启用
        option tcpka # 是否允许向server和client发送keepalive
        #cookie 1表示serverid为1，check inter 1500 是检测心跳频率    
        #rise 2是2次正确认为服务器可用，fall 3是3次失败认为服务器不可用，weight代表权重  

```

**3. 直接启动haproxy**

```shell
haproxy -f $HAPROXY_HOME/haproxy.cfg
```

**4. 脚本启动haproxy**

```shell
vim /etc/rc.d/init.d/haproxy
```

```shell
#!/bin/bash  
#chkconfig: 2345 10 90
#description:haproxy
BASE_DIR="/usr/local/haproxy"  
ARGV="$@"  

start()  
{  
    echo "START HAPoxy SERVERS"  
    $BASE_DIR/sbin/haproxy -f $BASE_DIR/haproxy.cfg  
}  

stop()  
{  
    echo "STOP HAPoxy Listen"  
    kill -TTOU $(cat $BASE_DIR/logs/haproxy.pid)  
    echo "STOP HAPoxy process"  
    kill -USR1 $(cat $BASE_DIR/logs/haproxy.pid)  
}  
case $ARGV in  
    
    start)  
start  
ERROR=$?  
;;  

stop)  
stop  
ERROR=$?  
;;  

restart)  
stop  
start  
ERROR=$?  
;;  

*)  
echo "hactl.sh [start|restart|stop]"  
esac  
exit $ERROR

```

```shell
# 执行命令
$ service haproxy start #启动
$ service haproxy stop  #停止
```

**5. 访问haproxy**
> http://localhost:23306/ 





## 高可用系列-安装PgPool

https://www.cnblogs.com/eagle-dtq/p/4288618.html

https://www.pgpool.net/docs/pgpool-II-3.2.1/tutorial-zh_cn.html#install



## 高可用

https://blog.csdn.net/ctwy291314/article/details/79928265

https://blog.csdn.net/weixin_42509278/article/details/81484655

https://blog.csdn.net/weixin_30254435/article/details/95630734

https://blog.csdn.net/ywd1992/article/details/104754086



## 参考链接
http://www.cnblogs.com/tae44/p/4717334.html
https://blog.csdn.net/nimasike/article/details/48048341
https://www.cnblogs.com/dkblog/archive/2012/03/13/2393321.html
https://www.cnblogs.com/Richardzhu/p/3344676.html
https://www.jianshu.com/p/95cc6e875456

