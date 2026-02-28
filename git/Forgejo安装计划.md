# Forgejo安装计划

## 系统信息
- 系统：ubunru 22.4
- 用户：shundong
- IP：192.168.1.10

## Forgejo安装信息
- 版本：14.0.2
- 数据库：slqite3
- web端口:18080
- ssh端口:10022
- 管理员账号：admin
- 管理员密码：123456
- 公司/团队主体：shundong
- 安装路径：/usr/local/bin/forgejo
- 工作目录（数据、配置、日志等）：~/.local/forgejo
- Nginx域名：hub.shundong.xyz

## Forgejo安装要求

- 使用docker或二进制安装（最求简单快捷、对系统侵入性小，可随手安装或卸载）

- 不使用systemd 
- 为了方便操作，无需创建forgejo独立用户和用户组
- 系统已安装了git，ssh，wget、nc等，无需重复安装