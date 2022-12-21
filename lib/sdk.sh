#!/bin/bash
import() { . "$1" &>/dev/null; }
# ==========================================================================
# Shell开发工具库(Shell Development Kit)
# 查看函数列表： ./sdk.sh list
# 下载/更新脚本：
#   curl -Ssl -O https://github.com/hollson/oskeeper/releases/download/v1.0.0/sdk.sh && chmod +x ./sdk.sh
# 更多详情，请参考 https://github.com/hollson/oskeeper
# ==========================================================================

# 全局变量
cmd=$1        # 二级命令
params=${*:2} # 二级命令参数

readonly SIZE1K=1024       # 容量大小(1K)
readonly SIZE1M=1048576    # 容量大小(1M)
readonly SIZE1G=1073741824 # 容量大小(1G)

ConsoleLog=on        # 是否打印控制台日志(on/off)
LogPath="./dump.log" # 日志文件(环境变量: $SDK_LOG_PATH)
TestVerbose=off      # 打印单元测试过程(环境变量: $TEST_VERBOSE,如: export TEST_VERBOSE=on)

OS=$(uname -s)
BASE_NAME=$(basename "$0") # 脚本名称
SDK_VERSION="v1.0.0"       # 当前sdk版本

import sdk_ut.sh
import base.sh

function init() {
  if [ -n "$SDK_LOG_PATH" ]; then
    LogPath="$SDK_LOG_PATH"
  fi
}
init
# =================================通用函数=====================================

## arch@查看CPU架构
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
  *) echox warn "unknown" && return 1 ;;
  esac
  return 0
}

## echox@打印彩色字符
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

  err | fail | error | ERROR) color="\033[1;31m❌  " ;;        # 「 错误 」
  ok | OK | success | SUCCESS) color="\033[${style}32m✅  " ;; # 「 成功 」
  warn | WARN) color="\033[${style}33m⛔️ " ;;                 # 「 警告 」
  info | INFO) color="\033[${style}34m🔔 " ;;                  # 「 提示 」
  *) color="\033[${style}30m" ;;
  esac
  # 格式：echo -e "\033[风格;字体;背景m内容\033[0m"
  echo -e "${color}${txt}${PLAIN}"
}

# 打印日志
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

# 提示信息
function logInfo() {
  log info "${*:1}"
}

# 警告提醒
function logWarn() {
  log warn "${*:1}"
}

# 一般错误
function logError() {
  log error "${*:1}"
}

# 致命错误
function logFail() {
  log fail "${*:1}"
}

# 加减乘除模
#expr 9 + 3
#expr 9 - 3
#expr 9 \* 3
#expr 9 / 3
#expr 9 % 2
## sum@求两数之和
function sum() {
  echo $(($1 + $2))
}

## contain@是否包含子串,如：contain src sub
function contain() {
  if [[ $1 == *$2* ]]; then
    echo true
    return 0
  fi
  echo false
}

## next@阻塞并确定是否继续
function next() {
  read -r -p "是否继续?(Y/n) " next
  [ "$next" = 'Y' ] || [ "$next" = 'y' ] || exit 0
}

## compare@比较大小
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

function list() {
  echox blue solid "======== 函数库列表 ========"
  echox magenta " 命令\t  说明"
  sed -n "s/^##//p" "$0" | column -t -s '@-' | grep --color=auto "^[[:space:]][a-zA-Z_]\+[[:space:]]"
  echo
}

# =================================单元测试=====================================
# 单元测试
# 加载单元测试: unitTest "${@:1}"
# 126: 不可执行
# 127: 命令不存在
function unitTest() {
  set +e
  if [[ "$TEST_VERBOSE" == "on" || "$TestVerbose" == "on" ]]; then
    $1
  else
    $1 &>/dev/null
  fi

  result=$?
  #  echo "$result"
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
  typeset -F | awk '/test[A-Z]+/ && !/testList/ {print $3}'
  echo
}

# 启动单元测试，如:
# ./sdk_test.sh
# ./sdk_test.sh list
# ./sdk_test.sh testOK
# ./sdk_test.sh testErr
function unitLaunch() {
  set +e
  if [ "$cmd" == "" ]; then
    echox BLUE 1 "执行单元测试, 命令如："
    printf "单元测试列表: \t\033[34m %s \033[0m\n" "./sdk_test.sh list"
    printf "执行具体函数: \t\033[34m %s \033[0m\n" "./sdk_test.sh testOK"
    printf "执行具体函数: \t\033[34m %s \033[0m\n" "./sdk_test.sh testErr"
    printf "执行全部测试: \t\033[34m %s \033[0m\n" "./sdk_test.sh all"
    echo
    echo -n "可打印单元测试过程:  "
    echox BLUE "export TEST_VERBOSE=on"
    echo
    return 0
  fi

  if [ "$cmd" == "list" ]; then
    echox blue solid "======== 单元测试函数列表 ========"
    unitList
    return 0
  fi

  #执行所有单元测试
  if [ "$cmd" == "all" ]; then
    all=$(unitList)
    # shellcheck disable=SC2048
    for v in ${all[*]}; do
      unitTest "$v"
    done
    return
  fi

  # 执行某个单元测试函数
  unitTest "$cmd"
}

# =================================类库帮助=====================================
function version() {
  echox blue SOLD "sdk $SDK_VERSION"
}

## help@帮助说明
function help() {
  echox blue solid "========================================================="
  echox blue solid "         欢迎使用sdk(Shell Development Kit) $SDK_VERSION"
  echox blue solid "========================================================="

  echo -e "用法：\n sdk [command] <param>"
  echo
  echo "Available Commands:"
  echox magenta " 命令\t简写\t说明"
  sed -n "s/^##//p" "$0" | column -t -s '@-' | grep --color=auto "^[[:space:]][a-zA-Z_]\+[[:space:]]"
  echo
  echo -e "更多详情，请参考 https://github.com/hollson\n"
}

# Main函数
function main() {
  if [[ "$BASE_NAME" == "sdk.sh" ]]; then
    case $cmd in
    list) list ;;
    ut | test) ut ;;
    ver | version) version ;;
    *) help ;;
    esac
  fi
}
main

function _xxx() {
  echo "$OS"
  echo "$params"
  echo $SIZE1K
  echo $SIZE1M
  echo $SIZE1G
}

#sed -i '/hello/d' ./a.txt # 删除关键字行
#sed -i '1d' a.txt         # 删首行
#sed -i '2d' a.txt         # 删除第2行
#sed -i '$d' a.txt         # 删除尾行
#sed -i 's/[ ]*//g' a.txt  # 删除空格
#sed -i '/^$/d' a.txt      # 删除空行
