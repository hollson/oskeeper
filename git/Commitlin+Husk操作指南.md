# Commitlint + Husky 标准化配置指南（可直接落地）
这份指南以 **Node.js 项目** 为例，提供从环境准备到验证测试的全流程标准化操作，确保提交信息规范能被严格执行，步骤清晰、可复制性强。

## 一、前置条件
1. 项目已初始化 Git（执行过 `git init`）
2. 项目已初始化 npm/yarn/pnpm（执行过 `npm init -y`）
3. 本地安装 Node.js（v14+ 即可，推荐 LTS 版本）

## 二、核心目标
通过配置实现：
- 执行 `git commit` 时自动校验提交信息格式
- 仅允许符合规范的提交信息（如 `feat: 新增用户列表`）
- 不符合规范的提交直接终止，强制团队提交信息统一

## 三、分步操作（全程在项目根目录执行）

### 步骤 1：安装核心依赖
根据包管理器选择对应命令，推荐使用 npm：
```bash
# npm 安装（推荐）
npm install --save-dev @commitlint/cli @commitlint/config-conventional husky

# yarn 安装
yarn add @commitlint/cli @commitlint/config-conventional husky --dev

# pnpm 安装
pnpm add -D @commitlint/cli @commitlint/config-conventional husky
```

### 步骤 2：初始化 Husky 钩子环境
Husky 是 Git 钩子管理工具，需先启用：
```bash
# 初始化 husky，生成 .husky 目录（关键）
npx husky install

# 配置 npm prepare 脚本（可选但强烈推荐）
# 作用：其他开发者安装依赖后自动启用 husky，无需手动执行 install
npm set-script prepare "husky install"
```
执行后检查项目根目录，会生成 `.husky` 文件夹，代表初始化成功。

### 步骤 3：创建 Commitlint 配置文件
在项目根目录新建 `.commitlintrc.js` 文件，粘贴以下标准化配置（包含你提供的规则，补充了常用约束）：
```javascript
module.exports = {
  // 继承官方规范（基础规则）
  extends: ["@commitlint/config-conventional"],
  // 自定义规则（优先级高于继承的规则）
  rules: {
    // 提交类型枚举（必选，错误级别2=终止提交）
    "type-enum": [
      2,
      "always",
      [
        "feat",     // 新功能（如：新增支付接口）
        "fix",      // Bug修复（如：修复登录态失效问题）
        "docs",     // 文档变更（如：更新README、注释）
        "style",    // 代码格式（如：缩进、空格，无逻辑变更）
        "refactor", // 代码重构（无新功能/无Bug修复）
        "perf",     // 性能优化（如：减少接口请求次数）
        "test",     // 测试相关（如：新增单元测试、补全测试用例）
        "chore",    // 构建/工具变动（如：修改webpack配置、依赖版本）
        "revert",   // 回滚提交（如：revert: feat: 新增支付接口）
        "build",    // 构建相关（如：打包脚本、编译配置）
        "ci"        // CI配置（如：GitHub Actions、Jenkinsfile修改）
      ],
    ],
    // 提交类型不能为空（必选）
    "type-empty": [2, "never"],
    // 提交描述（subject）不能为空（必选）
    "subject-empty": [2, "never"],
    // 提交描述（subject）禁用大小写（如：禁止 "Feat: 新增xx"）
    "subject-case": [2, "always", "lower-case"],
    // 提交描述（subject）结尾禁用句号
    "subject-full-stop": [2, "never", "."],
    // 提交体（body）换行符规范（遵循conventional规范）
    "body-leading-blank": [1, "always"],
    // 回滚提交必须有说明
    "revert-message": [2, "always"]
  },
};
```

### 步骤 4：添加 Git Commit-msg 钩子
通过 Husky 创建 `commit-msg` 钩子（Git 提交信息校验的核心钩子）：
```bash
# 创建钩子文件，并写入校验命令
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit $1'
```
执行后会生成 `.husky/commit-msg` 文件，内容如下（无需修改）：
```bash
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx --no -- commitlint --edit $1
```
**关键说明**：`$1` 是 Git 自动传入的提交信息文件路径，`commitlint --edit` 会读取该文件内容并校验。

### 步骤 5：（可选）配置提交信息模板（提升体验）
为了让团队更清晰提交格式，可创建提交信息模板：
1. 在项目根目录新建 `.gitmessage` 文件，写入：
```
# 提交格式：<type>: <subject>
# 示例：feat: 新增用户登录功能
# 
# 可选type：feat/fix/docs/style/refactor/perf/test/chore/revert/build/ci
# subject：简洁描述变更（小写，结尾无句号）
# 
# 可选：换行后写详细描述（body）
# 
# 可选：关联Issue（如：fix #123）
```
2. 配置 Git 识别模板：
```bash
git config --local commit.template .gitmessage
```
作用：执行 `git commit` 时会自动打开该模板，提示团队按规范填写。

## 四、验证测试（关键步骤，确保配置生效）
### 测试 1：非法提交（预期失败）
执行不符合规范的提交，验证是否被拦截：
```bash
# 先随便修改一个文件并暂存（否则无法commit）
touch test.txt && git add test.txt

# 提交信息无type，预期失败
git commit -m "新增测试文件"
```
**预期结果**：终端报错，包含 `type-empty` 相关提示，提交终止。

### 测试 2：非法type（预期失败）
```bash
git commit -m "update: 新增测试文件"
```
**预期结果**：终端报错，包含 `type-enum` 相关提示（`update` 不在允许的列表中），提交终止。

### 测试 3：合法提交（预期成功）
```bash
git commit -m "feat: 新增测试文件模板"
```
**预期结果**：无报错，提交成功，终端显示 `[main xxx] feat: 新增测试文件模板`。

## 五、团队协作补充
1. **加入 README**：在项目 README 中添加提交规范说明，示例：
   ```markdown
   ### 提交信息规范
   提交格式：`<type>: <subject>`
   示例：`feat: 新增用户列表接口`
   支持的 type：feat/fix/docs/style/refactor/perf/test/chore/revert/build/ci
   ```
2. **依赖自动安装**：由于配置了 `prepare` 脚本，其他开发者执行 `npm install` 时会自动启用 husky，无需额外操作。
3. **异常处理**：若钩子不生效，检查：
   - `.husky` 目录是否存在
   - `commit-msg` 文件是否有执行权限（Linux/Mac 执行 `chmod +x .husky/commit-msg`）
   - Git 版本是否 ≥ 2.9（`git --version` 查看）

## 总结
1. 核心流程：安装依赖 → 初始化 husky → 配置 commitlint 规则 → 添加 commit-msg 钩子 → 验证生效；
2. 关键文件：`.commitlintrc.js`（规则配置）、`.husky/commit-msg`（钩子执行脚本）；
3. 核心效果：强制提交信息符合规范，非法提交直接终止，保障团队提交记录清晰可追溯。

按照以上步骤操作，可快速在项目中落地标准化的提交信息校验，无需复杂调试，开箱即用。





---

`.pre-commit-config.yaml` 是 **pre-commit 工具** 的专属配置文件（和 husky 是竞品，二选一或混用都可）

简单记：**pre-commit 管代码，commitlint 管文案，都是 commit 时自动拦着你，不让你提交不规范的东西**。