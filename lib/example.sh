#!/bin/bash
# shellcheck source=/dev/null
source ./sdk.sh

# 全局变量
export APP_NAME="Example Project" # 应用名称
export APP_VERSION="v2.0.0"       # 应用版本

#CMD build|编译项目
function build() {
    logInfo "编译程序"
}


#CMD run|运行项目
function run() {
    logErr "运行失败"
    return 1 #返回错误
}


#CMD status|查看服务状态
function status() {
    logWarn "查看状态"
}

# 刷新静态元数据
main
