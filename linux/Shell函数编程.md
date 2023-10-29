
[TOC]

# while
```shell
# 从config.properties读取kv变量
while read line;do  
    if [ "${line:0:1}" == "#" -o "${line:0:1}" == "" ];then
        continue;
    fi
    key=${line/=*/}
    value=${line#*=}
    echo "$key=$value"
    kvs["$key"]="$value"
done < ../config.properties
```

# test检测
```shell

#==========数值测试=========
#-eq   等于则为真
#-ne   不等于则为真
#-gt   大于则为真
#-ge   大于等于则为真
#-lt   小于则为真
#-le   小于等于则为真

# 案例1
num1=100
num2=100
if test $[num1] -eq $[num2]
then
    echo '两个数相等！'
else
    echo '两个数不相等！'
fi

#案例2
#!/bin/bash
a=5
b=6

result=$[a+b] # 注意等号两边不能有空格
echo "result 为： $result"

#==========字符串测试=========
#=   等于则为真
#!=  不相等则为真
#-z 字符串  字符串的长度为零则为真
#-n 字符串  字符串的长度不为零则为真

num1="ru1noob"
num2="runoob"
if test $num1 = $num2
then
    echo '两个字符串相等!'
else
    echo '两个字符串不相等!'
fi


#==========文件测试=========
#-e 文件名  如果文件存在则为真
#-r 文件名  如果文件存在且可读则为真
#-w 文件名  如果文件存在且可写则为真
#-x 文件名  如果文件存在且可执行则为真
#-s 文件名  如果文件存在且至少有一个字符则为真
#-d 文件名  如果文件存在且为目录则为真
#-f 文件名  如果文件存在且为普通文件则为真
#-c 文件名  如果文件存在且为字符型特殊文件则为真
#-b 文件名  如果文件存在且为块特殊文件则为真

# 案例1
cd /bin
if test -e ./bash
then
    echo '文件已存在!'
else
    echo '文件不存在!'
fi

#案例2
cd /bin
if test -e ./notFile -o -e ./bash
then
    echo '至少有一个文件存在!'
else
    echo '两个文件都不存在'
fi
```

# 函数定义

- 函数可以省略`function`声明和`retuen`。
- 省略`retuen`时则返回最后一条命令结果， return后跟数值n(0-255）
- 最后命令的退出状态，0表示没有错误，其他任何值表明有错误。

**函数定义：**

```shell
[function] funname()
{
    action;
    [return int;]
}
```

```shell
#!/bin/bash
function Sqr(){
    echo "请输入一个整数: "
    read num
    #return `expr $num \* $num`
    return $(($num*$num))
}
Sqr
echo "计算平方值为： $?"
```
```shell
#!/bin/bash

function sum(){
    echo `expr 1 + 1`
}
sum
echo $? #2
echo $? #0，状态已经被覆盖
```

**函数参数：**

```shell
#!/bin/bash

withParam(){
    echo "第1个参: $1"
    echo "第2个参: ${2}"
    echo "所有参数: $@"
    echo "所有参数: $*"
    echo "参数总数: $#"
    echo "脚本进程ID: $$"
    echo "后台进程ID: $!"
    echo "当前选项: $-"
    echo "最后状态: $?"
EXEC_PARAMS=(${@:1})  //第二个以后的剩余
}
withParam a b c d e
```

**案例：斐波那契**

```shell
Fib() #定义函数
{ if [ $1 -eq 0 ] ;
then echo 0 #当$1值为0，回显0
elif [ $1 -eq 1 ] ;then echo 1 #当$1值为0，回显1
else echo $[$(Fib $[$1-1])+$(Fib $[$1-2])]   
 #递归展开Fn=F(n-1)+F(n-2)直到$[$1-1]=1,$[$1-2]=0，递归终止
 fi
 }
Fib $1 #引用函数
```

**案例：加密请求**

```shell
#!/bin/bash

: '说明：在PPGo_job中配置定时任务，执行以下示例的curl请求参数，
    即：在url末尾追加电子签名，在服务端进行签名验证，以防止外部恶意调用。
    请求方法：md5(secret.timespan)'

secret="204NAOB7JND0YRRA" #密钥
timespan=$(date +%s) #时间戳
raw=$secret"."$timespan #签名字符串
sign=`echo $raw| md5sum | cut -d ' ' -f 1` #签名
attach="timespan="$timespan"&sign="$sign

# api接口（注意末尾是否要加&）
api_url="http://deeplink.adxmax.com/api/update?over=0&"$attach
echo $api_url
curl $api_url
```

**案例：递归求和**

```shell
# !/bin/bash
sum=0
function Recurve()
{
    for var in `seq 0 100`
    do
        sum=`expr ${var} + ${sum}`
    done
}
Recurve
echo ${sum}
```

**案例：遍历目录**

```shell
#!/bin/bash
read -p "请输入遍历路径" path
function list()
{
        for var in `ls $1`
        do
        if test -d "$1/${var}"
        then
                echo "d ${var}"
                list "$1/${var}"
        else
                echo "- ${var}"
        fi
        done
}
list ${path}

```


# 字符串包含
```shell
#!/usr/bin/env bash

hello="hello world"
tar="hello"
#if cat console.log | grep "$message" >/dev/null; then
if cat $tar | grep "$message" >/dev/null; then
  echo 1
#  return 1
else
  echo 0
#  return 0
fi
```





#shell脚本包含
http://www.runoob.com/linux/linux-tutorial.html
https://www.runoob.com/w3cnote/linux-shell-brackets-features.html
https://www.cnblogs.com/xiaojiang1025/p/5863984.html
在线shell： http://www.runoob.com/try/runcode.php?filename=helloworld&type=bash

http://www.hechaku.com/shell/



