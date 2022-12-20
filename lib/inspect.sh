#!/bin/bash

 Linux 系统查看服务器SN序列号以及服务器型号和查看cpu信息

#1、单独查看服务器的序列号
dmidecode -t system | grep 'Serial Number'
#2、单独查看服务器型号
dmidecode | grep "Product"

3、统一查看服务器SN序列号和型号（厂商、型号、序列号）
# dmidecode | grep "System Information" -A9 | egrep "Manufacturer|Product|Serial"

4、查看内存条信息及使用情况（内存的插槽数,已经使用多少插槽.每条内存多大）
# dmidecode -t memory | grep Size

9、显示硬件系统部件 - (SMBIOS / DMI)
# dmidecode -q


# 厂商信息
sudo dmidecode -s system-product-name

# 是否为容器(物理机，虚拟机，container，pod)
cat /proc/1/cgroup|grep -E "kubepods|docker"



#https://www.cnblogs.com/miaojx/p/15667856.html

