#!/bin/bash

# # 加减乘除模
# #expr 9 + 3
# #expr 9 - 3
# #expr 9 \* 3
# #expr 9 / 3
# #expr 9 % 2
# ## sum@求两数之和
# function sum() {
#   echo $(($1 + $2))
# }

#sed -i '/hello/d' ./a.txt # 删除关键字行
#sed -i '1d' a.txt         # 删首行
#sed -i '2d' a.txt         # 删除第2行
#sed -i '$d' a.txt         # 删除尾行
#sed -i 's/[ ]*//g' a.txt  # 删除空格
#sed -i '/^$/d' a.txt      # 删除空行

# 字符串操作
#https://www.cnblogs.com/gaochsh/p/6901809.html

#   echo "上层函数 => ${FUNCNAME[1]}"
#   echo ${FUNCNAME[@]}

function fooTest() {
    echo "hello world"
}
eval "$(declare -f fooTest | xargs | grep -oE '{.*}' | sed -E 's/{|}//g')"

# todo
# 制表符
# 帮助命令
