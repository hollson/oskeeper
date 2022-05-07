#!/bin/bash

source sdk.sh

## build-_@编译程序
function build() {
    echox ok 1 "编译成功\n"
}

## run-_@运行程序
function run() {
    echox ok 1 "程序已启动...\n"
}

## stop-_@停止服务
function stop() {
    echox blue 1 "🔴 准备停止服务"
    next
    echox warn 1 "程序已停止运行...\n"
}

## version-ver@查看系统版本
function version() {
    echox ok 1 "=> v2.0.0\n"
}

## status-stt@查看服务状态
function status() {
    echox ok 1 "running\n"
}

## test-_@测试
function test() {
    sum 2 -5
    echox ok "2+(-5)=$RESULT"
    echox info 1 "当前CPU架构：$(arch)"
}

## help-*@帮助说明
function help() {
    usage
}

function load() {
    case $cmd in
    build) build ;;
    run) run ;;
    stop) stop ;;
    status|stt) status ;;
    list) list ;;
    test) test ;;
    ver | version) version ;;
    *)usage;;
    esac
}
load
