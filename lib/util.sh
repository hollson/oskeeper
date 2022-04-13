#!/bin/bash

# =================================================================
#  Shell通用函数库
#  查看函数列表： ./util.sh list
#  下载/更新脚本：curl -Ssl -O https://raw.githubusercontent.com/hollson/oskeeper/b63438f5bd7af8c9b659496e4ed51b64858a5737/lib/util.sh
#  更多详情，请参考 https://github.com/hollson/oskeeper
# =================================================================

cmd=$1 # 命令参数

## echox@打印彩色字符
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

    err | error | ERROR) color="\033[${style}31m❌  " ;;         # 「 错误 」
    ok | OK | success | SUCCESS) color="\033[${style}32m✅  " ;; # 「 成功 」
    warn | WARN) color="\033[${style}33m⛔️ " ;;                 # 「 警告 」
    info | INFO) color="\033[${style}34m🔔 " ;;                  # 「 提示 」
    *) color="\033[${style}30m" ;;
    esac
    # 格式：echo -e "\033[风格;字体;背景m内容\033[0m"
    echo -e "${color}${txt}${PLAIN}"
}

# 测试：
# echox black SOLD "字体+样式"
# echox RED SOLD "字体+样式"
# echox GREEN "字体"
# echox YELLOW "字体"
# echox BLUE "字体"
# echox MAGENTA "字体"
# echox CYAN "字体"
# echox error 1 "错误信息+样式"
# echox ok "成功信息"
# echox warn "警告信息"
# echox info "提示消息"

# =================================================================

## next@是否继续
function next() {
    read -r -p "是否继续?(y/n) " next
    [ "$next" = 'Y' ] || [ "$next" = 'y' ] || exit 1
}
# next

# =================================================================

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
    *) echox err "未知CPU架构" ;;
    esac
    return 0
}
# arch

# =================================================================

## sum@求两数之和
function sum() {
    RESULT=$(($1 + $2))
}

# 测试：
# sum -2 -3
# echo "🎯 sum: $RESULT"

# =================================================================

## contain@字符串是否包含子串
function contain() {
    ret=$(echo "$1" | grep "$2")
    if [[ "$ret" != "" ]]; then
        RESULT=1 # 存在
    else
        RESULT=0 # 不包含
    fi
}

# 测试：
# contain "linux" "lin"
# echo "🎯 contain: $RESULT"

# =================================================================

## compare@比较两个数的大小
function compare() {
    if test "$1" -lt "$2"; then
        RESULT=-1 # 小于
    elif test "$1" -eq "$2"; then
        RESULT=0 # 等于
    else
        RESULT=1 # 大于
    fi
}

# # 测试：
# compare 2 1
# echo "🎯 compare: $RESULT"

# =================================================================

## usage@通用帮助说明
function usage() {
    echox blue solid "======================================================"
    echox blue solid "         欢迎使用「SHELL-BOX」shell通用库"
    echox blue solid "======================================================"

    echo -e "用法：\n box [command] <param>"
    echo
    echo "Available Commands:"
    echox magenta " 命令\t简写\t说明"
    sed -n "s/^##//p" "$0" | column -t -s '@-' | grep --color=auto "^[[:space:]][a-zA-Z_]\+[[:space:]]"
    echo
    echo -e "更多详情，请参考 https://github.com/hollson\n"
}

function list() {
    echox blue solid "======== 函数库列表 ========"
    echox magenta " 命令\t  说明"
    sed -n "s/^##//p" "$0" | column -t -s '@-' | grep --color=auto "^[[:space:]][a-zA-Z_]\+[[:space:]]"
    echo
}

function version() {
    echox bule "v1.0.0"
}

# 加载初始项
# shellcheck disable=SC2120
function load() {
    case $cmd in
    run) run ;;
    list) list ;;
    ver | version) version ;;
    esac
}
load
