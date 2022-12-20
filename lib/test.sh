#!/bin/bash

source ./sdk.sh

#https://www.runoob.com/linux/linux-filesystem.html
function Info() {
 echo -e "操作系统: \t $(uname -rms)"
  echo -e "内存信息: \t $(top -l 1 | head -n 10 |sed -n "s/PhysMem: //p")"
  echo -e "CPU型号: \t $(sysctl -n machdep.cpu.brand_string)"
  echo -e "CPU状态: \t $(top -l 1 | head -n 10 |sed -n "s/CPU usage: //p")"
  echo -e "物理核数: \t $(sysctl -n machdep.cpu.core_count)"
  echo -e "逻辑核数: \t $(sysctl -n machdep.cpu.thread_count)"
}
Info