[TOC]



# 一. 基础语法



# 二. 流程控制

## 1.if语句

> 语法：`if;then;elif;then;else;fi;`

**Shell风格**

```shell
if [ $# -lt 1 ]; then
echo "输入参数缺失"
fi
```
```shell
if [ $1 -ge 80 ];then echo "优秀";elif [ $1 -ge 60 ];then echo "及格";else echo "不及格";fi
```
**C风格**

```shell
if (($1 >= 80)); then
printf '%s\n' "优秀"
elif (($1 >= 60)); then
printf '%s\n' "及格"
else
printf "%s\n" "不及格"
fi
```



## 2. For循环

**FOR-LOOP**

```shell
for ((i = 1; i <= 5; i++)); do
echo "For-Loop: $i"
done
```
```shell
awk 'BEGIN{for(i=1; i<=10; i++) print i}'
```

**For-In**

```shell
for item in 999 "hello" true 1.23; do
echo "For-In: $item"
done
```
```shell
for i in $(seq 1 10); do
echo $(expr $i \* 3 + 1)
done
```

```shell
for i in {1..10}; do
echo $(expr $i \* 3 + 1)
done
```


```shell
for i in $(ls); do
echo $i is file name\!
done

for i in $*; do
echo $i is input chart\!
done
```

**For-Read(遍历命令行参数)**

```shell
for param; do
echo "For-read:$param"
done
```

```shell
# 遍历字符串
list="how are you"
for item in $list; do
echo $item
done
```



## 3.While循环

> 使用`let`修改变量值

**While-Loop**

```shell
# 案例1
count=5
while (($count > 0)); do
echo $count
let count--
done
```
**While-Read**

```shell
echo '按下 <CTRL-D> 退出'
echo -n 'Input content: '
while read param; do
echo "您输入了：$param"
done
```
**死循环**

```shell
while :
do
command
done
#或者
while true
do
command
done
#或者
for (( ; ; ))
```

## 4. Until循环

> `until condition do command done`
```shell
num=0
until [ ! $num -lt 10 ]; do
echo $num
num=$(expr $num + 1)
done
```

## 5. Case语句
```shell
printf '输入男女(F/M) : '
read sex
case $sex in
f | F) echo '你选择了：女' ;;
f | M) echo '你选择了：男' ;;
*) echo '~输入错误~' ;;
esac
```

## 6. Break语句
```shell
while :; do
printf '输入男女(F/M) : '
read sex
if [ $sex == 'F' -o $sex == 'M' ]; then
echo "输入成功"
break
fi
echo " ~~>_<~~输入错误 ~~>_<~~"
```

## 7. Continue语句
```shell
for ((i = 1; i < 10; i++)); do
if ((i % 2 == 0)); then
continue
fi
echo $i
done
```

# 三. 函数



# 四. Test命令

> Test用来``检测某条件是否成立`。`test expression`可简写为`[ expression ]`
>
> 在 test 中使用变量建议用双引号包围起来
>
> `=`和`==`是等价的，都用来判断 str1 是否和 str2 相等。
>
> test 命令比较奇葩，>、<、== 只能用来比较字符串，不能用来比较数字，比较数字需要使用 -eq、-gt 等选项；不管是比较字符串还是数字，test 都不支持 >= 和 <=。有经验的程序员需要慢慢习惯 test 命令的这些奇葩用法。
>
>
>
> 有了 [[ ]]，你还有什么理由使用 test 或者 [ ]，[[ ]] 完全可以替代之，而且更加方便，更加强大。
>
> 但是 [[ ]] 对数字的比较仍然不友好，所以我建议，以后大家使用 if 判断条件时，用 (()) 来处理整型数字，用 [[ ]] 来处理字符串或者文件。





**比较数值**

> `-eq：相等；-ne：不等于；-gt：大于；-ge：大于等于；-lt：小于；-le：小于等于`

```shell
if test $1 -eq $2; then echo '相等'; else echo '不相等'; fi
if test $1 == $2; then echo "相等"; else echo "不相等"; fi
if (($1 == $2)); then echo '相等'; else echo '不相等'; fi
```

```shell
grep -wq "JAVE_HOME" /etc/profile && echo "yes" || echo "no"
grep -wq "KAFKA_HOME" /etc/profile && echo "yes" || echo "no"
```

**验证文件**

```shell
if test -e /etc/profile; then echo '文件存在'; else echo '文件不存在!'; fi
if test -d /etc/redis; then echo '目录存在'; else echo '目录不存在!'; fi
```





