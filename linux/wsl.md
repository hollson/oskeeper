```shell
# 查看WSL版本
$ wsl --version
WSL 版本： 2.1.5.0
内核版本： 5.15.146.1-2
WSLg 版本： 1.0.60
MSRDC 版本： 1.2.5105
Direct3D 版本： 1.611.1-81528511
DXCore 版本： 10.0.25131.1002-220531-1700.rs-onecore-base2-hyp
Windows 版本： 10.0.19045.3570

$ wsl --list --online
以下是可安装的有效分发的列表。
使用 'wsl.exe --install <Distro>' 安装。
NAME                                   FRIENDLY NAME
Ubuntu                                 Ubuntu
Debian                                 Debian GNU/Linux
kali-linux                             Kali Linux Rolling
Ubuntu-18.04                           Ubuntu 18.04 LTS
Ubuntu-20.04                           Ubuntu 20.04 LTS
Ubuntu-22.04                           Ubuntu 22.04 LTS
Ubuntu-24.04                           Ubuntu 24.04 LTS
OracleLinux_7_9                        Oracle Linux 7.9
OracleLinux_8_7                        Oracle Linux 8.7
OracleLinux_9_1                        Oracle Linux 9.1
openSUSE-Leap-15.5                     openSUSE Leap 15.5
SUSE-Linux-Enterprise-Server-15-SP4    SUSE Linux Enterprise Server 15 SP4
SUSE-Linux-Enterprise-15-SP5           SUSE Linux Enterprise 15 SP5
openSUSE-Tumbleweed                    openSUSE Tumbleweed

# 列出当前已安装的SubLinux
$ wsl --list --verbose
  NAME                   STATE           VERSION
  Ubuntu                 Stopped         1
  docker-desktop         Running         2
  docker-desktop-data    Running         2
    
 # 设置默认的 WSL 发行版
 $ wsl --set-version Ubuntu-22.04 2


# 设置默认的 WSL 发行版
wsl --import ubt01 D:\wsl\ubt01 D:\soft\ubuntu-22.04.2-live-server-amd64.iso --version 2
wsl --import ubt02 D:\wsl\ubt02 D:\soft\ubuntu-22.04.2-live-server-amd64.iso --version 2
wsl --import ubt03 D:\wsl\ubt03 D:\soft\ubuntu-22.04.2-live-server-amd64.iso --version 2
wsl --install -d Ubuntu-22.04

# 注销SubLinux
$ wsl --unregister Ubuntu
```



