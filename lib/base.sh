#!/bin/bash

# Mac(达尔文)系统
function darwin() {
  if [ "$(uname -s)" == "Darwin" ]; then
    return 0
  fi
  return 1
}

## dateTime@打印当前时间
function dateTime() {
  date "+%Y-%m-%d %H:%M:%S"
}

# 默认网关
function gateWay() {
  if [ "$(uname -s)" == "Darwin" ]; then
    route -n get default | awk -F: '/gateway/{print $2}' | xargs
    return
  fi
  ip route | awk '/default/{print $3}'
}

# IPv4
function ip4() {
  # unset IPv4
  # if [ -n "${IPv4}" ]; then
  #   echo "${IPv4}" && return
  # fi

  sub=$(gateWay | cut -d '.' -f1,2,3)
  ips=$(ifconfig | awk '/inet /{print $2}')

  # 24位子网
  echo -n "$ips" | grep "${sub}3" && return

  # 16位子网
  sub=$(gateWay | cut -d '.' -f1,2)
  echo -n "$ips" | grep "${sub}"
}

# 集合是否包含某个元素
function has() {
  all=$1
  tar=$2
  # shellcheck disable=SC2048
  for v in ${all[*]}; do
    [[ "$tar" == "$v" ]] && return
  done
  return 1
}

# ext=bmp2
# list=(jpg bmp png)
# has "${list[*]}" ${ext}
# echo $?

# 字符串操作
#https://www.cnblogs.com/gaochsh/p/6901809.html
