#import "templates/template.typ": project, title-page, contents-page, section-page, with-page-numbering, acias-table, kbd

#show: project

#title-page(
  title: [Back-end technical specifications/后端技术规范],
  version: [version 1.0],
  author: [ShongSheng],
  date: [November 2025],
)

#contents-page("Table of Contents/目录")

#show: with-page-numbering


= Server deployment architecture/服务器部署架构
#figure(
  image("templates/images/server_arch.png",alt: "center"),
  caption: [
    Server deployment architecture diagram/服务器部署架构图
  ],
)

#pagebreak()

= Git Usage Specifications/Git使用规范
== Branch Specifications/分支规范

- Master
Master branch, stores production environment code, protected (direct commits prohibited, only updated via merge requests).

主分支，存放生产环境代码，受保护（禁止直接提交，仅通过合并请求更新）。

- Dev
Dev branch, integrates completed features, serves as the source code for the test environment.

开发分支，集成已完成的功能，作为测试环境代码来源。


- Feature

Feature branch, naming format: feature/[requirement-ID]-xxx, created from the Dev branch, merged back to Dev upon completion.

功能分支，命名格式feature/[需求ID]-xxx，从 Dev 分支创建，完成后合并回 Dev。

- Hotfix

Hotfix branch, naming format: hotfix/[bug-ID]-xxx, created from Master, merged to both Master and Dev after fixing.

紧急修复分支，命名格式hotfix/[bugID]-xxx，从 Master 创建，修复后同时合并到 Master 和 Dev。


== Code Submission Specifications/代码提交规范
- feat: feat/新功能: 
```bash
git commit -m '[feat] Implement password recovery function for users'
git commit -m '[feat] 实现用户找回密码功能'
```


- fix:  Bug fix/修复Bug
```bash
git commit -m '[fix] Fix login page display issue on mobile devices'
git commit -m '[fix] 修复移动端登录页面显示问题'
```

- doc:  Documentation update/文档更新
```bash
git commit -m '[doc] Add API interface documentation'
git commit -m '[doc] 添加API接口文档说明'
```

- pref:  Performance optimization/性能优化
```bash
git commit -m '[pref] Optimize homepage loading speed (reduce request time by 30%)'
git commit -m '[pref] 优化首页加载速度（减少30%请求耗时）'
```


= Python Project Specifications/Python项目规范

== Python Version Selection/Python版本选择

- For projects with simple business logic and low performance requirements, use Python (version *3.8 - 3.10*).
- 对于业务单一，性能要求低的项目，使用Python开发，Python版本 *3.8 - 3.10*

== Python Interpreter/Python解释器

- Use PyPy interpreter in production environments for improved performance.
- 生产环境使用PyPy解释器，提高性能

== Python Application Packaging/Python应用打包

- Recommended tools: Pyinstaller/Nuitka
- 推荐使用：Pyinstaller/Nuitka

== Python Project/Virtual Environment Tool/Python项目/虚拟环境工具

- Use UV tool uniformly.
- 统一使用UV工具


== Project Coding Standards/项目编码标准

- Encoding(编码规则): utf-8

- Line endings(行尾序列): lf

= Project ISSUE Template/项目ISSUE模板


== Feature template/功能需求模版
```bash
Feature Nam : User Group Management
Overview : This feature allows administrators to manage user groups and assign 
permissions to control access to different parts of the system.
Requirements :
	  1.Admin can edit user groups.
	  2.Admin / Layer owner can assign layer permissions to user groups.
	  3.Layer permission: READ/WRITE
UI Design:
Implementation Proposal :
Timeline
Actual Implementation : 功能需求流程 (Development process)
```

== Issue report template/问题报告模板
```bash
Bug Name : Selected segment not highlighted on map
Overview :
    1. Type “RT Crawford St to Spore Flyer” in the search bar,
    2. Select “RT Crawford St to Spore Flyer” from drop-down list.
Expected result: The segement is highlighted on the map.
Actual result: The segement is not highlighted on the map.
Attachments :
```

= Quality Control/质量把控

== Unit Testing/单元测试
- Install pytest/安装pytest
```bash
pip install pytest
```
- Example Code/示例代码
```Python
# test_example.py
def add(a, b):
    return a + b

def test_add_positive_numbers():
    assert add(2, 3) == 5

def test_add_negative_numbers():
    assert add(-1, -1) == -2
```
- Run Tests/运行测试
```bash
pytest test_example.py -v
```


== Api Test(Mock)/API测试(Mock)
*postman/hoppscotch*

- Tools for designing, testing, and documenting APIs with mock servers. 
用于设计、测试和文档化 API 的工具，支持 Mock 服务。

- Support automated testing via collections and scripts (e.g., Postman's Tests tab).
通过集合（Collections）和脚本实现自动化测试（如 Postman 的 Tests 标签页）。

- Mock servers simulate API responses for frontend/backend parallel development. 
Mock 服务可模拟 API 响应，支持前后端并行开发。

== Automated Testing/自动化测试
- Pre-commit Hooks/预提交钩子
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0  # Specify the version to use
    hooks:
      - id: trailing-whitespace      # Trim trailing whitespace
      - id: end-of-file-fixer       # Ensure files end with a newline
      - id: check-yaml              # Validate YAML file syntax
      - id: check-added-large-files # Prevent committing large files

  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black                   # Python code formatting (Black)

  - repo: https://github.com/PyCQA/flake8
    rev: 6.0.0
    hooks:
      - id: flake8                 # Python static code analysis
```

comments&explanations/注释说明：
- trailing-whitespace
Trims redundant whitespace at the end of lines.

修剪行尾的多余空白字符（如空格、制表符）。

- end-of-file-fixer
Ensures files end with a single newline character (POSIX compliance).

确保文件以单个换行符结尾（符合 POSIX 标准）。

- check-yaml
Validates YAML files for syntax errors.

验证 YAML 文件的语法是否正确。

- check-added-large-files
Blocks accidental commits of large files (configurable size threshold).

阻止意外提交大文件（可配置文件大小阈值）。

- black
Enforces consistent Python code formatting (PEP 8 compliant).

强制统一 Python 代码格式（符合 PEP 8 规范）。

- flake8
Checks for style violations, programming errors, and complexity issues.

检查代码风格违规、编程错误和复杂度问题。

= Deployment Specifications/部署规范
== Environment Isolation/环境隔离
- Separate databases for development, testing, and production environments.
- 开发/测试/生产环境数据库分离

- Manage configurations using environment variables (e.g., DATABASE_URL).
- 使用环境变量管理配置（如DATABASE_URL）

== Containerization/容器化
- Optimize Docker image layering (base image + business layer).

- Docker镜像分层优化（基础镜像+业务层）

- Utilize multi-stage builds to reduce image size.

- 多阶段构建减少镜像体积

- Implement one-click deployment and rollback using docker-compose commands.

- 通过 docker-compose 命令实现一键部署和回滚

== CI/CD Pipeline / CI/CD流水线
- Trigger tests upon code submission.

- 代码提交触发测试

- Automatically deploy to the staging environment after tests pass.

- 测试通过后自动部署到预发布环境

- Deploy to the production environment after manual confirmation.

- 人工确认后部署生产环境

= Project Management Tools/项目管理工具

_English version：_
#acias-table(
  caption: [Tool List],
  ([Category], [Name], [Description]),
  
  [Product Design],
  [Axure],
  [Preferred, must be mastered by product managers/developers],
  [Product Design],
  [Penpot],
  [🚩 Backup/Function Exploration],
  [Development Management],
  [GitLab/YouTrack],
  [Milestones, requirements, tasks, development, code review, testing, CI/CD.],
  [Knowledge Base],
  [MinDoc/Obsidian],
  [Lightweight online documentation and knowledge base system; ],
  [File Sharing],
  [Cloudreve/Nextcloud],
  [Multi-storage protocol file sharing and management system],
  [Diagramming Tools],
  [Draw.io],
  [Full-featured diagramming tool (self-hostable or desktop version available)],
  [Diagramming Tools],
  [PlantUML],
  [Text-driven UML diagram tool],
  [AI Tools],
  [Qoder (Alibaba)],
  [Enterprise-grade AI-assisted programming tool],
  [Documentation Tools],
  [Typst],
  [Reference: #link("https://typst.app")[Typst Official Website]],
  [SDN Tools],
  [Tailscale],
  [Internal network communication],
  [Centralized Private Repository],
  [Sonatype],
  [Management of packages and mirrors,such as npm, Docker, PyPI],
  [Operating System],
  [rockylinux 8.9],
  [Production Environment System Standards],
)


_中文版：_
#acias-table(
  caption: [工具列表],
  ([类别], [名称], [说明]),
  [产品设计],
  [Axure],
  [首选，产品经理/研发须掌握],
  [产品设计],
  [Penpot],
  [🚩备用/功能发掘],
  [开发管理],
  [GitLab/YouTrack],
  [里程碑、需求、任务、开发、代码评审、测试、CICD。],
  [知识库],
  [MinDoc/Obsidian],
  [轻量型在线文档与知识库系统],
  [文件共享],
  [Cloudreve/nextcloud],
  [多存储协议文件共享管理系统],
  [图表绘制工具],
  [Draw.io],
  [全功能图表绘制工具（可自建部署或用桌面版）],
  [图表绘制工具],
  [PlantUML],
  [文本驱动UML图表工具],
  [AI 工具],
  [Qoder（阿里）],
  [企业级AI辅助编程工具],
  [文档工具],
  [Typst],
  [参考： #link("https://typst.app")[Typst官网]],
  [SDN工具],
  [tailscale],
  [内网通信],
  [集中私有库],
  [Sonatype],
  [管理npm、Docker、PyPI等软件包/镜像],
  [操作系统],
  [rockylinux 8.9],
  [生产环境系统标准],
)


