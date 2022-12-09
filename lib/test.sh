#!/bin/bash

f1() { :; }
f2() { :; }
f3() { :; }
f4() { :; }
function testFoo() { echo "hwllo world" ;}
testBar() { :; }
testbaz() { :; }

help() {
  typeset -F
#  typeset -F|awk '{print $3}'|grep test
#  typeset -f | awk '/ \(\) $/ && /^test/ {print $1}'
}

help