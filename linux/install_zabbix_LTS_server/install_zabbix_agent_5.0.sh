#!/bin/bash
#
#==============================================================#
# Author:            li lei
# QQ:                45646231
# Date:              2022-03-06
# FileName:          install_zabbix_agent_5.0.sh
# E-Mail:            lilei@xacdyun.com
# Version:           1.0.0
# Description:       install zabbix_agent 5.0
# Copyright (C) 2022-2023 li lei
#==============================================================#
# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "请使用root用户执行此脚本" >&2
    exit 1
fi
# Global Environment Variables
ZABBIX_VER=5.0
URL="mirrors.aliyun.com/zabbix"
ZABBIX_HOSTNAME=$(hostname -I)
VERSION_ID=$(grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"' | cut -d. -f1)
UBUNTU_CODENAME=$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2 | tr -d '"')
ID=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
if [ -z "$1" ]; then
    read -p "请输入 Zabbix 服务器 IP 地址或域名：" server
else
    server=$1
fi
ZABBIX_SERVER=$server
echo "Zabbix 服务器地址：$ZABBIX_SERVER"
ping -c 4 $ZABBIX_SERVER
if [ $? -eq 0 ]; then
    echo "服务器可达，开始安装..."
else
    echo "无法连接服务器，请检查网络设置。"
fi
color() {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ]; then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "
    elif [ $2 = "failure" -o $2 = "1" ]; then
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
        echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo
}

install_zabbix_agent() {
    if [ $ID = "centos" -o $ID = "rocky" -o $ID = "ol" ]; then
        rpm -Uvh https://$URL/zabbix/${ZABBIX_VER}/rhel/${VERSION_ID}/x86_64/zabbix-release-${ZABBIX_VER}-1.el${VERSION_ID}.noarch.rpm
        if [ $? -eq 0 ]; then
            color "YUM仓库准备完成" 0
        else
            color "YUM仓库配置失败,退出" 1
            exit
        fi
        sed -i "s#repo.zabbix.com#${URL}#" /etc/yum.repos.d/zabbix.repo
        yum -y install zabbix-agent
    else
        wget https://${URL}/zabbix/${ZABBIX_VER}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VER}-1+${UBUNTU_CODENAME}_all.deb
        if [ $? -eq 0 ]; then
            color "APT仓库准备完成" 0
        else
            color "APT仓库配置失败,退出" 1
            exit
        fi
        dpkg -i zabbix-release_${ZABBIX_VER}-1+${UBUNTU_CODENAME}_all.deb
        sed -i "s#repo.zabbix.com#${URL}#" /etc/apt/sources.list.d/zabbix.list
        apt update
        apt -y install zabbix-agent
    fi
}

config_zabbix_agent() {
    sed -i -e "s/^Server=127\.0\.0\.1/Server=${ZABBIX_SERVER}/g" \
        -e "s/^ServerActive=127\.0\.0\.1/ServerActive=${ZABBIX_SERVER}/g" \
        -e "s/^Hostname=Zabbix server/Hostname=${ZABBIX_HOSTNAME}/g" \
        /etc/zabbix/zabbix_agentd.conf
}

start_zabbix_agent() {
    systemctl enable zabbix-agent.service
    systemctl restart zabbix-agent.service
    systemctl is-active zabbix-agent.service
    if [ $? -eq 0 ]; then
        echo "-------------------------------------------------------------------"
        color "Zabbix Agent 安装完成!" 0
    else
        color "Zabbix Agent 安装失败" 1
        exit
    fi
}

install_zabbix_agent
config_zabbix_agent
start_zabbix_agent
