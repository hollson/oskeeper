# SonatypeNexus3实操文档指南

# 一、概要

Sonatype Nexus 3（Nexus 3）是开源仓库管理工具，用于集中管理PyPI、npm包及Docker镜像等，支持私有仓库、远程代理与聚合，实现统一管控与安全分发。



# 二、安装
**环境依赖：**

- 已安装Docker、Docker Compose；系统内存≥4G（生产建议8G\+）；

- Linux环境（CentOS 7\+/Ubuntu 20\.04\+）。

**1. 数据目录配置**

```bash
# 权限必设200:200
mkdir -p /data/nexus && chown -R 200:200 /data/nexus && chmod -R 755 /data/nexus
```

**2. 编写docker-compose.yml**

```bash
cat > /data/nexus/docker-compose.yml << EOF
version: '3'
services:
  nexus:
    image: sonatype/nexus3:3.70.1
    container_name: nexus3
    restart: always
    ports:
      - "8081:8081"   # Web UI端口
      - "8082:8082"   # Docker仓库端口
    environment:
      INSTALL4J_ADD_VM_PARAMS: >
        -Xms2G -Xmx4G -XX:MaxDirectMemorySize=2G -Djava.util.prefs.userRoot=/nexus-data/javaprefs
    volumes:
      - /data/nexus:/nexus-data
EOF
```
**3. 启动Nexus**

```bash
cd /data/nexus && docker-compose up -d && docker-compose logs -f # 日志出现"Started Sonatype Nexus OSS"即启动成功
```

**4. 初始化配置**

```bash
cat /data/nexus/admin.password # 查看初始管理员密码
# 浏览器访问http://<IP>:8081，使用admin+上述密码登录，立即修改密码（如Admin@123），关闭匿名访问（生产建议）
```

# 三、核心仓库

- hosted：私有仓库（本地上传包/镜像）

- proxy：代理远程仓库（缓存加速）

- group：聚合仓库（统一访问地址）



# 四、仓库配置实

## 4.1 PyPI仓库配置及使用

### （1）Web UI创建仓库（3个）

进入：设置→Repositories→Create repository

- pypi\-proxy（proxy）：Name=pypi\-proxy，Remote URL=https://mirrors\.aliyun\.com/pypi/simple/，默认创建

- pypi\-hosted（hosted）：Name=pypi\-hosted，Deployment policy=Allow redeploy，默认创建

- pypi\-group（group）：Name=pypi\-group，将pypi\-proxy、pypi\-hosted加入，默认创建

聚合地址：http://<IP>:8081/repository/pypi-group/simple

### （2）客户端配置及使用

```bash
# 配置pip源
mkdir -p ~/.pip && cat > ~/.pip/pip.conf << EOF
[global]
index-url = http://<IP>:8081/repository/pypi-group/simple
trusted-host = <IP>
EOF

# 测试安装公共包
pip install requests

# 上传私有包（先打包项目，再上传）
python setup.py bdist_wheel && pip install twine
twine upload --repository-url http://<IP>:8081/repository/pypi-hosted/ dist/*

# 安装私有包
pip install my-private-package
```

## 4.2 npm仓库配置及使用

### （1）Web UI创建仓库（3个）

- npm\-proxy（proxy）：Name=npm\-proxy，Remote URL=https://registry\.npmmirror\.com，默认创建

- npm\-hosted（hosted）：Name=npm\-hosted，默认创建

- npm\-group（group）：Name=npm\-group，将npm\-proxy、npm\-hosted加入，默认创建

聚合地址：http://\&lt;IP\&gt;:8081/repository/npm\-group/

### （2）客户端配置及使用

```bash
# 配置npm源
npm config set registry http://<IP>:8081/repository/npm-group/ && npm config get registry

# 登录私有仓库、发布私有包、安装包
npm login --registry=http://<IP>:8081/repository/npm-hosted/ # 输入admin+密码+任意邮箱
npm publish --registry=http://<IP>:8081/repository/npm-hosted/ # 项目目录执行
npm install my-private-npm-package
```

## 4.3 Docker仓库配置及使用

### （1）Web UI创建仓库（2个）

- docker\-proxy（proxy）：Name=docker\-proxy，Remote URL=https://hub\.docker\.com，Docker API Version=V2，默认创建

- docker\-hosted（hosted）：Name=docker\-hosted，可选勾选Allow anonymous pull，默认创建

### （2）客户端配置及使用

```bash
# 配置Docker insecure-registries（允许http访问）
cat > /etc/docker/daemon.json << EOF
{
  "insecure-registries": ["<IP>:8082"]
}
EOF
systemctl restart docker

# 登录、拉取公共镜像、推送/拉取私有镜像
docker login <IP>:8082 # 输入admin+密码
docker pull <IP>:8082/nginx # 代理拉取并缓存
docker tag my-app:1.0 <IP>:8082/my-app:1.0 # 给本地镜像打标签
docker push <IP>:8082/my-app:1.0 # 推送私有镜像
docker pull <IP>:8082/my-app:1.0 # 拉取私有镜像
```

# 五、常用问题解决

```bash
# 1. 启动失败（permission denied）
chown -R 200:200 /data/nexus

# 2. 忘记admin密码
docker exec -it nexus3 bash && cd /nexus-data && rm admin.password && exit
docker-compose restart nexus3 &amp;&amp; cat /data/nexus/admin.password # 重新获取密码
```

