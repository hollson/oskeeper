#!/bin/bash
# shellcheck source=/dev/null
source sdk.sh

# 模拟断言成功
function testOK() {
  return 0
}

# 模拟断言失败
function testErr() {
  return 1
}

function testDateTime() {
  dateTime
}

# 正向断言: 即左侧模拟0值结果
function testArch() {
  [[ $(arch) == "x64" ]] || return 1
  [[ $(arch) != "x86" ]] || return 1
  [[ $(arch) != "x32" ]] || return 1
}

function testHas() {
  ext=bmp
  list=(jpg bmp png)

  has "${list[*]}" ${ext} || return 1
  ! has "${list[*]}" "abc" || return 1
  ! has "${list[*]}" "xyz" || return 1
  has "${list[*]}" "png" || return 1
}

function testCompare() {
  [[ $(compare 2 1) == 1 ]] || return 1
  [[ $(compare 1 2) == -1 ]] || return 1
  [[ $(compare 2 2) == 0 ]] || return 1
  [[ $(compare 1 2) -lt 0 ]] || return 1
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

function testContain() {
  contain "Linux" "Lin" || return 1
  contain "Linux" "Linux" || return 1
  ! contain "Linux" "unix" || return 1
  ! contain "Bye" "ByeBye" || return 1
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
