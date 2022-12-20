#!/bin/bash

source ./sdk.sh

#https://www.runoob.com/linux/linux-filesystem.html
function macOS() {
  echo -e "操作系统: \t $(uname -rms)"
  echo -e "内存信息: \t $(top -l 1 | head -n 10 | sed -n "s/PhysMem: //p")"
  echo -e "CPU型号: \t $(sysctl -n machdep.cpu.brand_string)"
  echo -e "CPU状态: \t $(top -l 1 | head -n 10 | sed -n "s/CPU usage: //p")"
  echo -e "物理核数: \t $(sysctl -n machdep.cpu.core_count)"
  echo -e "逻辑核数: \t $(sysctl -n machdep.cpu.thread_count)"
}

# CPU状态参数：
# %us：表示用户空间程序的cpu使用率（没有通过nice调度）
# %sy：表示系统空间的cpu使用率，主要是内核程序。
# %ni：表示用户空间且通过nice调度过的程序的cpu使用率。
# %id：空闲cpu
# %wa：cpu运行时在等待io的时间
# %hi：cpu处理硬中断的数量
# %si：cpu处理软中断的数量
# %st：被虚拟机偷走的cpu
function linuxOS() {
  echo -e "操作系统: \t $(uname -rms)"
  echo -e "内存信息: \t $(free -h | sed -n 's/Mem:\s*//p' | awk '{print "total:"$1, "used:"$2,"buff:"$5,"available:"$6}')"

  echo -e "CPU型号: \t $(awk -F: '/model name/{print $2}' /proc/cpuinfo | sort | uniq | xargs)"
  echo -e "CPU状态: \t $(top -bn1 -ic | grep '%Cpu' | awk -F: '{print $2}' | xargs)"
  echo -e "CPU数量: \t $(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)"
  echo -e "物理核数: \t $(awk '/cpu cores/{print $4}' /proc/cpuinfo | uniq)"
  echo -e "逻辑核数: \t $(grep -c "processor" /proc/cpuinfo)"
}

# linuxOS

# 安装器
function installer() {
  set +e
  arr=(dnf yum apt apt-get apk brew)
  for v in "${arr[@]}"; do
    which "$v" && return 0
  done
  return 127
}

$(installer) --version

# 检查当前系统是否为虚拟化环境
# VT-x:     物理机
# Xen/Kvm:  开源虚拟化软件
# VMware:   付费虚拟化软件
# hyper-v:  微软虚拟化组件
# Kubepods： K8s容器化
# Docker:   Docker容器化
function virtualize() {
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
virtualize

# 查看系统发行信息(厂商)，如：
# CentOS Linux 7 (Core)
# Ubuntu 20.04 LTS (Focal Fossa)
# Debian GNU/Linux 11 (bullseye)
# uos 20
function osRelease() {
  awk -F= '/^NAME=|^VERSION="/{print $2}' /etc/os-release | xargs
}
# osRelease

# 集合是否包含某个元素
function has() {
  echo ""
}

# 字符串操作
# https://blog.csdn.net/qq_23091073/article/details/83066518
