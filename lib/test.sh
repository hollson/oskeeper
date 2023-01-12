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

# function fooTest() {
#     echo "hello world"
# }
# eval "$(declare -f fooTest | xargs | grep -oE '{.*}' | sed -E 's/{|}//g')"

# todo
# 制表符
# 帮助命令

# echo "#FUN 分类|名称|帮助说明" | sed -n "s/^#FUN//p" | awk -F '|' '{printf ("\033[30;41m %12s\033[0m",$1),"\t|\t", $2,"\t|\t" $3}'
# echo "#FUN 分类|名称|帮助说明" | sed -n "s/^#FUN //p" | awk -F "|" '{printf ("\033[31m %s\033[0m",$0)}'
# awk -F ":" '$5~/^a/{print }' /etc/passwd  打印以冒号为分隔符，第5列中以a开头的行

# function has() {
#     all=$1
#     tar=$2
#     # shellcheck disable=SC2048
#     for v in ${all[*]}; do
#         [[ "$tar" == "$v" ]] && return
#     done
#     return 1
# }

## 管道
#echo "输入网站名: "
##读取从键盘的输入
#read website
#echo "你输入的网站名是 $website"
#exit 0 #退出
#echo abc.com | ./test.sh

# sed专题
# https://www.yiibai.com/sed/sed_regular_expressions.html

# 压缩json


#RUN find . -name *.go -exec rm -rf {} \ #删除源文件
#RUN find -type d -empty |xargs rm -rf;  #删除空目录