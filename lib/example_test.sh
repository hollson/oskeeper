#!/bin/bash
# shellcheck source=/dev/null
source ./example.sh

# 编写单元测试函数，函数名格式: testXXX
function testBuild() {
    Build
}

function testRun() {
    Run
}

function testStatus() {
    Status
}

# 未定义
function testStop() {
    undifined
}

# 启动单元测试，必须放置在脚本末尾
unitStart
