#!/bin/bash
# shellcheck disable=SC1090
import() { . "$1" &>/dev/null; }

import sdk.sh
#set -e
params="${@:1}" #二级命令参数

function testEchox() {
  # 测试：
  echox black SOLD "字体+样式"
  echox RED SOLD "字体+样式"
  echox GREEN "字体"
  echox YELLOWdd "字体"
  echox BLUE "字体2"
  echox MAGENTA "字体"
  echox CYAN "字体"
  echox error 1 "错误信息+样式"
  echox ok "成功信息"
  echox warn "警告信息"
  echox info "提示消息"
}

function testOK() {
  echox info 1 "this is testOK"
  return 0
}

function testErr() {
  echox error 1 "this is testErr"
  return 99
}

# 126: 不可执行
# 127: 命令不存在
function testx() {
  set +e
  $1 &>/dev/null
  # shellcheck disable=SC2181
  result=$?

  if [ $result -eq 127 ]; then
    echox error 1 "【NotFound】函数或命令不存在-$1"
#    return
  fi
  if [ $result -ne 0 ]; then
    echox error 1 "【UT】\t 不通过【$1】$?"
    exit 1
  fi
  echox success 1 "【UT】\t 通过【$1】"
}

testx $params