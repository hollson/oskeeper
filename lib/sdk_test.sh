#!/bin/bash
# shellcheck source=/dev/null
source sdk.sh

function testArch() {
  [[ $(arch) == "x64" ]] || return 1
  [[ $(arch) == "x86" ]] || return 0
}

function testHas() {
  ext=bmp
  list=(jpg bmp png)

  has "${list[*]}" ${ext} || return 1 # 如果不存在,则结果错误
  has "${list[*]}" "abc" || return 0  # 如果存在,  则结果正确
}

function testOK() {
  echox BLUE "this is testOK"
  return 0
}

function testErr() {
  echox BLUE "this is testErr"
  return 1
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
  [[ $(compare 2 1) == 1 ]] || return 1
  [[ $(compare 1 2) == -1 ]] || return 1
  [[ $(compare 2 2) == 0 ]] || return 1
  [[ $(compare 2 2) == -1 ]] || return 0
}

function testContain() {
  contain "Linux" "Lin"
  contain "Linux" "abc"
  contain "Linux" "LinuxLinux"
}

function testLog() {
  log hello world
  logInfo 你好 世界
  logInfo "提示信息"
  logWarn "警告提醒"
  logErr "一般错误"
  logFail "致命错误"
}

function testSysInfo() {
  sysInfo
}

function testSysInspect() {
  sysInspect
}

function testNotfound() {
  notfound
}

# (针对性)单元测试
#unitTest testOK
#unitTest testErr
#unitTest testArch
#unitTest testOS
#unitTest testLog
#unitTest testEchox
#unitTest testContain
#unitTest testCompare
#unitTest testSum

# (自动化)单元测试
unitStart
