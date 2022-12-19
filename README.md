

# System Operating Kit

![gdk](./favicon.svg?description=1&language=1&pattern=Floating%20Cogs&theme=Light)

<br/>

## Install
```shell
VERSION=v1.0.0
curl -Ssl -O https://github.com/hollson/oskeeper/releases/download/${VERSION}/sdk.sh && chmod +x ./sdk.sh
```

## Usage
```shell
> $ ./sdk.sh
=========================================================
         欢迎使用sdk(Shell Development Kit) v1.0.0
=========================================================
用法：
 sdk [command] <param>

Available Commands:
 命令   简写    说明
 arch      查看CPU架构
 echox     打印彩色字符
 dateTime  打印当前时间
 next      阻塞并确定是否继续
 sum       求两数之和
 contain   是否包含子串,如：contain src sub
 compare   比较大小
 help      帮助说明

更多详情，请参考 https://github.com/hollson
```

## Unit Test
**打印单元测试过程**
```shell
export TEST_VERBOSE=on
```
**查看单元测试函数列表**
```shell
> $ ./sdk_test.sh list
======== 单元测试函数列表 ========
testArch
testCompare
testContain
testDateTime
testEchox
testErr
testLog
testOK
testOS
testSum
```
**执行某个单元测试**
```shell
> $ ./sdk_test.sh testOK
✅  [UT]          [testOK]        成功
> $ ./sdk_test.sh testErr
❌  [UT]          [testErr]       失败
sybs@shs:lib$ 
```
**执行所有单元测试**
```shell
> $ ./sdk_test.sh 
✅  [UT]          [testArch]      成功
✅  [UT]          [testCompare]   成功
✅  [UT]          [testContain]   成功
✅  [UT]          [testDateTime]  成功
✅  [UT]          [testEchox]     成功
❌  [UT]          [testErr]       失败
✅  [UT]          [testLog]       成功
✅  [UT]          [testOK]        成功
✅  [UT]          [testOS]        成功
✅  [UT]          [testSum]       成功
```


## Others
