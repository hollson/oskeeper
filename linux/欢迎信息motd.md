## 系统默认MOTD脚本
- 查看MOTD的守护进程脚本（按照从最低到最高数值的顺序执行）
```shell
$ ls -1  /etc/update-motd.d 
00-header
10-help-text
50-landscape-sysinfo
50-motd-news
85-fwupd
90-updates-available
91-contract-ua-esm-status
91-release-upgrade
92-unattended-upgrades
95-hwe-eol
97-overlayroot
98-fsck-at-reboot
98-reboot-required
```
- 单独执行某个脚本
```shell
$ bash /etc/update-motd.d/00-header
```
- 禁用默认`MOTD`脚本
```shell
$ sudo chmod -x /etc/update-motd.d/*
```



## 自定义MOTD脚本
- **创建自定义脚本：**

```shell
sudo vim /etc/update-motd.d/01-myHeader
```
```shell
#!/bin/sh

[ -r /etc/lsb-release ] && . /etc/lsb-release

if [ -z "$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=$(lsb_release -s -d)
fi

printf "欢迎进入2 %s (%s %s %s)\n" "$DISTRIB_DESCRIPTION" "$(uname -o)" "$(uname -r)" "$(uname -m)"

```
- **添加执行权限**
```shell
sudo chmod +x /etc/update-motd.d/01-myHeader
```

- 添加动态MOD内容

```shell
# 编辑motd,加入自定义内容
$ vim /etc/motd
Hello Linux
```

  

_再次进入服务器，可看到更改的内容_

