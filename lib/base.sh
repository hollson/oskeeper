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

# 集合是否包含某个元素
function has() {
  echo ""
}

# 字符串操作
#https://www.cnblogs.com/gaochsh/p/6901809.html