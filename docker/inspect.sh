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

5、查看查看物理CPU个数
# cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l

6、每个物理CPU中core的个数(即核数)
# cat /proc/cpuinfo| grep "cpu cores"| uniq

7、查看逻辑CPU的个数
# cat /proc/cpuinfo| grep "processor"| wc -l

8、查看cpu的型号
# cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c

9、显示硬件系统部件 - (SMBIOS / DMI)
# dmidecode -q

10、宿主机查看序列号
# esxcli hardware platform get

11、小型机查看序列号
prtconf | head

#https://www.cnblogs.com/miaojx/p/15667856.html