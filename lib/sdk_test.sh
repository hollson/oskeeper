#!/bin/bash
source sdk.sh

function testArch() {
    arch
}

#function testNext() {
#  next
#  echo "Done"
#}
#testNext

function testOK() {
  echox BLUE "this is testOK"
  return 0
}

function testErr() {
  echox BLUE "this is testErr"
  return 1
}

function testSum() {
  sum 1 2
  sum 111 222
}

function testEchox() {
  echox black SOLD "字体+样式"
  echox RED SOLD "字体+样式"
  echox GREEN "字体"
  echox YELLOWdd "字体"
  echox BLUE "字体2"
  echox MAGENTA "字体"
  echox CYAN "字体"
  echox error "错误信息+样式"
  echox ok "成功信息"
  echox warn "警告信息"
  echox info 1 "提示消息"
}

function testDateTime() {
  dateTime
}

function testCompare() {
  compare 2 1
  compare 1 1
  compare 1
}

function testContain() {
  contain "linux" "lin"
  contain "linux" "abc"
  contain "linux" "linuxlinux"
}

function testLog() {
  log hello world
  logInfo 你好 世界
  logInfo "提示信息"
  logWarn "警告提醒"
  logError "一般错误"
  logFail "致命错误"
}


function testOS() {
    os
}

#unitTest testOK
#unitTest testErr
#unitTest testArch
#unitTest testOS
#unitTest testLog
#unitTest testEchox
#unitTest testContain
#unitTest testCompare
#unitTest testSum
#unitTest testNotfound

# 启动单元测试
unitLaunch