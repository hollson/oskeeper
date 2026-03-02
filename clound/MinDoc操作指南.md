

## MinDoc实操指南
### 一、核心说明
[MinDoc](https://www.iminho.me/wiki/docs/mindoc/) 是轻量开源的文档管理系统，SQLite3 无需额外部署数据库，文件式存储，适合个人/小团队快速上手。

### 二、部署方式（二选一）
#### 方式1：Docker部署（推荐）
1. 新建目录并创建 `docker-compose.yml`
```yaml
version: '3'
services:
  mindoc:
    image: registry.cn-hangzhou.aliyuncs.com/mindoc/mindoc:latest
    container_name: mindoc
    restart: always
    ports:
      - "8185:8185"  # 端口可自定义，如9000:8185
    volumes:
      - ./mindoc_data:/mindoc/uploads  # 存储上传的图片/附件
      - ./mindoc_conf:/mindoc/conf    # 配置文件
      - ./mindoc_db:/mindoc/db        # SQLite3数据库文件
    environment:
      - MINDOC_RUN_MODE=prod
      - MINDOC_DB_ADAPTER=sqlite3     # 固定使用SQLite3
      - MINDOC_DB_NAME=./db/mindoc.db # 数据库文件路径
```
2. 启动命令
```bash
# 启动容器（后台运行）
docker-compose up -d
# 查看启动状态
docker-compose ps
```
3. 访问：`http://服务器IP:8185`，默认账号：`admin` / `123456`

#### 方式2：二进制部署
1. 下载对应系统版本（以Linux为例）
```bash
# 创建目录
mkdir -p /opt/mindoc && cd /opt/mindoc
# 下载（替换为最新版本号，可从GitHub获取）
wget https://github.com/mindoc-org/mindoc/releases/download/v2.16.0/mindoc_linux_amd64.zip
# 解压
unzip mindoc_linux_amd64.zip
chmod +x mindoc_linux_amd64
```
2. 初始化并启动
```bash
# 初始化SQLite3数据库
./mindoc_linux_amd64 install
# 启动服务（默认端口8185）
./mindoc_linux_amd64 start
```
3. 访问：`http://服务器IP:8185`，默认账号同上

### 三、核心操作
#### 1. 首次登录必做
- 登录后立即修改管理员密码：个人中心 → 修改密码
- 如需调整端口/基础配置：
  - Docker版：修改 `docker-compose.yml` 中 `ports` 后重启
  - 二进制版：编辑 `conf/app.conf`，修改 `httpport` 后重启

#### 2. 创建项目与文档
1. 首页 → 「新建项目」：填写名称，选择「私有/公开」，确认创建
2. 进入项目 → 「新建文档」：
   - 编辑器默认用Markdown，支持图片上传、代码块、表格
   - 编辑完成后点击「保存」，自动生成版本记录
3. 文档管理：左侧目录树可拖拽排序，右上角「历史」可恢复旧版本

#### 3. 权限管理（极简）
- 项目内添加成员：项目 → 「项目设置」→「成员管理」→ 添加用户并分配角色（编辑者/观察者）
- 私有项目分享：生成访问Token，仅授权用户可查看

### 四、维护与备份
#### 1. 数据备份
- Docker版：备份 `./mindoc_data`（附件）、`./mindoc_db`（数据库）目录
- 二进制版：备份 `uploads`（附件）、`db/mindoc.db`（数据库文件）
#### 2. 重启/停止
- Docker版：
  ```bash
  docker-compose restart  # 重启
  docker-compose down     # 停止
  ```
- 二进制版：
  ```bash
  ./mindoc_linux_amd64 restart  # 重启
  ./mindoc_linux_amd64 stop     # 停止
  ```
#### 3. 密码重置（忘记密码时）
- Docker版：
  ```bash
  docker exec -it mindoc ./mindoc password --username=admin --password=新密码
  ```
- 二进制版：
  ```bash
  ./mindoc_linux_amd64 password --username=admin --password=新密码
  ```







## 参考资料

官方文档：https://www.iminho.me/wiki/docs/mindoc/

GitHub：https://github.com/mindoc-org/mindoc

演示站：https://demo.mindoc.cn