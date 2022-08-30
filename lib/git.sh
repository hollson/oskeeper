#!/bin/bash

git config --global alias.br "branch"  # 分支管理
git config --global alias.ci "commit"
git config --global alias.co "checkout"
git config --global alias.cp "cherry-pick"
git config --global alias.cv "cherry -v --abbrev=10"   #查看未push的commit
git config --global alias.rpo "remote prune origin"

git config --global alias.rbh2 "rebase -i HEAD~2"
git config --global alias.rbh3 "rebase -i HEAD~3"
git config --global alias.rbh4 "rebase -i HEAD~4"
git config --global alias.rbh5 "rebase -i HEAD~5"
git config --global alias.rs1 "reset --soft HEAD~1"
git config --global alias.rs "reset --soft"
git config --global alias.rh1 "reset --hard HEAD~1"
git config --global alias.rh "reset --hard"
git config --global alias.rl "reflog -10"   #查看引用日志


git config --global alias.ls "config -l"
git config --global alias.st "status"
git config --global alias.lg "lg = log --graph --pretty=format:'%Cred%h%Creset %C(bold blue)<%an> %Cgreen(%cr) %C(yellow)%d%Creset %C(bold magenta)%s' --abbrev-commit --date=relative"


git show --raw <commit>  # 查看某次提交的变更列表
git log --pretty=raw     # 显式gitk风格

# 如：git head HEAD~1
git config --global alias.head "lg -1"

awk '{print $2}'


# test
git br G
git br H
git br I
git br G
git br E

