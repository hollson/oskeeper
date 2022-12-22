#!/bin/bash

source ./base.sh

# 安装器
function installer() {
  arr=(dnf yum apt apt-get apk brew)
  for v in "${arr[@]}"; do
    which "$v" && return 0
  done
  return 127
}
#$(installer) --version

# 检查当前系统是否为虚拟化环境
: '
 CPU状态参数：
 VT-x/Physics: 物理机
 Xen/Kvm:   开源虚拟化软件
 VMware:    付费虚拟化软件
 hyper-v:   微软虚拟化组件
 Kubepods： K8s容器化
 Docker:    Docker容器化
'
function virtualize() {
  if darwin; then
    echo "Physics"
    return
  fi

  if grep -q "kubepods" /proc/1/cgroup; then
    echo "Kubepods"
    return 0
  fi

  if grep -q "docker" /proc/1/cgroup; then
    echo "Docker"
    return 0
  fi

  # 虚拟化
  lscpu | awk -F: '/Virtualization|Hypervisor/&&!/full/{print $2}' | xargs
}

# 查看系统发行版本(厂商)，如：
# CentOS Linux 7 (Core)
# Ubuntu 20.04 LTS (Focal Fossa)
# Debian GNU/Linux 11 (bullseye)
# uos 20
function osRelease() {
  if darwin; then
    sw_vers | awk -F: '/Product/{print $2}' | xargs
    return 0
  fi
  awk -F= '/^NAME=|^VERSION="/{print $2}' /etc/os-release | xargs
}

# 查看系统(静态)信息
function sysInfo() {
  if [ -f ~/.sdk/sys.info ]; then
    cat ~/.sdk/sys.info
    return
  fi

  mkdir -p ~/.sdk
  _os="$(uname -rms)"
  _cpu_mode="known"
  _cpu_count=1
  _physical=0
  _thread=0

  if darwin; then
    _cpu_mode=$(sysctl -n machdep.cpu.brand_string)
    _physical=$(sysctl -n machdep.cpu.core_count)
    _thread=$(sysctl -n machdep.cpu.thread_count)

  else
    _cpu_mode=$(awk -F: '/model name/{print $2}' /proc/cpuinfo | sort | uniq | xargs)
    _cpu_count=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
    _physical=$(awk '/cpu cores/{print $4}' /proc/cpuinfo | uniq)
    _thread=$(grep -c "processor" /proc/cpuinfo)
  fi

  cat <<EOF | column -s = -t >~/.sdk/sys.info
操作系统:= $_os
CPU型号:= $_cpu_mode
CPU数量:= $_cpu_count
物理核数:= $_physical
逻辑核数:= $_thread
发行版本:= $(osRelease)
安装器:= $(installer)
虚拟化状态:= $(virtualize)
EOF

  cat ~/.sdk/sys.info
}

# 系统诊断(动态)信息
: '
 CPU状态参数：
 %us：表示用户空间程序的cpu使用率（没有通过nice调度）
 %sy：表示系统空间的cpu使用率，主要是内核程序。
 %ni：表示用户空间且通过nice调度过的程序的cpu使用率。
 %id：空闲cpu
 %wa：cpu运行时在等待io的时间
 %hi：cpu处理硬中断的数量
 %si：cpu处理软中断的数量
 %st：被虚拟机偷走的cpu
 https://www.runoob.com/linux/linux-filesystem.html
'
function sysInspect() {
  echo -e "磁盘信息: \t 待完善..."
  if darwin; then
    echo -e "内存信息: \t $(top -l 1 | head -n 10 | sed -n "s/PhysMem: //p")"
    echo -e "CPU状态: \t $(top -l 1 | head -n 10 | sed -n "s/CPU usage: //p")"
  else
    echo -e "内存信息: \t $(free -h | sed -n 's/Mem:\s*//p' | awk '{print "total:"$1, "used:"$2,"buff:"$5,"available:"$6}')"
    echo -e "CPU状态: \t $(top -bn1 -ic | grep '%Cpu' | awk -F: '{print $2}' | xargs)"
  fi

  echo -e "网关  : \t $(gateWay)"
  echo -e "内网IP: \t $(ip4)"
  echo -e "公网IP: \t $(curl ifconfig.me -s)"
}

# # 默认网关
# function gateWay() {
#   if [ "$(uname -s)" == "Darwin" ]; then
#     route -n get default | awk -F: '/gateway/{print $2}' | xargs
#     return
#   fi
#   ip route | awk '/default/{print $3}'
# }

# # IPv4
# function ip4() {
#   sub=$(gateWay | cut -d '.' -f1,2,3)
#   ips=$(ifconfig | awk '/inet /{print $2}')

#   # 24位子网
#   echo -n "$ips" | grep "${sub}3" && return

#   # 16位子网
#   sub=$(gateWay | cut -d '.' -f1,2)
#   echo -n "$ips" | grep "${sub}"
# }
# ip4
