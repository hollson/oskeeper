#!/bin/bash
# shellcheck source=/dev/null
source sdk.sh

# 模拟断言成功
function testOK() {
  logInfo "test ok"
  return 0
}

# 模拟断言失败
function testErr() {
  return 1
}

function testDateTime() {
  dateTime
}

function testDarwin() {
  darwin
}

# ./sdk_test.sh testNext a b -y
# ./sdk_test.sh testNext -y a b
# ./sdk_test.sh testNext a -y b
# ./sdk_test.sh testNext -y
# ./sdk_test.sh testNext -Y
# ./sdk_test.sh testNext --y
# ./sdk_test.sh testNext -yz
# ./sdk_test.sh testNext -zy
#function testNext() {
#  # next
#}

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

# jsonParser "${jsonStr}" "code"
# jsonParser "${jsonStr}" "msg" "成功" | xargs
# jsonParser "${jsonStr}" "data"
# jsonParser "${jsonStr}" "id" 0
# jsonParser "${jsonStr}" "name" "unknown"
# jsonParser "${jsonStr}" "gender" "female"
function testJsonParser() {
  # 从文本读取
  jsonStr='{"code": 200, "msg": "ok", "data": {"id": 1001,"name": "Jackson"}}'
  [[ $(jsonParser "${jsonStr}" "code") == 200 ]] || return 1
  [[ $(jsonParser "${jsonStr}" "msg") == "ok" ]] || return 1
  [[ $(jsonParser "${jsonStr}" "data") != "" ]] || return 1
  [[ $(jsonParser "${jsonStr}" "id" 0) == 1001 ]] || return 1
  [[ $(jsonParser "${jsonStr}" "name" "unknown") == "Jackson" ]] || return 1
  [[ $(jsonParser "${jsonStr}" "gender" "female") == "female" ]] || return 1
  [[ $(jsonParser "${jsonStr}" "email") == "null" ]] || return 1

  # 从文件读取
  [[ $(jsonParser "./example.json" "code") == 200 ]] || return 1
  [[ $(jsonParser ./example.json "name" "unknown") == "  Linus   Torvalds    " ]] || return 1
}

# export TEST_VERBOSE=on
function testIniParser() {
  iniExample="
;INI文件由节、键、值组成。
[mysql]
host			 = 127.0.0.1
port			 = 3306
user			 = root
password	 = 123456
charset		 = "utf8"

[pgsql]
host			 = 127.0.0.1
port			 = 6379
user			 = postgres
password	 = 123456
"

  # 检查语法
  iniCheck ./example.ini && echo "Success" || return 1
  iniCheck "${iniExample}" && echo "Success" || return 1

  # 解析内容
  [[ $(iniParser ./example.ini mysql user) == "root" ]] || return 1
  [[ $(iniParser ./example.ini pgsql user) == "postgres" ]] || return 1
  [[ $(iniParser "${iniExample}" mysql port) == 3306 ]] || return 1
  [[ $(iniParser "${iniExample}" mysql charset) == utf8 ]] || return 1
  [[ $(iniParser "${iniExample}" pgsql port) == 6379 ]] || return 1
}

function testSysInfo() {
  sysInfo
}

function testIp4() {
  ip4
}

function testSysInspect() {
  sysInspect
}

function testNotfound() {
  notfound
}

# (自动化)单元测试
unitStart
