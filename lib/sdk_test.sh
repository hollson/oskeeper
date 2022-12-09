#!/bin/bash
source sdk.sh

function testOK() {
  echox info 1 "this is testOK"
  return 0
}

function testErr() {
  #  $FUNCNAME
  echo "$FUNCNAME"
  echox error 1 "this is testErr"
  return 99
}

function testEchox() {
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

function testDateTime() {
  dateTime
}

function testCompare() {
  compare 2 1
  compare 1 1
  compare 1 2
}

function testContain() {
  contain "linux" "lin"
  contain "linux" "abc"
  contain "linux" "linuxlinux"
}

function testLog() {
  log hello world
  logInfo "提示信息"
  logWarn "警告提醒"
  logError "一般错误"
  logFail "致命错误"
}

function testNext() {
  next "${@:1}"
  echo done
}
# 加载单元测试处理程序
#unittest "${@:1}"


#unittest $(testList)


unittest testLog
unittest testContain
unittest testCompare
unittest testOK
unittest testErr
unittest testNotfound

#grep test ./sdk_next.sh