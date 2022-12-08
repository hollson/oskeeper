#!/bin/bash

function foo() {
  echo "foo"
#  echo "dsaasfdassfdfa"
#  echo "fasds===>" > ./pid
  return 2
#    exit 3
}

function bar() {
  echo "bar"
  return 3
}

function import() {
#  set -e
  foo
  bar
  #  set -e
}

import
#import
#reportstatus 1 "备份MySQL完成"

#sed -i '/hello/d' ./a.txt # 删除关键字行
#sed -i '1d' a.txt         # 删首行
#sed -i '2d' a.txt         # 删除第2行
#sed -i '$d' a.txt         # 删除尾行
#sed -i 's/[ ]*//g' a.txt  # 删除空格
#sed -i '/^$/d' a.txt      # 删除空行
