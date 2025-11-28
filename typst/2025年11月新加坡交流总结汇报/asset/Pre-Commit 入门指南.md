### Pre-Commit 入门指南

#### **一、Pre-Commit是什么？**

Pre-Commit是一个**Git预提交钩子管理框架**，用于在代码提交（`git commit`）前自动执行代码检查、格式化、静态分析等任务。其核心功能包括：

- **自动化代码质量检查**：如代码风格（flake8、black）、语法错误、安全漏洞等。
- **统一团队规范**：强制所有成员遵守相同的代码标准，减少人工审查成本。
- **拦截低级错误**：阻止未格式化、含调试语句或语法错误的提交，避免问题流入后续流程。



<br/>



#### **二、针对Python项目的Pre-Commit配置步骤**

##### **1. 安装Pre-Commit**

推荐使用`pip`全局安装（或通过`pipx`隔离环境）：

```bash
bashpip install pre-commit
# 或
pipx install pre-commit
```

验证安装：

```bash
pre-commit --version
```

##### **2. 初始化项目配置**

在项目根目录创建配置文件`.pre-commit-config.yaml`，示例如下：

```yaml
yamlrepos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0  # 使用稳定版本
    hooks:
      - id: trailing-whitespace  # 删除行尾空格
      - id: end-of-file-fixer  # 确保文件以换行符结尾
      - id: check-yaml  # 验证YAML语法
      - id: check-toml  # 验证TOML语法

  - repo: https://github.com/psf/black
    rev: 23.3.0  # Python代码格式化工具
    hooks:
      - id: black
        args: [--line-length=88]  # 设置每行最大长度

  - repo: https://github.com/PyCQA/isort
    rev: 5.12.0  # Python导入排序工具
    hooks:
      - id: isort

  - repo: https://github.com/PyCQA/flake8
    rev: 6.0.0  # Python代码风格检查工具
    hooks:
      - id: flake8
        args: [--max-line-length=88, --ignore=E501]  # 忽略行长错误（由black处理）
```

##### **3. 安装Git钩子**

在项目根目录运行以下命令，将Pre-Commit钩子安装到Git中：

```bash
pre-commit install
```

此操作会在`.git/hooks`目录下生成`pre-commit`脚本，确保每次提交时自动触发检查。

##### **4. 运行检查**

- 手动检查所有文件

  （适用于存量代码修复）：

  ```bash
  pre-commit run --all-files
  ```
  
- **自动检查暂存文件**（日常提交时自动触发）：
  直接执行`git commit`，若检查失败会阻止提交并提示错误。

##### **5. 跳过检查（谨慎使用）**

临时绕过Pre-Commit检查（例如紧急提交）：

```bash
git commit --no-verify -m "紧急修复"
```

但建议修复问题后重新提交，以保持代码质量。



<br/>



#### **三、公共模板与最佳实践**

##### **1. 官方模板库**

Pre-Commit官方提供了丰富的预置钩子库，可直接引用：

- **通用钩子**：
  [pre-commit/pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks)
  包含空格检查、文件结尾修正、YAML/TOML验证等基础工具。
- **Python专用钩子**：
  - **格式化**：[black](https://github.com/psf/black)、[autopep8](https://github.com/hhatto/autopep8)
  - **Linting**：[flake8](https://github.com/PyCQA/flake8)、[pylint](https://github.com/PyCQA/pylint)
  - **导入排序**：[isort](https://github.com/PyCQA/isort)
  - **类型检查**：[mypy](https://github.com/python/mypy)

##### **2. 多项目统一配置（团队级模板）**

通过**模板目录**功能，团队可共享同一套配置标准：

```bash
# 创建模板目录
mkdir ~/.git-templates
pre-commit init-templatedir ~/.git-templates

# 配置全局Git使用模板
git config --global init.templateDir ~/.git-templates

# 新项目初始化时自动应用模板
git init new-project
cd new-project  # 无需手动配置pre-commit
```

将模板目录纳入版本控制，确保配置变更可追踪。

##### **3. 进阶配置技巧**

- 按文件类型过滤：仅对特定文件运行钩子。

  ```yaml
  yamlhooks:
    - id: black
      types: [python]  # 仅处理Python文件
    - id: eslint
      files: \.(js|ts)$  # 正则匹配JS/TS文件
  ```
  
- 自定义钩子：支持本地脚本或私有仓库。

  ```yaml
  yamlrepos:
    - repo: local
      hooks:
        - id: custom-check
          name: "My Custom Script"
          entry: ./scripts/custom-check.sh  # 脚本路径
          language: system  # 直接执行系统命令
  ```



<br/>



#### **四、入门级教程总结**

1. **安装Pre-Commit**：通过`pip`或`pipx`全局安装。
2. **创建配置文件**：编写`.pre-commit-config.yaml`，引用官方钩子库或自定义规则。
3. **安装Git钩子**：运行`pre-commit install`，绑定到Git提交流程。
4. **运行检查**：通过`pre-commit run --all-files`修复存量代码，日常提交自动触发检查。
5. **团队协作**：使用模板目录统一配置标准，减少重复设置。