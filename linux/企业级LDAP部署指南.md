



# 企业级 LDAP 统一身份认证平台部署指南

企业级LDAP部署指南企业级LDAP部署指南企业级LDAP部署指南

------

## 1. 环境预检与准备

### 1.1 服务器要求

- **OS**：CentOS 7/8, Ubuntu 20.04+, Rocky Linux
- **配置**：2C4G minimum (生产建议 4C8G)
- **软件**：Docker 20.10+, Docker Compose 2.0+

### 1.2 端口规划 (防火墙/安全组必须放行)

| 服务              | 端口 | 用途             |
| :---------------- | :--- | :--------------- |
| OpenLDAP          | 389  | LDAP 协议        |
| OpenLDAP          | 636  | LDAPS (加密)     |
| Go-LDAP-Admin API | 8888 | 后端接口         |
| Go-LDAP-Admin Web | 8090 | 管理后台         |
| MySQL             | 3307 | 避免与宿主机冲突 |

### 1.3 目录结构初始化

```bash
bash


mkdir -p /opt/ldap-stack/{config,data/mysql,data/openldap,data/backup,certs}
cd /opt/ldap-stack
chmod 755 -R data/  # 确保 Docker 有写权限
```

------

## 2. Docker Compose 一键部署

### 2.1 编写 `docker-compose.yml`

**注意**：请务必修改 `LDAP_DOMAIN`, `LDAP_ADMIN_PASSWORD`, `MYSQL_ROOT_PASSWORD`。

```yaml
yaml


version: '3.8'

networks:
  ldap-net:
    driver: bridge

services:
  # --- MySQL (元数据存储) ---
  mysql:
    image: mysql:5.7
    container_name: ldap-mysql
    restart: always
    environment:
      TZ: Asia/Shanghai
      MYSQL_ROOT_PASSWORD: "Root@Pass2026"  # 【修改】生产环境强密码
      MYSQL_DATABASE: go_ldap_admin
      MYSQL_ROOT_HOST: "%"
    volumes:
      - ./data/mysql:/var/lib/mysql
      - ./config/my.cnf:/etc/mysql/my.cnf
    networks:
      - ldap-net
    ports:
      - "3307:3306"

  # --- OpenLDAP (核心目录服务) ---
  openldap:
    image: osixia/openldap:1.5.0
    container_name: ldap-server
    restart: always
    environment:
      TZ: Asia/Shanghai
      LDAP_ORGANISATION: "MyCorp"
      LDAP_DOMAIN: "mycorp.com"          # 【修改】你的企业域名
      LDAP_ADMIN_PASSWORD: "Ldap@Admin2026" # 【修改】管理员密码
      LDAP_CONFIG_PASSWORD: "Config@2026"
      LDAP_READONLY_USER: "false"
    volumes:
      - ./data/openldap/database:/var/lib/ldap
      - ./data/openldap/config:/etc/ldap/slapd.d
      - ./config/init.ldif:/container/service/slapd/assets/config/bootstrap/ldif/custom/init.ldif
      # 生产环境挂载证书
      # - ./certs/ldap.crt:/container/service/slapd/assets/certs/ldap.crt
      # - ./certs/ldap.key:/container/service/slapd/assets/certs/ldap.key
    ports:
      - "389:389"
      - "636:636"
    command: ['--copy-service', '--loglevel=256']
    networks:
      - ldap-net

  # --- Go-LDAP-Admin 后端 ---
  go-ldap-admin-server:
    image: eryajf/go-ldap-admin-server:latest
    container_name: ldap-admin-server
    restart: always
    environment:
      TZ: Asia/Shanghai
      WAIT_HOSTS: mysql:3306, openldap:389
      DB_DRIVER: mysql
      DB_HOST: mysql
      DB_PORT: 3306
      DB_USER: root
      DB_PASS: "Root@Pass2026"  # 需与 MySQL 一致
      DB_NAME: go_ldap_admin
      LDAP_URL: ldap://openldap:389
      LDAP_BASE_DN: "dc=mycorp,dc=com"  # 需与 LDAP_DOMAIN 对应
      LDAP_ADMIN_DN: "cn=admin,dc=mycorp,dc=com"
      LDAP_ADMIN_PASS: "Ldap@Admin2026" # 需与 OpenLDAP 一致
      JWT_SECRET: "ChangeThisSecretKey" # 【修改】JWT 密钥
    ports:
      - "8888:8888"
    depends_on:
      - mysql
      - openldap
    networks:
      - ldap-net

  # --- Go-LDAP-Admin 前端 ---
  go-ldap-admin-ui:
    image: eryajf/go-ldap-admin-ui:latest
    container_name: ldap-admin-ui
    restart: always
    ports:
      - "8090:80"
    depends_on:
      - go-ldap-admin-server
    networks:
      - ldap-net
```

### 2.2 启动服务

```bash
bash


# 拉取镜像并启动
docker-compose up -d

# 查看日志 (排错用)
docker-compose logs -f openldap
docker-compose logs -f go-ldap-admin-server
```

------

## 3. 核心配置与初始化

### 3.1 初始化组织架构 (LDIF)

创建 `./config/init.ldif`，定义基础 OU（如果不创建，系统将为空）：

```ldif
ldif


# 部门结构
dn: ou=People,dc=mycorp,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=mycorp,dc=com
objectClass: organizationalUnit
ou: Group

dn: ou=Device,dc=mycorp,dc=com
objectClass: organizationalUnit
ou: Device
```

*重启 OpenLDAP 容器使其生效：`docker restart ldap-server`*

### 3.2 登录 Web 后台

1. 访问：`http://<服务器IP>:8090`
2. 默认账号：`admin` / `123456` (首次登录强制改密)
3. **关键步骤**：进入 **系统配置 -> LDAP 连接**，点击“测试连接”。
    - 如果报错 `Invalid Credentials`，检查 `docker-compose.yml` 中的 `LDAP_ADMIN_PASS`。
    - 如果报错 `Connection Refused`，检查网络 `ldap-net` 是否通。

### 3.3 手动创建第一个用户 (实操)

为了测试，先手动创建一个用户：

1. 进入 **用户管理** -> **新建用户**。
2. 填写信息：
    - **DN**: `uid=zhangsan,ou=People,dc=mycorp,dc=com` (必须唯一)
    - **UID**: `zhangsan`
    - **CN**: `张三`
    - **SN**: `张`
    - **Password**: `Test@123456`
3. 点击保存。

------

## 4. 验证服务可用性

### 4.1 使用 ldapsearch 命令行验证

在宿主机安装客户端：`yum install openldap-clients -y`

```bash
bash


ldapsearch -x \
  -H ldap://localhost:389 \
  -D "cn=admin,dc=mycorp,dc=com" \
  -w "Ldap@Admin2026" \
  -b "dc=mycorp,dc=com" \
  "(objectClass=*)"
```

**预期输出**：能看到 `dn: dc=mycorp,dc=com` 及刚创建的用户条目。

### 4.2 使用 Apache Directory Studio (GUI工具)

- 下载 Apache Directory Studio。
- 新建连接：
    - Hostname: `localhost`
    - Port: `389`
    - Base DN: `dc=mycorp,dc=com`
    - Authentication: Simple
    - Bind DN: `cn=admin,dc=mycorp,dc=com`
    - Bind Password: `Ldap@Admin2026`
- 连接成功即可可视化操作。

------

## 5. 高级实操：IM 同步 (以钉钉/飞书为例)

Go-LDAP-Admin 的核心价值在于自动化同步。

1. **获取 IM 密钥**：
    - 钉钉/企微/飞书开放平台 -> 创建企业内部应用 -> 获取 `AppKey` 和 `AppSecret`。
    - 配置回调地址（如有）：`http://<IP>:8888/api/v1/callback/dingtalk` (需公网可达)。
2. **配置 Web 后台**：
    - 进入 **IM 集成** -> **钉钉/飞书配置**。
    - 填入 Key/Secret。
    - **字段映射** (重要)：
        - `dingtalk_userid` -> `uid`
        - `name` -> `cn`
        - `mobile` -> `telephoneNumber`
        - `dept_id` -> `ou` (需提前在 LDAP 创建好部门 OU)
3. **执行同步**：
    - 点击 **手动同步** -> **同步部门** (先同步架构，再同步人)。
    - 查看日志确认无报错。

------

## 6. 运维干货：备份与恢复

**数据无价，必须备份！**

### 6.1 自动化备份脚本

创建 `backup.sh`：

```bash
bash


#!/bin/bash
BACKUP_DIR="/opt/ldap-stack/data/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 1. 备份 MySQL (Go-LDAP-Admin 数据)
docker exec ldap-mysql mysqldump -u root -p"Root@Pass2026" go_ldap_admin > $BACKUP_DIR/mysql_$DATE.sql

# 2. 备份 OpenLDAP (全量导出)
docker exec ldap-server slapcat -l /tmp/ldap_backup.ldif
docker cp ldap-server:/tmp/ldap_backup.ldif $BACKUP_DIR/ldap_$DATE.ldif

# 3. 清理 7 天前备份
find $BACKUP_DIR -type f -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -type f -name "*.ldif" -mtime +7 -delete

echo "Backup completed: $DATE"
```

- 添加定时任务：`crontab -e` -> `0 2 * * * /bin/bash /opt/ldap-stack/backup.sh`

### 6.2 灾难恢复流程

1. **恢复 MySQL**：

    ```bash
    bash
    
    
    cat backup/mysql_20260228.sql | docker exec -i ldap-mysql mysql -u root -p"Root@Pass2026" go_ldap_admin
    ```

2. **恢复 LDAP** (危险操作，先停服务)：

    ```bash
    bash
    
    
    docker-compose stop openldap
    # 清空旧数据 (警告！)
    rm -rf /opt/ldap-stack/data/openldap/database/*
    # 导入数据
    docker exec -i ldap-server slapadd -l /opt/ldap-stack/data/backup/ldap_20260228.ldif
    docker-compose start openldap
    ```

------

## 7. 常见故障排查 (Troubleshooting)

| 现象                      | 可能原因                 | 解决方案                                                     |
| :------------------------ | :----------------------- | :----------------------------------------------------------- |
| **Web 无法连接 LDAP**     | 网络不通 / 密码错误      | `docker exec` 进入 go-ldap-admin-server 容器，`ping openldap`。检查环境变量 `LDAP_ADMIN_PASS`。 |
| **OpenLDAP 容器反复重启** | 权限不足 / 端口冲突      | `chown -R 1000:1000 ./data/openldap`。检查宿主机 389 端口是否被占用 `netstat -tulnp | grep 389`。 |
| **同步用户失败**          | 字段映射错误 / OU 不存在 | 检查 IM 返回的 `dept_id` 是否在 LDAP 中有对应的 `ou`。开启 Go-LDAP-Admin 的 Debug 日志。 |
| **修改配置不生效**        | 缓存未清理               | Go-LDAP-Admin 部分配置需重启后端容器生效：`docker restart ldap-admin-server`。 |

------

## 8. 生产环境加固建议

1. **启用 LDAPS (TLS)**：
    - 申请 SSL 证书，放入 `./certs/`。
    - 修改 `docker-compose.yml` 挂载证书，并设置环境变量 `LDAP_TLS=true`。
    - 将 Go-LDAP-Admin 的 `LDAP_URL` 改为 `ldaps://openldap:636`。
2. **密码策略**：
    - 在 OpenLDAP 中配置 PPolicy (密码复杂度、过期时间)。
    - 需挂载 `ppolicy.ldif` 到初始化目录。
3. **只读副本**：
    - 若用户量 > 5万，建议搭建 OpenLDAP Syncrepl 集群，Go-LDAP-Admin 指向 VIP 或从节点读。
4. **防火墙限制**：
    - 389/636 端口仅对内网应用服务器开放，禁止公网直接访问。

------

**部署完成**。现在你可以将 Jenkins、GitLab、Grafana 等应用的认证源指向 `ldap://<IP>:389`，实现统一登录。