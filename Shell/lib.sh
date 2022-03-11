#!/bin/bash

# =================================================================
#  Shell通用函数库
# =================================================================

## echox@输出彩色字符
echox() {
    PLAIN='\033[0m'
    txt=${*:2}
    style=""
    if [[ $# -eq 3 ]]; then
        style="1;"
        txt=${*:3}
    fi

    case $1 in
    black | Black) color="\033[${style}30m" ;;                 # 黑色(默认)
    red | RED) color="\033[${style}31m" ;;                     # 红色
    green | GREEN) color="\033[${style}32m" ;;                 # 绿色
    yellow | YELLOW) color="\033[${style}33m" ;;               # 黄色
    blue | BLUE) color="\033[${style}34m" ;;                   # 蓝色
    magenta | MAGENTA) color="\033[${style}35m" ;;             # 洋紫
    cyan | CYAN) color="\033[${style}36m" ;;                   # 青色
    err | error | ERROR) color="\033[${style}31m❌ " ;;         # 「 错误 」
    ok | OK | success | SUCCESS) color="\033[${style}32m✅ " ;; # 「 成功 」
    warn | WARN) color="\033[${style}33m⛔️ " ;;                # 「 警告 」
    info | INFO) color="\033[${style}34m🔔 " ;;                 # 「 提示 」
    *) color="\033[${style}30m" ;;
    esac
    # 格式：echo -e "\033[风格;前景色;背景色m内容\033[0m"
    echo -e "${color}${txt}${PLAIN}"
}

# 测试：
# echox black SOLD "黑色粗体文字"
# echox RED SOLD "红色粗体文字"
# echox GREEN "绿色文字"
# echox YELLOW "黄色文字"
# echox BLUE "蓝色文字"
# echox MAGENTA "洋紫文字"
# echox CYAN "青色文字"
# echox error 1 "错误信息"
# echox ok "成功信息"
# echox warn "警告信息"
# echox info "提示消息"

# =================================================================

## cpu@查看CPU架构
cpu() {
    case "$(uname -m)" in
    i686 | i386) echo 'x32' ;;
    # x86_64 | amd64) echo 'x64' ;;
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

## help@帮助说明
function usage() {
    echox blue solid "======================================================"
    echox blue solid "        欢迎使用「SHELL-BOX」shell通用库"
    echox blue solid "======================================================"

    echo -e "用法：\n box [command] <param>"
    echo
    echo "Available Commands:"
    echo -e "\033[35m 函数  \t说明:\033[0m"
    sed -n "s/^##//p" "$0" | column -t -s '@-' | grep --color=auto "^[[:space:]][a-zA-Z_]\+[[:space:]]"
    echo
    echo -e "更多详情，请参考 https://github.com/hollson\n"
}

# 加载初始项
function load() {
    case $0 in
    run) run ;;
    dok | docker) docker ;;
    ver | version) version ;;
    *) usage ;;
    esac
}
load

# https://www.jb51.net/article/54488.htm
# https://www.jb51.net/article/48057.htm
