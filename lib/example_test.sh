#!/bin/bash
# shellcheck source=/dev/null
source ./example.sh

# 编写单元测试函数，函数名格式: testXXX
# 正向断言: 即左侧模拟0值结果
function testDemo() {
    [[ $(arch) == "x64" ]] || return 1
    [[ $(arch) != "x86" ]] || return 1

    contain "Linux" "Lin" || return 1
    ! contain "Linux" "abc" || return 1
}

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
# unitStart
