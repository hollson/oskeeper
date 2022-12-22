#!/bin/bash
source ./sdk.sh

# 编译项目
function Build() {
    logInfo "编译程序"
}

function Run() {
    logErr "运行失败"
    return 1 #返回错误
}

function Status() {
    logWarn "查看状态"
}

#reload  注册
