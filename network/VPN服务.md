[TOC]

# 一. V2Ray简介

[**v2ray**](https://v2fly.org/)是一个十分流行的网络工具，其功能强大，用途不限于突破防火墙。

**数据流向: ** : 
> {浏览器} <--(socks)--> `{V2Ray客户端inbound <-> V2Ray客户端outbound}` <--(VMess)--> ` {V2Ray服务器inbound <-> V2Ray服务器outbound}` <--(Freedom)--> {目标网站}

<br/>

# 二. V2ray安装
## 2.1 安装v2ray服务
>   可到Github下载[v2ray-core](https://github.com/v2fly/v2ray-core)Release版本，进行手动安装，或使用脚本进行一键安装：

```shell
$ bash <(curl -SL https://raw.githubusercontent.com/hijkpw/scripts/master/goV2.sh)
```
*解压包内容如下：*
```shell
├── config.json		#配置文件
├── geoip.dat		#IP数据
├── geosite.dat		#域名数据
├── systemd
│   └── system
│       ├── v2ray.service
│       └── v2ray@.service
├── v2ctl			#客户端工具
├── v2ray			#服务应用
├── vpoint_socks_vmess.json  
└── vpoint_vmess_freedom.json
```
## 2.2 命令行参数
> https://www.v2ray.com/chapter_00/command.html

<br/>

# 三. V2ray配置

## 3.1 配置格式

```json
{
  "log": {},
  "inbounds": [],
  "outbounds": [],
  "routing": {},
  "transport": {},
  "dns": {},
  "reverse": {},
  "policy": {},
  "stats": {},
  "api": {}
}
```

## 3.2 服务端配置

>   每个V2Ray都是一个节点，`inbound`对外开放一个服务，`outbound`表示对接外部流量的配置。 

```json
{
  "log": {
    "loglevel": "info",		// 错误级别：info｜error｜none
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log"
  },
  "inbounds": [
    {
      "port": 16823,        // 服务器监听端口
      "protocol": "vmess",  // VMess协议是V2Ray原创的加密传输协议
      "settings": {
        "clients": [
          {
            "id": "b8313...0811", // 用户UUID(可用v2ctl生成)，客户端与服务器须相同
            "alterId": 64		  // 防探测强度(建议)
          }
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom", // 主传出协议(直连)
      "settings": {}
    }
  ]
}
```
## 3.3 客户端配置

```json
{
  "inbounds": [
    {
      "port": 1080,         // 监听端口
      "protocol": "socks",  // 入口协议为SOCKS5
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      },
      "settings": {
        "auth": "noauth"	//noauth代表不认证(信任客户端)
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",              // 默认协议，加密访问
      "mux": {"enabled": true},  		//多路复用，即服务器会自动识别，将多条TCP报文合并发送
      "settings": {
        "vnext": [
          {
            "address": "serveraddr.com",// 服务器地址或IP
            "port": 16823,              // 服务器端口
            "users": [
              {
                "id": "b8313...0811",   // 用户ID(必与服务器端相同)
                "alterId": 64           // 与服务器配置相同
              }
            ]
          }
        ]
      }
    },
    {
      "protocol": "freedom", 
      "settings": {},
      "tag": "direct"       //直连模式 - 国内站点
    },
    {
      "protocol": "blackhole", 
      "settings": {},
      "tag": "adblock"       //广告 - 黑洞模式
    }
  ],

  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "domain": [
          "tanx.com",
          "googeadsserving.cn",
          "baidu.com"
        ],
        "type": "field",
        "outboundTag": "adblock"
      },
      {
        "domain": [
          "amazon.com",
          "microsoft.com",
          "jd.com",
          "youku.com",
          "baidu.com"
        ],
        "type": "field",
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": ["geosite:cn"]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:cn",
          "geoip:private"
        ]
      }
    ]
  }
}
```

<br/>

# 四. V2ray客户端

>   `v2ray-core是一个网络中转服务，既可以作为服务端，也可以作为客户端。此外，也可以安装第三方可视化客户端： 

## 4.1 第三方客户端
>   https://tlanyan.pp.ua/v2ray-clients-download/

## 4.2 浏览器插件
>    Chrome插件： `SwitchyOmega`

## 4.3 Curl代理
>   https://www.cnblogs.com/panxuejun/p/10574038.html



<br/>



# 五. VPS服务商
>   https://tlanyan.pp.ua/vps-merchant-collection/


<br/>

# 参考链接：
> https://www.v2ray.com/ 
> 
> https://tlanyan.me/v2ray-tutorial/
>
> https://guide.v2fly.org/
>
> https://tlanyan.pp.ua/v2ray-traffic-mask/ 
>
> https://toutyrater.github.io/



