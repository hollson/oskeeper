# Tcpdump结合nc模拟网络抓包
## 一. 准备工作

### 1.1 安装工具

```shell
yum install -y nc
yum install -y tdpdump
```

### 1.2 关闭防火墙

```shell
systemctl status firewalld
systemctl stop firewalld
systemctl disable firewalld
```



## 二. 模拟TCP通信

### 2.1 模拟Tcp通信

```shell
# 【服务端(10.0.0.11)】服务端建通10020端口
nc -kvl 10020

# 【服务端(10.0.0.11)】抓包(默认为第一个网卡)，抓10次
tcpdump -i ens33 -c 10 port 10020

# 【服务端(10.0.0.2)】客户端连接10020服务端口
nc -v 10.0.0.11 10020
```





## 监听网络通信

```shell
# 【服务端】监听UDP
nc -lu 10020

# 【服务端】抓包
tcpdump -i ens33 port 10020

# 【客户端】发送数据
nc -u 10.0.0.11 10020
```





## 抓包

```shell
 tcpdump -i ens33 -t -XX port 10020
```







https://zhuanlan.zhihu.com/p/146155213

https://blog.csdn.net/finghting321/article/details/105510264

