
[toc]
`i 交互,忽略大小,f 强制,h 人性化,r 递归,l 列表`


```sh
open .  # 打开当前目录
open -a vscode ./a.txt  # vs打开a.txt文件
```

<br/>
```txt
# 应用程序：
# 不同操作系统的具体差异很大，如macos和centos中很大一部分命令位置都不一致
/bin           #Binary的缩写, 普通用户和管理员都可执行的【通用用户程序】,如：ls，mkdir。
/usr/bin       #系统自带的一些可执行程序。即【系统应用程序】,如：grep，sed，find，gcc。
/usr/local/bin #用户【自编译应用程序】, 如：wget、vim、redis-server。

/sbin     #系统管理员使用的系统管理程序，如：ifconfig,iptables。
/usr/sbin #超级用户使用的比较高级的管理程序和系统守护程序，如：useradd,shutdown,sysctl。

# 系统配置：
/etc   #【系统管理】所需要的配置文件和子目录。

# 安装目录：
/usr     #用户的很多应用程序和文件都放在这个目录下，类似于windows下的program files目录。
/usr/src #内核源代码默认的放置目录。
/opt     #额外安装软件的目录。如在此目录安装一个ORACLE数据库。

# 用户目录
/root   #系统管理员root的主目录。
/home   #用户的家目录。


# 数据目录
/srv #该目录存放一些服务启动之后需要提取的数据。
/srv ：主要用来存储本机或本服务器提供的服务或数据。（用户主动生产的数据、对外提供服务）

/var #这个目录中存放着在不断扩充着的东西，我们习惯将那些经常被修改的目录放在这个目录下。包括各种日志文件。
/var ：系统产生的不可自动销毁的缓存文件、日志记录。（系统和程序运行后产生的数据、不对外提供服务、只能用户手动清理）（包括mail、数据库文件、日志文件）

/tmp #这个目录是用来存放一些临时文件的。
/tmp ：保存在使用完毕后可随时销毁的缓存文件。（有可能是由系统或程序产生、也有可能是用户主动放入的临时数据、系统会自动清理）

/run #是一个临时文件系统，存储系统启动以来的信息。当系统重启时，这个目录下的文件应该被删掉或清除。如果你的系统上有 /var/run 目录，应该让它指向 run。

/proc #这个目录是一个虚拟的目录，它是系统内存的映射，我们可以通过直接访问这个目录来获取系统信息。
# 这个目录的内容不在硬盘上而是在内存里，我们也可以直接修改里面的某些文件，比如可以通过下面的命令来屏蔽主机的ping命令，使别人无法ping你的机器：
`echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all`

# 系统保留
/boot #这里存放的是启动Linux时使用的一些核心文件，包括一些连接文件以及镜像文件。
/dev #dev是Device(设备)的缩写, 该目录下存放的是Linux的外部设备，在Linux中访问设备的方式和访问文件的方式是相同的。
/media #linux系统会自动识别一些设备，例如U盘、光驱等等，当识别后，linux会把识别的设备挂载到这个目录下。
/mnt #系统提供该目录是为了让用户临时挂载别的文件系统的，我们可以将光驱挂载在/mnt/上，然后进入该目录就可以查看光驱里的内容了。
/lib #这个目录里存放着系统最基本的动态连接共享库，其作用类似于Windows里的DLL文件。几乎所有的应用程序都需要用到这些共享库。
/lost+found #这个目录一般情况下是空的，当系统非法关机后，这里就存放了一些文件。

/selinux #这个目录是Redhat/CentOS所特有的目录，Selinux是一个安全机制，类似于windows的防火墙，但是这套机制比较复杂，这个目录就是存放selinux相关的文件的。
/sys #这是linux2.6内核的一个很大的变化。该目录下安装了2.6内核中新出现的一个文件系统 sysfs 。
#sysfs文件系统集成了下面3种文件系统的信息：针对进程信息的proc文件系统、针对设备的devfs文件系统以及针对伪终端的devpts文件系统。
#该文件系统是内核设备树的一个直观反映。
#当一个内核对象被创建的时候，对应的文件和目录也在内核对象子系统中被创建。

#在 Linux 系统中，有几个目录是比较重要的，平时需要注意不要误删除或者随意更改内部文件。
/etc #上边也提到了，这个是系统中的配置文件，如果你更改了该目录下的某个文件可能会导致系统不能启动。
/bin, /sbin, /usr/bin, /usr/sbin: #这是系统预设的执行文件的放置目录，比如 ls 就是在/bin/ls 目录下的。值得提出的是，bin, /usr/bin 是给系统用户使用的指令（除root外的通用户），而/sbin, /usr/sbin 则是给root使用的指令。
/var： #这是一个非常重要的目录，系统上跑了很多程序，那么每个程序都会有相应的日志产生，而这些日志就被记录到这个目录下，具体在/var/log 目录下，另外mail的预设放置也是在这里。
```

◆ 安装和登录命令：login、shutdown、halt、reboot、install、mount、umount、chsh、exit、last；
◆ 文件处理命令：file、mkdir、grep、dd、find、mv、ls、diff、cat、ln；
◆ 系统管理相关命令：df、top、free、quota、at、lp、adduser、[groupadd](#groupadd)、kill、crontab；
◆ 网络操作命令：ifconfig、ip、ping、netstat、telnet、ftp、route、rlogin、rcp、finger、mail、 nslookup；
◆ 系统安全相关命令：passwd、su、umask、chgrp、chmod、chown、chattr、sudo ps、who；
◆ 其它命令：tar、unzip、gunzip、unarj、mtools、man、unendcode、uudecode。

<br/>

# 1. 命令帮助
**命令大全：** https://www.runoob.com/linux/linux-command-manual.html

```shell
# 查看说明
$ fdisk --help  #使用说明
$ whatis ping
$ man ping  #命令文档

# 查找命令
$ which -a ping #(从PATH路径)查找命令位置
$ whereis ping #(从索引数据)查找二进制文件、源文件和帮助手册文件

# 命令类型
$ type ping  #系统内嵌命令
$ type lua  #外部独立安装
```





#2. 系统信息
**系统版本：**

```shell
uname -s
hostnamectl
lsb_release -a


$ arch  #cpu架构
$ uname -a  #内核版本
$ cat /etc/redhat-release
cat /proc/cpuinfo |grep "physical id"|sort |uniq|wc -l # cpu核数


# 查看物理cpu个数

grep 'core id' /proc/cpuinfo | sort -u | wc -l

# 查看核心数量

grep 'processor' /proc/cpuinfo | sort -u | wc -l

# 查看线程数

grep 'physical id' /proc/cpuinfo | sort -u





查看CPU信息（型号）

[root@AAA ~]# cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c

     24         Intel(R) Xeon(R) CPU E5-2630 0 @ 2.30GHz



# 查看物理CPU个数

[root@AAA ~]# cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l

2



# 查看每个物理CPU中core的个数(即核数)

[root@AAA ~]# cat /proc/cpuinfo| grep "cpu cores"| uniq

cpu cores    : 6



# 查看逻辑CPU的个数

[root@AAA ~]# cat /proc/cpuinfo| grep "processor"| wc -l

24





```

MAC信息
```sh
# 物理CPU数量
sysctl hw.physicalcpu

# 逻辑CPU数量
sysctl hw.logicalcpu

# 硬件信息总览
system_profiler SPHardwareDataType
```



**开机关机：**

```shell
$ w  #查看在线用户(强大)
$ who -Hu  #查看在线用户

$ shutdown -h 0  #0分钟后关机
$ shutdown -r 0  #0分钟后重启

$ shutdown -k +10 "⚠️  警示：:系统将在10分钟后重启 ！！！"  #发出警告
$ shutdown -r +10 "⚠️  警示：:系统将在10分钟后重启 ！！！"  #实际执行
```



**系统日期：**

```shell
$ cal --help
$ cal 2020  #2020年
$ cal 12 2020  #2020年12月

$ date --help                
$ date +%s  #时间戳
$ date +%A  #星期几
```





#3. 用户管理

- 用户分类：` Root 用户(0)； 系统用户(1-999)；普通用户(1000+)`。
```shell
# 添加删除用户组
$ groupadd GroupName
$ groupdel GroupName

# 添加删除用户
$ useradd -g GroupName -c "备注" UserName
$ userdel UserName

# 修改用户密码
$ echo "123456" | passwd --stdin UserName

# 查看账户信息
$ id UserName
$ cat /etc/<passwd|shadow|group> #用户|密码|组信息

# 赋予普通用户sudo权限(需要打开与关闭写权限)
$ chmod u+w /etc/sudoers
$ echo "UserName    ALL=(ALL)       ALL">>/etc/sudoers
$ chmod u-w /etc/sudoers
```





#4. 存储管理

**内存信息：**
- https://www.cnblogs.com/operationhome/p/10362776.html
- https://blog.csdn.net/xujiamin0022016/article/details/89268139
- https://www.jianshu.com/p/8676973770d2

```shell
#以K字节查看内存
# free：空闲的内存数
# buff: 写 IO 缓存
# cache: 读 IO 缓存
# available: 可用内存(估算值)
$ free -k 
              total        used        free      shared  buff/cache   available
Mem:        3880248       90340     3579016       41400      210892     3543488
Swap:             0           0           0

# 计算校验：userd + free+ buff/cache = total
$ echo '90340 + 3579016 + 210892'|bc  #输出 3880248

# 释放缓存(在两个终端操作，观察释放前后数据)
$ free -hs 10  #十秒钟刷新一次
$ sync  #将缓冲区磁写入磁盘
# 释放：0-不释放（系统默认值）；1-释放页缓存；2-释放dentries和inodes；3-释放所有缓存
$ echo 3 > /proc/sys/vm/drop_caches
```
**磁盘管理：**

```shell
# https://blog.51cto.com/11495268/2424414?source=dra

$ du -sh
$ du -ch

$ cat /proc/partitions    #物理分区
$ df -ah                #磁盘占用
$ cd /&& du -sh *    #目录占用
$ du --max-depth=1 -h    #深度为1
du -hd 1 ~|sort -nr|tail #排序

$ df -h  #磁盘剩余

https://blog.csdn.net/july_young/article/details/81948322
```

**磁盘分区：**

```shell
$ fdisk -l
磁盘 /dev/sda：21.5 GB, 21474836480 字节，41943040 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：dos
磁盘标识符：0x00031158

   设备 Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048     1026047      512000   83  Linux
/dev/sda2         1026048    41943039    20458496   8e  Linux LVM

磁盘 /dev/mapper/centos-root：18.8 GB, 18756927488 字节，36634624 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节


磁盘 /dev/mapper/centos-swap：2147 MB, 2147483648 字节，4194304 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
```



# 5. 进程管理

## 查看进程

```shell
$ man ps  #查看帮助
$ ps  #当前用户会话中打开的进程

# 以(UNIX)标准语法查看[所有][进程]
$ ps -ef

# 以BSD语法查看[所有][用户][进程]【推荐】
$ ps aux
$ ps aux --sort -%mem|head #以内存占比降序

#Unix，Linux和BSD都是POSIX(可移植操作系统接口)，基本上都是可以互换的。

# 查看进程树
#yum -y install psmisc
$ pstree
```

```shell
$ top
top - 00:21:46 up 5 days,  3:23,  1 user,  load average: 0.01, 0.03, 0.05
Tasks:  97 total,   1 running,  96 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.2 sy,  0.0 ni, 99.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.5 st
KiB Mem :  3880248 total,  2746612 free,   756508 used,   377128 buff/cache
KiB Swap:        0 total,        0 free,        0 used.  2710860 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
 7429 root      20   0  162004   2272   1608 R   0.3  0.1   0:00.42 top
 7450 mysql     20   0 1275384 186764   9020 S   0.3  4.8   3:28.16 mysqld
 9031 root      20   0  565620  54760  24012 S   0.3  1.4   6:38.54 dockerd
 9038 root      20   0  418492  30652  12316 S   0.3  0.8   7:08.79 docker-containe
    1 root      20   0   43452   3624   2404 S   0.0  0.1   1:15.01 systemd
    2 root      20   0       0      0      0 S   0.0  0.0   0:00.01 kthreadd
    4 root       0 -20       0      0      0 S   0.0  0.0   0:00.00 kworker/0:0H
    ...
```

## 守护进程
```shell
# 语法：nohup Command [ Arg ... ] [　& ]
# nohup表示:not hang up; &表示：后台运行

# 操作系统中有三个常用的流：
#        0：标准输入流 stdin
#        1：标准输出流 stdout（默认）
#        2：标准错误流 stderr 

# 例如：

$ ls 1>/dev/null 2>/dev/null  #将1和2定向到黑洞

$ ls >/dev/null 2>&1  #同上，顺序不能更改


#https://www.cnblogs.com/zhangwuji/p/8059539.html
$ nohup ./program >out.log 2>&1 & #将标准输出和错误都定向到log
$ nohup ./program >/dev/null 2>out.log &  #将1定向到null，2定向到log

$ nohup ./program >/dev/null 2>&1 &  #将1和2都定向到null

```



## 杀死进程

```shell
# 查询进程编号
$ pgrep nginx  #模糊查询进程ID
$ pidof nginx  #具名查找进程ID


# 杀死进程
$ kill -l  #查看信号
$ kill -s 8888 
$ kill -s 9 `pgrep nginx`
$ pgrep nginx| xargs kill -s 9
$ pkill -９ nginx  #pgrep+kill(注意是-9)
```

#6. 文件管理
## 文件操作

```shell
$ touch a.txt  #创建文件
$ file a.txt  #文件描述
$ stat a.txt  #文件信息
$ rm -f a.txt #删除文件
$ rm -rf ./dir #删除目录
```


##文件查找
**递归查找：**【不推荐】

```shell
# 递归查找【注意引号】
$ find ./ -name "*.txt" 
$ find /etc/ -maxdepth 2 -name passwd  #深度
$ find . -size +1M  #大于1兆的文件

$ find ./ -name "*.txt" |xargs rm -rf
$ find ./ -ctime +7 -name ".log" |xargs rm -f #删除一周前的日志
```
**索引查找：**【推荐】
```shell
# 索引查找(模糊)，等下于“find -name”
$ yum install -y mlocate
$ locate txt 
$ updatedb  #更新索引数据
```

# 查找并删除
https://www.cnblogs.com/langzou/p/5959940.html

## 文件权限

```shell
# 修改权限：user、group、other、read、write、excute
$ chmod ugo+rwx <File/Dir>  #加权限
$ chmod go-rwx <File/Dir>  #删除权限

# 修改权限：r=4，w=2，x=1
$ chmod 777 <File>

# 变更所有权
$ chown UserName <File>  #改变文件所有者
$ chown -R UserName <Dir>  #递归改变子目录文件所有权

# 变更群组
$ chgrp GroupName <File>
$ chown UserName:GroupName <File> #指定所有者和群组

# 更改属性
$ chattr +i <File> #只读（不可删、改、重命名或链接）
$ chattr +a <File> #只允许追加
$ lsattr <File>  #查看属性
```



## 文件压缩

```shell
$ tar -cvf target.tar source.txt      #仅打包不压缩

$ tar -zcvf target.tar.gz source.txt  #打包后并以 gzip 压缩
$ tar -zxvf target.tar.gz             #解压

$ tar -jcvf target.tar.bz2 source.txt  #打包后并以 bzip2 压缩
$ tar -jtvf target.tar.bz2             #查询
$ tar -jxvf target.tar.bz2 -C ./       #解压
```



#7. 文本操作

## 简单操作

```shell
$ /bin/echo --help. #(特殊)必须这种方式查看
$ echo "hello world">hello.txt

$ cat a.txt  #正向查看
$ tac a.txt  #反向查看

#空格翻页，只能向下，整篇加载，留有痕迹，Q键退出
$ more a.txt      

#空格/w翻页，箭头上下，动态加载无痕迹，"less is more"
$ less -N a.txt       

$ head -2 a.txt  #查看前两行
$ tail -2 a.txt  #查看后两行

# 字数统计：c(chars);l(lines);w(words)
$ wc a.txt  #行数/单词数/字符数
```


## 三剑客-Grep

```shell
# 正则查找
$ grep -c 'key' test.txt  #关键字出现次数


# 递归查找（r:递归;i:忽略;n:行号,e:正则)
$ grep -rine "regexp" ./

#查找关键字行
$ grep ^MyKey ./test.txt

# 查找一段，如帮助文档的某个段落
# https://blog.csdn.net/qingsong3333/article/details/78067778  
$ awk 'BEGIN {RS = "\n\n+";ORS = "\n\n"} /关键字/ {print $0}' db2diag.log
#如果要反选，即不包含关键字的段落，在关键字前加上!
$ awk 'BEGIN {RS = "\n\n+";ORS = "\n\n"} !/关键字/ {print $0}' db2diag.log
# 另外，也可以直接将RS设置为空串，效果是一样的
$ awk 'BEGIN {RS = "";ORS = "\n\n"} /关键字/ {print $0}' db2diag.log
```

## 三剑客-Sed

```shell
$ sed --help
$ sed 's/str1/str2/g' test.txt > new.txt  #替换内容并存入新文件
$ sed '/#/d;/^$/d' test.sh  #删除注释和空行

echo 'esempio' | tr '[:lower:]' '[:upper:]' 合并上下单元格内容
sed -e '1d' result.txt 从文件example.txt 中排除第一行
sed -n '/stringa1/p' 查看只包含词汇 "string1"的行
sed -e 's/ *$//' example.txt 删除每一行最后的空白字符
sed -e 's/stringa1//g' example.txt 从文档中只删除词汇 "string1" 并保留剩余全部

sed -n '1,5p;5q' example.txt 查看从第一行到第5行内容
sed -n '5p;5q' example.txt 查看第5行
sed -e 's/00*/0/g' example.txt 用单个零替换多个零


paste file1 file2 合并两个文件或两栏的内容
paste -d '+' file1 file2 合并两个文件或两栏的内容，中间用"+"区分

sed -i "s/查找字段/替换字段/g" `grep 查找字段 -rl 路径`

```

## 三剑客-Awk

http://c.biancheng.net/view/4082.html



## 文件比较

```shell
 #比较差异
$ diff a.txt b.txt

# 过滤重复
$ uniq test.txt -u  #c:统计;u:不重复行;重复
$ uniq test.txt > new.txt  #过滤相邻重复行

# 内容排序
$ sort a.txt
$ sort fileA fileB | uniq  #并集
$ sort fileA fileB | uniq -d  #交集
$ sort fileA fileB | uniq -u  #差集(交集的补集)

# 比较文件(比较两个已排过序的文件)
# 结果分三列：左列(A)，右列(B)，交集(A∩B)
$ comm fileA fileB #全部显示
$ comm -1 fileA fileB  #不显示第1列
$ comm -2 fileA fileB  #不显示第2列
$ comm -3 fileA fileB  #不显示第3列
```
```shell
#示例：A(111,222,333);B(222,333,444)
sybs@shs:~$ comm  a.txt b.txt
111
                 222
                 333
        444
```






#8. 软件管理

https://www.cnblogs.com/clicli/p/6371118.html

**Rpm管理器**

```shell
$ rpm -qa #显示已安装
$ rpm -ivh package.rpm #安装
$ rpm -U package.rpm #更新
$ rpm -e package_name.rpm #删除
```
**Yum管理器**

```shell
$ yum list #列出安装的所有包
$ yum install pkg_name -y #下载并安装
$ yum update pkg_name #更新一个rpm包
$ yum remove pkg_name #删除一个rpm包
$ yum search pkg_name #在rpm仓库中搜寻
$ yum clean all       #清除缓存目录下的软件包

```



#9. 哈希签名

```shell
$ hash -l     #Linux会将执行过的命令缓存在hash表
$ hash -r     #清除哈希表
```
```shell
# 文件签名(输出签名数字和源文件路径)
$ md5sum a.txt >a.md5
$ sha1sum a.txt >a.sha1
$ sha256sum a.txt >a.sha256
$ sha512sum a.txt >a.sha512

# 签名校验
$ md5sum -c <a.md5  

$ sha1sum a.txt >a.sha1sum            #签名
$ sha1sum -c <(grep a.txt a.sha1sum)  #验签

# 字符串签名
$ printf "hello"|sha256sum
$ echo -n "hellp"|sha256sum|cut -d ' ' -f1  #删除文件名
```
_mac_
```shell
计算 MD5 校验和
md5 /tmp/hello.txt
计算 SHA-1 校验和
shasum -a 1 /tmp/hello.txt
计算 SHA-256 校验和
shasum -a 256 /tmp/hello.txt
```
_案例：签名http请求_

```shell
#!/bin/bash

: '说明：在PPGo_job中配置定时任务，执行以下示例的curl请求参数，
    即：在url末尾追加电子签名，在服务端进行签名验证，以防止外部恶意调用。
    请求方法：md5(secret.timespan)'

secret="204NAOB7JND0YRRA"       #密钥
timespan=$(date +%s)            #时间戳
raw=$secret"."$timespan         #签名字符串
sign=`echo $raw| md5sum | cut -d ' ' -f 1`  #签名
attach="timespan="$timespan"&sign="$sign

# api接口（注意末尾是否要加&）
api_url="http://deeplink.adxmax.com/api/update?over=0&"$attach
echo $api_url
curl $api_url
```




# 10.定时任务
- https://www.runoob.com/w3cnote/linux-crontab-tasks.html

```shell
# 服务管理(状态|启动|停止|重启|加载)
$ service crond status|start|stop|restart|reload

# 系统任务
$ cat /etc/crontab

# 用户任务(相当于：vim /var/spool/cron/$whoami)
$ crontab -l  #查看任务
$ crontab -e #编辑任务
$ crontab -r  #删除任务

# 查看日志
$ ll /var/log/cron*
```
**示例：**

```shell
[root@vmcontabo ~]# crontab -l
# 每个两分钟执行测试命令
*/2 * * * * echo `date` >> $HOME/test.txt

# 每星期六的晚上11:00pm重启smb
0 23 * * 6 /etc/init.d/smb restart

```





# 11.服务管理

service

systemctl






# 12.time用法
1)实际时间(real time): 从command命令行开始执行到运行终止的消逝时间；
2)用户CPU时间(user CPU time): 命令执行完成花费的用户CPU时间，即命令在用户态中执行时间总和；
3)系统CPU时间(system CPU time): 命令执行完成花费的系统CPU时间，即命令在核心态中执行时间总和。



# 13 trap
https://www.jianshu.com/p/b26d4e520385


<br/>

https://baijiahao.baidu.com/s?id=1637922221053576019&wfr=spider&for=pc

https://www.cnblogs.com/liuzhipenglove/p/7058726.html



```shell
#！bin/sh
sleep 3s
echo hello world
```
```shell
$ time hello.sh
hello world

real    0m3.015s
user    0m0.002s
sys    0m0.005s
```



```sh
function Usage() {
cat << HELP
Usage: docker - search NAME[:TAG]
docker - search list all tags for docker image on a remote registry.
Example:
docker - search(default nginx)
docker - search nginx
docker - search nginx: 1.15.8
docker search nginx | docker - search
docker search nginx | docker - search : 1.15.8
echo nginx | docker - search
echo nginx | docker - search : 1.15.8
HELP
}
```
参考教程：
http://www.92csz.com/study/linux/
http://c.biancheng.net/cpp/linux/
https://linux.cn/article-6314-1.html

https://linux.cn/article-11008-1.html

