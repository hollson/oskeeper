#!/bin/bash
# shellcheck source=/dev/null
source ./sdk.sh

# 全局变量
export APP_NAME="Example Project" # 应用名称
export APP_VERSION="v2.0.0"       # 应用版本

## build@编译项目
function Build() {
    logInfo "编译程序"
}

## runn@运行项目
function Run() {
    logErr "运行失败"
    return 1 #返回错误
}

## build@查看服务状态
function Status() {
    logWarn "查看状态"
}

# 注册帮助信息
main
