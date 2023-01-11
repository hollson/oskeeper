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

# 测试build命令
function testBuild() {
    build
}

# 测试install命令
function testInstall() {
    install
}

# 测试run命令
function testRun() {
    run
}

# 测试status命令
function testStatus() {
    status
}

# 未定义的函数
function testStop() {
    undifined
}

# 启动单元测试，必须放置在脚本末尾
unitStart
