# Git 关联多个远程仓库 · 实操笔记

[TOC]





## 核心目标
本地代码库同时推送到多个远程仓库（如 GitHub、Gitee、公司GitLab）

## 一、查看现有远程仓库
```bash
git remote -v
```
**效果示例**：

```
origin  https://gitee.com/xxx/xxx.git (fetch)
origin  https://gitee.com/xxx/xxx.git (push)
```

## 二、添加新的远程仓库
```bash
# 格式：git remote add <自定义远程名> <仓库地址>
git remote add github https://github.com/你的用户名/仓库名.git
git remote add gitee https://gitee.com/你的用户名/仓库名.git
```
✅ 命名建议：用平台名（github/gitee）或用途（backup），方便识别

## 三、推送代码（核心操作）
### 方式1：单独推送到指定仓库
```bash
# 推到origin（原仓库）
git push origin main
# 推到github（新仓库）
git push github main
# 推到gitee（第三个仓库）
git push gitee main
```
⚠️ 注意：分支名根据实际情况替换（如 master、dev）

### 方式2：一键推送到所有远程仓库（高效）
```bash
# 批量推送main分支到所有远程
git remote | xargs -I {} git push {} main
```

## 四、补充操作（常用）
```bash
# 删除指定远程仓库
git remote remove github
# 修改远程仓库地址
git remote set-url origin 新的仓库地址
```

### 核心要点总结
1. 用 `git remote add` 给每个远程仓库起独立名称，实现多仓库关联；
2. 基础推送用 `git push <远程名> <分支>`，批量推送用 `git remote | xargs -I {} git push {} <分支>`；
3. 始终用 `git remote -v` 核对远程仓库配置，避免推送地址错误。