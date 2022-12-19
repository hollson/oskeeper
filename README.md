

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

## Others
**Unnit Test**
```shell
> $ ./sdk_test.sh 
✅  [UT]          [testLog]       成功
✅  [UT]          [testContain]   成功
✅  [UT]          [testCompare]   成功
✅  [UT]          [testOK]        成功
❌  [UT]          [testErr]       失败
❌  [NotFound]    [testNotfound]  函数或命令不存在
✅  [UT]          [testSum]       成功
```

