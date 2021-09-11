https://www.cnblogs.com/yadongliang/p/12536889.html



Centos7中默认使用`Firewalld`取代了(通用的)`Iptables`作为`防火墙管理工具`。 iptables服务会把配置好的防火墙策略交由内核
层面的`netfilter网络过滤器`来处理，而firewalld服务则是把配置好的防火墙策略交由内核层面的`nftables包过滤框架`来处理。它们
的作用都是为了方便运维人员管理Linux系统的防火墙策略，而我们只要配置妥当其中一个就足够了。



# 一. firewalld防火墙

## 1.1 服务管理

```css
$ yum install firewalld systemd -y              #安装防火墙
$ firewall-cmd --state                          #防火墙状态

$ systemctl status firewalld                    #查看服务状态
$ systemctl start firewalld                     #启动
$ systemctl stop firewalld                      #停止
$ systemctl restart firewalld                   #重启
$ systemctl disable/enable firewalld            #禁用/启用
$ systemctl is-enabled firewalld.service        #是否开机启动
$ systemctl list-unit-files|grep enabled        #已启动的服务列表
$ systemctl --failed                            #启动失败的服务列表
```
<br/>

## 1.2 规则配置

```css
$ firewall-cmd --zone=public --query-port=80/tcp              #查看端口状态
$ firewall-cmd --zone=public --add-port=80/tcp --permanent    #添加端口
$ firewall-cmd --reload                                       #重新载入
$ firewall-cmd --zone=public --remove-port=80/tcp --permanent #删除端口
$ firewall-cmd --zone=public --list-ports                     #查看打开的端口

$ firewall-cmd -V                                             #查看版本
$ firewall-cmd -h                                             #查看帮助
```
<br/>





# iptables防火墙









# 防火墙

https://www.cnblogs.com/kreo/p/4368811.html

https://www.linuxprobe.com/25-iptables-common-examples.html



https://www.cnblogs.com/wujunbin/p/7465538.html




