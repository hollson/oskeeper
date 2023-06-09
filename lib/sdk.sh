#!/bin/bash
# shellcheck source=/dev/null
import() { source "$1" &>/dev/null; }

# ======================= SDK (Shell Development Kit) ========================
# 名称: SDK(Shell Development Kit)
# 作者: Hollson
# 说明: Shell开发工具库,包含常用shell函数，单元测试，帮助命令等
# 下载：https://github.com/hollson/oskeeper/releases/download/leatest/sdk.tar.gz
# 用法： ./sdk.sh help
# =============================================================================

# 全局变量
export APP_NAME="SDK(Shell Development Kit)" # 应用名称
export APP_VERSION="v1.0.1"                  # 应用版本

COMMAND=$1           # 二级命令
PARAMS=${*:2}        # 二级命令参数
ConsoleLog=on        # 是否打印控制台日志(on/off)
LogPath="./dump.log" # 日志文件(环境变量: export SDK_LOG_PATH=./)
TestVerbose=off      # 打印单元测试过程(环境变量: export TEST_VERBOSE=on/off)

# 通用常量
readonly SIZE1K=1024       # 容量大小(1K)
readonly SIZE1M=1048576    # 容量大小(1M)
readonly SIZE1G=1073741824 # 容量大小(1G)

function init() {
  if [ -n "$SDK_LOG_PATH" ]; then
    LogPath="$SDK_LOG_PATH"
  fi
}
init

# =================================通用函数=====================================

#FUN echox|打印彩色字符内容
#for i in {1..8};do echo -e "\033[$i;31;40m hello shell \033[0m";done
#for i in {30..37};do echo -e "\033[$i;40m hello shell \033[0m";done
#for i in {40..47};do echo -e "\033[47;${i}m hello shell \033[0m";done
function echox() {
  # Reset        = 0 // 重置
  # Bold         = 1 // 加粗
  # Faint        = 2 // 模糊
  # Italic       = 3 // 斜体
  # Underline    = 4 // 下划线
  # BlinkSlow    = 5 // 慢速闪烁
  # BlinkRapid   = 6 // 快速闪烁
  # ReverseVideo = 7 // 反白/反向显示
  # Concealed    = 8 // 隐藏/暗格
  # CrossedOut   = 9 // 删除
  # FontBlack    = 30 // 「字体」黑色
  # FontRed      = 31 // 「字体」红色
  # FontGreen    = 32 // 「字体」绿色
  # FontYellow   = 33 // 「字体」黄色
  # FontBlue     = 34 // 「字体」蓝色
  # FontMagenta  = 35 // 「字体」品红/洋紫
  # FontCyan     = 36 // 「字体」青色
  # FontWhite    = 37 // 「字体」白色
  # BackBlack    = 40 // 「背景」黑色
  # BackRed      = 41 // 「背景」红色
  # BackGreen    = 42 // 「背景」绿色
  # BackYellow   = 43 // 「背景」黄色
  # BackBlue     = 44 // 「背景」蓝色
  # BackMagenta  = 45 // 「背景」品红/洋紫
  # BackCyan     = 46 // 「背景」青色
  # BackWhite    = 47 // 「背景」白色

  PLAIN='\033[0m'
  txt=${*:2}
  style=""
  if [[ $# -eq 3 ]]; then
    style="1;"
    txt=${*:3}
  fi

  case $1 in
  black | Black) color="\033[${style}30m" ;;     # 黑色(默认)
  red | RED) color="\033[${style}31m" ;;         # 红色
  green | GREEN) color="\033[${style}32m" ;;     # 绿色
  yellow | YELLOW) color="\033[${style}33m" ;;   # 黄色
  blue | BLUE) color="\033[${style}34m" ;;       # 蓝色
  magenta | MAGENTA) color="\033[${style}35m" ;; # 洋紫
  cyan | CYAN) color="\033[${style}36m" ;;       # 青色

  err | fail | error | ERROR) color="\033[1;31m❌ " ;;        # 「 错误 」
  ok | OK | success | SUCCESS) color="\033[${style}32m✅ " ;; # 「 成功 」
  warn | WARN) color="\033[${style}33m⛔️ " ;;                # 「 警告 」
  info | INFO) color="\033[${style}34m🔔 " ;;                 # 「 提示 」
  *) color="\033[${style}30m" ;;
  esac
  # 格式：echo -e "\033[风格;字体;背景m内容\033[0m"
  echo -e "${color}${txt}${PLAIN}"
}

#FUN arch|查看CPU架构
function arch() {
  case "$(uname -m)" in
  i686 | i386) echo 'x32' ;;
  x86_64 | amd64) echo 'x64' ;;
  armv5tel) echo 'arm32-v5' ;;
  armv6l) echo 'arm32-v6' ;;
  armv7 | armv7l) echo 'arm32-v7a' ;;
  armv8 | aarch64) echo 'arm64-v8a' ;;
  mips64le) echo 'mips64le' ;;
  mips64) echo 'mips64' ;;
  mipsle) echo 'mips32le' ;;
  mips) echo 'mips32' ;;
  ppc64le) echo 'ppc64le' ;;
  ppc64) echo 'ppc64' ;;
  riscv64) echo 'riscv64' ;;
  s390x) echo 's390x' ;;
  *) echox warn "unknown" ;;
  esac
}

# Mac(达尔文)系统
function darwin() {
  [[ "$(uname -s)" == "Darwin" ]]
}

#FUN dateTime|打印当前时间
function dateTime() {
  date "+%Y-%m-%d %H:%M:%S"
}

# 读取当前脚本的绝对路径
function scriptFile() {
  cd "$(dirname "$0")" && pwd | xargs printf "%s/$(basename "$0")\n"
}

#FUN gateWay|获取默认网关
function gateWay() {
  if [ "$(uname -s)" == "Darwin" ]; then
    route -n get default | awk -F: '/gateway/{print $2}' | xargs
    return
  fi
  ip route | awk '/default/{print $3}'
}

#FUN ip4|获取内网IP(v4)
function ip4() {
  # unset IPv4
  sub=$(gateWay | cut -d '.' -f1,2,3)
  ips=$(ifconfig | awk '/inet /{print $2}')

  # 24位子网
  echo -n "$ips" | grep "${sub}3" && return

  # 16位子网
  sub=$(gateWay | cut -d '.' -f1,2)
  echo -n "$ips" | grep "${sub}"
}

#FUN outIP4|获取公网IP(v4)
function outIP4() {
  # IP4 && 请求超时3秒 && 数据传输2秒
  curl -4 -s --connect-timeout 3 -m 2 ifconfig.me ||
    curl -4 -s --connect-timeout 3 -m 2 icanhazip.com ||
    curl -4 -s --connect-timeout 3 -m 2 ifconfig.co ||
    curl -4 -s --connect-timeout 3 -m 2 ipecho.net/plain
}

#FUN has|集合是否包含某个元素
# ext=bmp
# list=(jpg bmp png)
# has "${list[*]}" ${ext}
function has() {
  all=$1
  tar=$2
  # shellcheck disable=SC2048
  for v in ${all[*]}; do
    [[ "$tar" == "$v" ]] && return
  done
  return 1
}

#FUN log|打印日志
# log "普通日志"
# log info  "提示信息"
# log warn " 警告提醒"
# log error "一般错误，如: 用户执行结果失败、参数错误等"
# log fail  "致命错误，如: 系统不兼容、命令错误等异常"
function log() {
  content="[$(dateTime)] ${*:1}"
  if [ "$1" == "info" ] || [ "$1" == "warn" ] || [ "$1" == "error" ] || [ "$1" == "fail" ]; then
    content="[$(dateTime)] [$1] ${*:2}"
  fi
  if [ $ConsoleLog == "on" ]; then
    echox "$1" "$content"
  fi
  echo -e "$content" >>"$LogPath"
}

#FUN logInfo|打印提示信息
function logInfo() {
  log info "${*:1}"
}

#FUN logWarn|打印警告提醒
function logWarn() {
  log warn "${*:1}"
}

#FUN logWarn|打印一般错误
function logErr() {
  log error "${*:1}"
}

#FUN logWarn|打印致命错误
function logFail() {
  log fail "${*:1}"
}

#FUN contain|是否包含子串,格式：contain <src> <sub>
function contain() {
  [[ $1 == *$2* ]]
}

#FUN next|阻塞并确定是否继续
function next() {
  ! echo "${PARAMS}" | grep -oiE "\s\-y\s|\s\-y$|^-y\s|^-y$" >/dev/null || return 0
  read -r -p "是否继续?(Y/n) " next
  [ "$next" = 'Y' ] || [ "$next" = 'y' ] || exit 0
}

#FUN compare|比较两个数值的大小
# -1: a < b
#  0: a = b
#  1: a > b
function compare() {
  if test "$1" -lt "$2"; then
    echo -1
  elif test "$1" -eq "$2"; then
    echo 0
  else
    echo 1
  fi
}

# =================================配置文件=====================================

#FUN iniCheck|检查ini文件语法
# iniCheck ./config.ini
# iniCheck "ini content"
function iniCheck() {
  fileOrTxt="$1"
  [[ $# -lt 2 ]] || return 127
  [[ -f $1 ]] && fileOrTxt=$(cat "${fileOrTxt}")
  ret=$(echo "${fileOrTxt}" | awk -F= 'BEGIN{valid=1}{
        if(valid == 0) next  
        if(length($0) == 0) next
        gsub(" |\t","",$0)     
        head_char=substr($0,1,1)
        if (head_char != "#" && head_char != ";"){
            if( NF == 1){
                b=substr($0,1,1)
                len=length($0)
                e=substr($0,len,1)
                if (b != "[" || e != "]"){valid=0}
            }else if( NF == 2){
                b=substr($0,1,1)
                if (b == "["){ valid=0 }
            }else{ valid=0 } 
        }
    } END{print valid}')
  [[ $ret == 1 ]] || return 1
}

#FUN iniParser|解析ini配置文件
#参数1 文件名
#参数2 块名
#参数3 字段名
#返回0,表示正确,且能输出字符串表示找到对应字段的值
#否则其他情况都表示未找到对应的字段或者是出错
function iniParser() {
  fileOrTxt="$1"
  [[ $# == 3 ]] || return 1
  [[ -f $1 ]] && fileOrTxt=$(cat "${fileOrTxt}")

  declare -r blockName=$2 fieldName=$3
  declare -i beginBlock=0 endBlock=0
  echo "${fileOrTxt}" | while read -r line; do
    if [ "X$line" = "X[$blockName]" ]; then
      beginBlock=1
      continue
    fi

    if [ $beginBlock -eq 1 ]; then
      endBlock=$(echo "$line" | awk 'BEGIN{ret=0} /^\[.*\]$/{ret=1} END{print ret}')
      if [ "$endBlock" -eq 1 ]; then break; fi
      need_ignore=$(echo "$line" | awk 'BEGIN{ret=0} /^#/{ret=1} /^$/{ret=1} END{print ret}')
      if [ "$need_ignore" -eq 1 ]; then continue; fi
      field=$(echo "$line" | awk -F= '{gsub(" |\t","",$1); print $1}')
      value=$(echo "$line" | awk -F= '{gsub(" |\t","",$2); print $2}')
      if [ "X$fieldName" = "X$field" ]; then
        echo "$value"
        break
      fi
    fi
  done
}

#FUN jsonParser|解析json文件
# jsonParser jsonText key [defaultValue]
# 🚫 对嵌套对象的处理不太友好，建议使用jq命令
function jsonParser() {
  fileOrTxt=$1
  [[ $# -ge 2 ]] || return 1
  [[ -f "${fileOrTxt}" ]] >/dev/null && fileOrTxt=$(cat <"${fileOrTxt}" | tr -d '\n\r')

  defaultValue="null"
  if [[ "$3" != "" ]]; then defaultValue="$3"; fi
  awk -v json="${fileOrTxt}" -v key="$2" -v defaultValue="${defaultValue}" 'BEGIN{
        foundKeyCount = 0
        while (length(json) > 0) {
            pos = match(json, "\""key"\"[ \\t]*?:[ \\t]*");
            if (pos == 0) {if (foundKeyCount == 0) {print defaultValue;} exit 0;}
            ++foundKeyCount;
            start = 0; stop = 0; layer = 0;
            for (i = pos + length(key) + 1; i <= length(json); ++i) {
                lastChar = substr(json, i - 1, 1)
                currChar = substr(json, i, 1)
                if (start <= 0) { if (lastChar == ":") {
                    start = currChar == " " ? i + 1: i;
                    if (currChar == "{" || currChar == "[") {layer = 1;}}
                } else {if (currChar == "{" || currChar == "[") {++layer;}
                    if (currChar == "}" || currChar == "]") {--layer;}
                    if ((currChar == "," || currChar == "}" || currChar == "]") && layer <= 0) {
                        stop = currChar == "," ? i : i + 1 + layer;break;}}
                    }
            if (start <= 0 || stop <= 0 || start > length(json) || stop > length(json) || start >= stop) {
                if (foundKeyCount == 0) {print defaultValue;} exit 0;} 
                else {print substr(json, start, stop - start);
            }
            json = substr(json, stop + 1, length(json) - stop)}}' | xargs
}

# =================================系统信息=====================================

#FUN installer|查看当前系统的安装器
function installer() {
  arr=(dnf yum apt apt-get apk brew)
  for v in "${arr[@]}"; do
    which "$v" && return 0
  done
  return 127
}
#$(installer) --version

#FUN virtualize|检查当前系统是否为虚拟化环境
: '
 CPU状态参数：
 VT-x/Physics: 物理机
 Xen/Kvm:   开源虚拟化软件
 VMware:    付费虚拟化软件
 hyper-v:   微软虚拟化组件
 Kubepods： K8s容器化
 Docker:    Docker容器化
'
function virtualize() {
  if darwin; then
    echo "Physics"
    return 0
  fi

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

#FUN osRelease|查看系统(厂商)发行信息
# 查看系统发行版本(厂商)，如：
# CentOS Linux 7 (Core)
# Ubuntu 20.04 LTS (Focal Fossa)
# Debian GNU/Linux 11 (bullseye)
# uos 20
function osRelease() {
  if darwin; then
    sw_vers | awk -F: '/Product/{print $2}' | xargs
    return
  fi
  awk -F= '/^NAME=|^VERSION="/{print $2}' /etc/os-release | xargs
}

#FUN sysInfo|查看系统(静态)信息
function sysInfo() {
  if [ -f ~/.sdk/sys.info ]; then
    cat ~/.sdk/sys.info
    return
  fi

  mkdir -p ~/.sdk
  _os="$(uname -rms)"
  _cpu_mode="known"
  _cpu_count=1
  _physical=0
  _thread=0

  if darwin; then
    _cpu_mode=$(sysctl -n machdep.cpu.brand_string)
    _physical=$(sysctl -n machdep.cpu.core_count)
    _thread=$(sysctl -n machdep.cpu.thread_count)

  else
    _cpu_mode=$(awk -F: '/model name/{print $2}' /proc/cpuinfo | sort | uniq | xargs)
    _cpu_count=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
    _physical=$(awk '/cpu cores/{print $4}' /proc/cpuinfo | uniq)
    _thread=$(grep -c "processor" /proc/cpuinfo)
  fi

  cat <<EOF | column -s = -t >~/.sdk/sys.info
操作系统:= $_os
CPU型号:= $_cpu_mode
CPU数量:= $_cpu_count
物理核数:= $_physical
逻辑核数:= $_thread
发行版本:= $(osRelease)
安装器:= $(installer)
虚拟化状态:= $(virtualize)
EOF
  cat ~/.sdk/sys.info
}

#FUN sysInspect|系统诊断(动态)信息
: '
 CPU状态参数：
 %us：表示用户空间程序的cpu使用率（没有通过nice调度）
 %sy：表示系统空间的cpu使用率，主要是内核程序。
 %ni：表示用户空间且通过nice调度过的程序的cpu使用率。
 %id：空闲cpu
 %wa：cpu运行时在等待io的时间
 %hi：cpu处理硬中断的数量
 %si：cpu处理软中断的数量
 %st：被虚拟机偷走的cpu
 https://www.runoob.com/linux/linux-filesystem.html
'
function sysInspect() {
  echo -e "磁盘信息: \t 待完善..."
  if darwin; then
    echo -e "内存信息: \t $(top -l 1 | head -n 10 | sed -n "s/PhysMem: //p")"
    echo -e "CPU状态: \t $(top -l 1 | head -n 10 | sed -n "s/CPU usage: //p")"
  else
    echo -e "内存信息: \t $(free -h | sed -n 's/Mem:\s*//p' | awk '{print "total:"$1, "used:"$2,"buff:"$5,"available:"$6}')"
    echo -e "CPU状态: \t $(top -bn1 -ic | grep '%Cpu' | awk -F: '{print $2}' | xargs)"
  fi

  echo -e "网关  : \t $(gateWay)"
  echo -e "内网IP: \t $(ip4)"
  echo -e "公网IP: \t $(outIP4)"
}

#FUN gitBranch|获取当前的分支
function gitBranch() {
  git rev-parse --abbrev-ref "@{u}"
}

#FUN gitCommit|获取最近一次提交的ID
function gitCommit() {
  git rev-parse --short HEAD
}

#FUN gitAuthor|获取当前用户名
function gitAuthor() {
  git config user.name
}

#FUN gitTag|获取最近一次tag标签
function gitTag() {
  git describe --tags --abbrev=0
}

# =================================单元测试=====================================
# 单元测试
# 加载单元测试: unitTest "${@:1}"
# 126: 不可执行
# 127: 命令不存在
function unitTest() {
  # set +e
  if ! [[ $1 =~ ^test[A-Z] ]]; then
    printf "\033[1;31m[UT]\t\t⛔️\t\t\033[0m \033[30;41m%-20s\033[0m \t\t 测试函数不存在或不符合命名规范\n" "$1"
    return 126
  fi

  if [[ "$TEST_VERBOSE" == "on" || "$TestVerbose" == "on" ]]; then
    $1
  else
    $1 &>/dev/null
  fi

  result=$?
  # echo "$result"
  if [ $result -eq 127 ]; then
    printf "\033[1;31m[UT]\t\t⛔️\t\t\033[0m \033[30;41m%-20s\033[0m \t\t 函数/命令不存在\n" "$1"
    # echox error 1 "[NotFound] \t [$1]\t 函数/命令不存在"
    return
  fi
  if [ $result -eq 0 ]; then
    printf "\033[1;32m[UT]\t\t✅\t\t\033[0m \033[30;42m%-20s\033[0m\t\t 成功\n" "$1"
    # echox success 1 "[UT] \t [$1]\t 成功"
    return
  fi

  printf "\033[1;31m[UT]\t\t❌\t\t\033[0m \033[30;41m%-20s\033[0m\t\t 失败\n" "$1"
  # echox error 1 "[UT] \t [$1]\t 失败"
}

# 单元测试列表
function unitList() {
  # grep -oE "^\s*function\s+test[A-Z][a-zA-Z]+|^\s*test[A-Z][a-zA-Z]+\s*\(\s*\)" "$0" | grep -oE "test[A-Z][a-zA-Z]+"
  # typeset -F | awk '/test[A-Z][a-zA-Z]+/ && !/testList/ {print $3}'
  declare -F | awk '/test[A-Z][a-zA-Z0-9]+/ && !/testList/ {print $3}'
}

# 启动单元测试
function unitStart() {
  cur=$(basename "$0")
  if [[ "${cur}" != *_test.sh ]]; then
    echox warn "非法的测试文件"
    return 1
  fi

  set +e
  if [ "$COMMAND" == "" ]; then
    echox BLUE 1 "=== 🧪🧪🧪 执行单元测试 🧪🧪🧪==="
    echo -e "命令格式: "
    echox RED 1 "    ./${cur} <list|all|testXXX> [OPTIONS]"
    echo
    echo -e "Options: "
    echo -e "    -v,--verbose  打印详细信息"
    echo

    echo "示例："
    printf "1) 单元测试列表:  \033[34m %s \033[0m\n" "./${cur} list"
    printf "2) 执行具体函数:  \033[34m %s \033[0m\n" "./${cur} testXXX"
    printf "3) 执行全部测试:  \033[34m %s \033[0m\n" "./${cur} all"
    echo
    echo -n "设置verbose系统变量: "
    echox BLUE "export TEST_VERBOSE=on"
    echo
    return
  fi

  if [[ "${PARAMS[0]}" == "-v" || "${PARAMS[0]}" == "--verbose" ]]; then
    TestVerbose=on
  fi

  if [ "$COMMAND" == "list" ]; then
    echox blue solid "=== 🧪🧪🧪 单元测试列表 🧪🧪🧪==="
    unitList
    return
  fi

  #执行所有单元测试
  if [ "$COMMAND" == "all" ]; then
    all=$(unitList)
    # shellcheck disable=SC2048
    for v in ${all[*]}; do
      unitTest "$v"
    done
    return
  fi

  # 执行某个单元测试函数
  unitTest "$COMMAND"
}

# =================================SDK命令=====================================

#CMD list|查看函数列表, 格式: ./sdk.sh list [category]
function list() {
  echox magenta " 函数\t  |   说明"
  echox magenta "----------|-----------"
  sed -n "s/^#FUN//p" "$0" | column -t -s '|' | sort | grep --color=auto "^[[:space:]][a-zA-Z0-9_]\+[[:space:]]"
  echo
  echox BLUE 1 "执行某个函数(部分支持), 如: ./$(basename "$0") exec arch\n"
}

#CMD exec|执行某个函数(部分支持), 如: ./sdk.sh exec arch
# ./sdk.sh exec echox RED 1 你好
function exec() {
  # shellcheck disable=SC2068
  ${PARAMS[@]}
}

#CMD docs|查看帮助文档列表, 格式: ./sdk.sh docs
function docs() {
  echox warn "TODO"
}

#CMD man|查看帮助文档内容, 格式: ./sdk.sh man <command>
function man() {
  echox warn "TODO"
}

#CMD logf|监视当前脚本日志
function logf() {
  tail -f "${LogPath}"
}

#CMD version|查看sdk版本
function version() {
  echox blue SOLD "$APP_VERSION"
}

#CMD help|查看帮助说明
function help() {
  echox blue solid "=========================================================
     欢迎使用${APP_NAME} ${APP_VERSION}
========================================================="
  echo -e "用法：\n $(basename "$0") [command] <params>"
  echo
  echo "Available Commands:"
  cur=$(basename "$0")
  if [[ "${cur}" == "sdk.sh" ]]; then
    echox magenta " 命令\t  说明"
  else
    echox magenta " 命令\t 简称\t说明"
  fi

  sed -n "s/^#CMD//p" "$0" | column -t -s '|' | grep --color=auto "^[[:space:]][a-zA-Z0-9_]\+[[:space:]]"
  echo
  echo -e "更多详情，请参考 https://github.com/hollson\n"
}

# main函数.V1
function main1() {
  # echo "Invoker => ${FUNCNAME[1]}"
  [[ ${FUNCNAME[1]} == "main" ]] || return 0

  case $COMMAND in
  create | new) create ;;
  exec) exec ;;
  docs) docs ;;
  man) man ;;
  log) tail -20 "${LogPath}" ;;
  logf) logf ;;
  list | func | fun) list ;;
  ver | version) version ;;
  *) help ;;
  esac
}

# main函数.V2
function main() {
  [[ ${FUNCNAME[1]} == "main" ]] || return 0
  if [[ "${COMMAND}" == "" || "${COMMAND}" == "help" ]]; then
    help
    return 0
  fi
  cs=$(sed -n "s/^#CMD//p" "$0" | awk -F '|' '{print $1,$2}' | grep -E "[\s\|]*${COMMAND}[\s\|]*")
  if test $? || [[ ${cs} == "" ]]; then
    "$(echo "${cs}" | awk '{print $1}')" 2>/dev/null
    [[ $? != 127 ]] || echox warn "执行失败，请检查参数和CMD命令注释是否正确"
    return
  fi
  help
}

main

# ============================================================================

# 语法检测
function _xxx() {
  echo "$PARAMS"
  echo $SIZE1K
  echo $SIZE1M
  echo $SIZE1G
}
