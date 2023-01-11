#!/bin/bash
# shellcheck source=/dev/null
source ./sdk.sh

# 全局变量
export APP_NAME="Example Project" # 应用名称
export APP_VERSION="v2.0.0"       # 应用版本

#CMD build|-|编译项目
function build() {
    logInfo "Todo:编译程序"
}

#CMD install|ins|安装程序
function install() {
    logInfo "Todo:安装程序"
    return 1
}

#CMD run|-|运行程序
function run() {
    logErr "Todo:运行失败"
    return 1
}

#CMD status|stt|查看服务状态
function status() {
    logInfo "Todo:查看状态"
}

#FUN demo|示例函数
function demoFunc() {
    logInfo "Todo:查看状态"
}

# 继承通用命令，并重载main函数
#CMD list|-|查看函数列表
#CMD version|ver|查看应用版本
#CMD help|*|查看帮助说明
main
