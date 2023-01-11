# System Operating Kit

![gdk](./favicon.svg?description=1&language=1&pattern=Floating%20Cogs&theme=Light)

<br/>

## Feature
- 支持Command帮助命令
- 可快速查看函数库列表
- 丰富的单元测试用例
- 支持一键执行所有测试用例

<br/>

## Download
```shell
wget https://github.com/hollson/oskeeper/releases/download/latest/sdk.tar.gz
```

<br/>

## Usage
**查看SDK帮助信息：**
```shell
> ./sdk.sh
=========================================================
     欢迎使用SDK(Shell Development Kit) v1.0.0                                                                                                                                                                       
=========================================================                                                                                                                                                            
用法：
 sdk.sh [command] <params>

Available Commands:
 命令   说明
 create   创建应用/测试脚本, 格式: ./sdk.sh create <app｜test>
 list     查看函数列表, 格式: ./sdk.sh list [category]
 exec     执行某个函数(部分支持), 如: ./sdk.sh exec arch
 docs     查看帮助文档列表, 格式: ./sdk.sh docs
 man      查看帮助文档内容, 格式: ./sdk.sh man <command>
 logf     监视当前日志
 version  查看sdk版本
 help     查看帮助说明

更多详情，请参考 https://github.com/hollson
```
**查看SDK函数库列表：**
```shell
> ./sdk.sh list
 函数      |    说明
-----------|------------
 arch        查看CPU架构
 compare     比较两个数值的大小
 contain     是否包含子串,格式：contain <src> <sub>
 dateTime    打印当前时间
 echox       打印彩色字符内容
 gateWay     获取默认网关
 has         集合是否包含某个元素
 iniCheck    检查ini文件语法
 iniParser   解析ini配置文件
 installer   查看当前系统的安装器
 jsonParser  解析json文件
 log         打印日志
 logInfo     打印提示信息
 logWarn     打印警告提醒
 logWarn     打印一般错误
 logWarn     打印致命错误
 next        阻塞并确定是否继续
 osRelease   查看系统(厂商)发行信息
 sysInfo     查看系统(静态)信息
 sysInspect  系统诊断(动态)信息
 virtualize  检查当前系统是否为虚拟化环境

  执行某个函数(部分支持), 如: ./sdk.sh exec arch
```

<br/>

## Unit Test
**查看UT帮助信息：**
```shell
> ./sdk_test.sh 
=== 🧪🧪🧪 执行单元测试 🧪🧪🧪===
命令格式: 
    ./sdk_test.sh <list|all|testXXX> [OPTIONS]

Options: 
    -v,--verbose  打印详细信息

示例：
1) 单元测试列表:   ./sdk_test.sh list 
2) 执行具体函数:   ./sdk_test.sh testXXX 
3) 执行全部测试:   ./sdk_test.sh all 

设置verbose系统变量: export TEST_VERBOSE=on
```
**查看UT函数列表：**
```shell
> ./sdk_test.sh list
=== 🧪🧪🧪 单元测试列表 🧪🧪🧪===
testArch
testCompare
testContain
testDarwin
testDateTime
testEchox
testErr
testHas
testIniParser
testJsonParser
testLog
testNotfound
testOK
testSysInfo
testSysInspect
```
**执行某个UT:**
```shell
> ./sdk_test.sh testOK -v
🔔 [2023-01-10 19:23:48] [info] test ok
[UT]            ✅               testOK                          成功
```
**执行所有UT:**
```shell
> $ ./sdk_test.sh all
[UT]            ✅               testArch                        成功
[UT]            ✅               testCompare                     成功
[UT]            ✅               testContain                     成功
[UT]            ❌               testDarwin                      失败
[UT]            ✅               testDateTime                    成功
[UT]            ✅               testEchox                       成功
[UT]            ❌               testErr                         失败
[UT]            ✅               testHas                         成功
[UT]            ✅               testIniParser                   成功
[UT]            ✅               testJsonParser                  成功
[UT]            ✅               testLog                         成功
[UT]            ⛔               testNotfound                    函数/命令不存在
[UT]            ✅               testOK                          成功
[UT]            ✅               testSysInfo                     成功
[UT]            ✅               testSysInspect                  成功
```
<br/>

## Example
```shell
./example.sh 
=========================================================
     欢迎使用Example Project v2.0.0                                                                                                                                                                                  
=========================================================                                                                                                                                                            
用法：
 example.sh [command] <params>

Available Commands:
 命令   说明
 build   编译项目
 run     运行项目
 status  查看服务状态

更多详情，请参考 https://github.com/hollson
```