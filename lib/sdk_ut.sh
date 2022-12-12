#!/bin/bash


# 单元测试
# 加载单元测试: unittest "${@:1}"
# 126: 不可执行
# 127: 命令不存在
function unittest() {
  set +e
  if [ "$TEST_VERBOSE" == "on" ]; then
    $1
  else
    $1 &>/dev/null
  fi

  result=$?
  if [ $result -eq 127 ]; then
    echox error 1 "[NotFound] \t [$1]\t 函数或命令不存在"
    return
  fi
  if [ $result -ne 0 ]; then
    echox error 1 "[UT] \t [$1]\t 成功"
    return
  fi
  #  echo $result
#  echox success 1 "[UT] \t [$1]\t 失败"
}

# 单元测试列表
testList() {
  # typeset -F | awk '{print $3}' | grep "^test"
  # typeset -f | awk '/ \(\) $/ && /^test/ {print $1}'
  # 包含" test"且排除testList
  typeset -F | awk '/ test/ && !/testList/ {print $3}'
}