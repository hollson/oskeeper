# Grafana入门指南

**[Grafana](https://github.com/grafana/grafana) 是一款可视化数据仪表盘工具**，能对接Prometheus、Loki、Elasticsearch、InfluxDB、Postgres等数据源。



## 一. 安装Grafana

### 1.1 Windows安装Grafana

- 访问官网 [下载Grafana](https://grafana.com/grafana/download) 并安装，Grafana分**企业版**和**社区版(OSS)**，未激活的企业版等同于**OSS**版。 



### 1.2 Docker安装Grafana

**拉取镜像**

```shell
docker pull grafana/grafana-oss:latest
```

**简单安装**

```shell
docker run -d --name grafana \
  -p 3000:3000 \
  --restart=always \
  -v grafana-storage:/var/lib/grafana \
  grafana/grafana-oss:latest
```
**完整安装**

```shell
# 创建挂载目录
mkdir -p ${HOME}/.local/grafana/{data,config}

# Grafana 官方镜像默认使用ID为472的用户(grafana 用户)
sudo chown -R 472:472 ${HOME}/.local/grafana

# 完整安装
# GF_SECURITY_ADMIN_PASSWORD: 初始管理员密码
# GF_SERVER_ROOT_URL: 配置后能规避 Grafana 内部跳转、面板分享、告警链接失效的问题
docker run -d \
--name grafana \
--restart=always \
-p 3000:3000 \
-v ${HOME}/.local/grafana/data:/var/lib/grafana \
-e GF_SERVER_ROOT_URL="http://grafana.xxx.com" \
-e GF_SECURITY_ADMIN_PASSWORD="Pass@123" \
-e GF_TIMEZONE="Asia/Shanghai" \
grafana/grafana-oss:latest


docker run -d \
--name grafana \
--restart=always \
-p 8300:3000 \
-v ${HOME}/.local/grafana/data:/var/lib/grafana \
-e GF_SERVER_ROOT_URL="http://grafana.shundong.xyz" \
-e GF_SECURITY_ADMIN_PASSWORD="123456" \
-e GF_TIMEZONE="Asia/Shanghai" \
grafana/grafana-oss:latest
```











### 1.3 二进制安装Grafana

Grafana 官方提供了**[完整的独立二进制包](https://grafana.com/grafana/download?edition=oss&platform=mac)**，内部打包了运行所需的所有依赖 (包括前端资源、后端服务等）,任何前端依赖，一键安装即可运行。



### 1.4 验证安装

浏览器打开  http://localhost:3000 ，默认账号密码：`admin/admin`（首次登录强制修改密码）。

