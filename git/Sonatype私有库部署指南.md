# Sonatype Nexus 实操指南
## 一、核心定义
[Sonatype Nexus Repository Manager（Nexus）](https://github.com/sonatype/nexus-public)是企业级私有制品仓库，可统一管理 Docker、PyPI（Python）、Maven 等各类软件构件，核心价值是缓存公网资源、托管私有制品、管控软件供应链安全。

**适用场景**

- 搭建企业内部 Maven/npm/Docker 私有仓库
- 缓存公网依赖，加速构建、节省带宽
- 托管内部二方包、私有镜像
- 统一权限、审计、版本管控



---

## 二、环境准备（前置条件）
| 环境项         | 最低要求                | 生产建议                |
|----------------|-------------------------|-------------------------|
| JDK            | 11+                     | 11 LTS                  |
| 内存           | 2GB                     | 4GB+                    |
| 端口           | 8081（Web）、5000（Docker） | 8081、5000（独占）|
| 部署方式       | Docker（推荐）| Docker Compose          |
| 数据目录       | /opt/nexus-data         | 挂载独立磁盘            |

### 基础部署（Docker 一键启动）
```bash
# 1. 创建数据目录并授权（避免权限问题）
mkdir -p /opt/nexus-data && chmod 777 /opt/nexus-data

# 2. 启动 Nexus 容器（映射 Docker 端口 5000）
docker run -d \
  --name nexus3 \
  -p 8081:8081 \
  -p 5000:5000 \
  -v /opt/nexus-data:/nexus-data \
  --restart=always \
  sonatype/nexus3:latest

# 3. 获取初始密码（首次登录用）
docker exec nexus3 cat /nexus-data/admin.password
```

### 首次登录配置
1. 访问 Web 控制台：`http://服务器IP:8081`
2. 使用账号 `admin` + 上述初始密码登录
3. 按提示修改密码（务必记录，生产环境需符合密码规范）
4. 关闭“匿名访问”（生产必做）：Settings → Security → Anonymous Access → 禁用

---

## 三、Docker 私有镜像库搭建（实操步骤）
### 1. 创建 Docker 仓库
1. 进入控制台：Repository → Repositories → Create repository
2. 选择仓库类型：`docker (hosted)`（托管私有镜像）
3. 配置核心参数：
   - Name：`docker-private`（自定义，建议规范命名）
   - HTTP：勾选并填写端口 `5000`（需与容器映射端口一致）
   - Enable Docker V1 API：按需勾选（兼容旧版本）
   - Deployment policy：`Allow redeploy`（允许覆盖镜像，测试环境用；生产建议 `Disable redeploy`）
4. 点击 `Create repository` 完成创建

### 2. 配置 Docker 客户端连接私有库
#### 方式 1：配置 insecure-registries（测试环境）
```bash
# 编辑 Docker 配置文件
vi /etc/docker/daemon.json

# 添加以下内容（替换为 Nexus 服务器 IP）
{
  "insecure-registries": ["http://服务器IP:5000"]
}

# 重启 Docker 服务
systemctl daemon-reload
systemctl restart docker
```

#### 方式 2：配置 HTTPS（生产环境，略）
> 生产环境需配置 SSL 证书，避免明文传输，步骤可参考 Nexus 官方文档。

### 3. Docker 镜像推送/拉取实操
```bash
# 1. 登录私有库
docker login 服务器IP:5000
# 输入 Nexus 的 admin 账号/密码（生产建议创建专用 Docker 账号）

# 2. 标记本地镜像（需符合私有库命名规范）
docker tag 本地镜像名:版本 服务器IP:5000/自定义镜像名:版本
# 示例：docker tag nginx:latest 192.168.1.100:5000/my-nginx:v1

# 3. 推送镜像到私有库
docker push 服务器IP:5000/自定义镜像名:版本

# 4. 拉取私有库镜像
docker pull 服务器IP:5000/自定义镜像名:版本

# 5. 退出登录（可选）
docker logout 服务器IP:5000
```

### 4. Docker 代理仓库（缓存公网镜像，可选）
如需缓存 Docker Hub 镜像，创建 `docker (proxy)` 类型仓库：
- Remote storage：`https://registry-1.docker.io`
- 其余配置参考上述托管仓库，最后可创建 `docker (group)` 合并私有库和代理库，统一访问入口。

---

## 四、Python PyPI 私有库搭建（实操步骤）
### 1. 创建 PyPI 仓库
#### ① 创建托管仓库（存储私有 Python 包）
1. 进入控制台：Repository → Repositories → Create repository
2. 选择仓库类型：`pypi (hosted)`
3. 配置核心参数：
   - Name：`pypi-hosted`
   - Deployment policy：`Allow redeploy`（测试环境）/ `Disable redeploy`（生产）
4. 点击 `Create repository`

#### ② 创建代理仓库（缓存 PyPI 官方包）
1. 选择仓库类型：`pypi (proxy)`
2. 配置核心参数：
   - Name：`pypi-proxy`
   - Remote storage：`https://pypi.org/simple/`（或国内源 `https://pypi.tuna.tsinghua.edu.cn/simple/`）
3. 点击 `Create repository`

#### ③ 创建仓库组（统一访问入口）
1. 选择仓库类型：`pypi (group)`
2. 配置核心参数：
   - Name：`pypi-group`
   - Member repositories：添加上述 `pypi-hosted` 和 `pypi-proxy`
3. 点击 `Create repository`
4. 记录仓库组 URL：`http://服务器IP:8081/repository/pypi-group/simple/`

### 2. Python 客户端配置（使用私有 PyPI 库）
#### 方式 1：临时使用（命令行指定）
```bash
# 安装包（从私有库拉取）
pip install 包名 -i http://服务器IP:8081/repository/pypi-group/simple/ --trusted-host 服务器IP

# 上传包（推送到私有库）
# 先安装 twine：pip install twine
twine upload --repository-url http://服务器IP:8081/repository/pypi-hosted/ 包文件路径
# 输入 Nexus 的 admin 账号/密码
```

#### 方式 2：全局配置（永久生效）
```bash
# 编辑 pip 配置文件
vi ~/.pip/pip.conf

# 添加以下内容（替换为服务器 IP）
[global]
index-url = http://服务器IP:8081/repository/pypi-group/simple/
trusted-host = 服务器IP

[upload]
repository = http://服务器IP:8081/repository/pypi-hosted/
```

### 3. 验证 PyPI 私有库
```bash
# 1. 从私有库安装测试包（如 requests）
pip install requests

# 2. 上传自定义 Python 包（示例）
# 先打包自定义包：python setup.py sdist bdist_wheel
# 再上传：twine upload dist/*
```

---

## 五、日常维护命令
```bash
# 启动/停止/重启 Nexus
docker start nexus3
docker stop nexus3
docker restart nexus3

# 查看 Nexus 日志（排查问题）
docker logs -f nexus3

# 备份 Nexus 数据（核心）
cp -r /opt/nexus-data /opt/nexus-data-backup-$(date +%Y%m%d)
```

---

## 六、安全规范配置
1. **账号权限**：创建专用账号（如 docker-deploy、pypi-deploy），仅授予对应仓库的部署/读取权限，避免使用 admin 账号日常操作。
2. **密码策略**：Settings → Security → Password Policy，配置密码复杂度（长度≥8、含大小写/数字/特殊字符）。
3. **访问控制**：禁用匿名访问，仅允许内网 IP 访问 Nexus 端口（8081/5000）。
4. **数据备份**：定期备份 `/opt/nexus-data` 目录，建议每日备份，保留 7 天历史版本。

---

## 总结
1. Nexus 可快速搭建 Docker 私有镜像库（核心是创建 `docker (hosted)` 仓库并映射 5000 端口，客户端需配置 insecure-registries）和 Python PyPI 私有库（核心是创建 `pypi (hosted/proxy/group)` 三类仓库，客户端通过 pip 配置指定私有库地址）。
2. 部署时优先使用 Docker 方式，需注意数据目录权限和端口映射，生产环境必须禁用匿名访问、配置强密码策略并定期备份数据。
3. Docker 镜像推送/拉取需先登录私有库，PyPI 包上传推荐使用 twine 工具，避免直接用 pip upload（安全性低）。