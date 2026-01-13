#!/bin/bash
#
#======================================================================#
# Author:            li lei
# QQ:                45646231
# Date:              2023-03-20
# FileName:          install_zabbix_server6.0.sh
# E-Mail:            lilei@xacdyun.com
# Version:           2.0.0
# Description:       install zabbix server 6.0 with Apache2 PHP7 MySQL8
# Copyright (C) 2023 li lei
# OS DISTRIBUTION and OS VERSION:
# zabbix 6.0 LTS for RHEL\CentOS\OL\Rocky 8,9
# zabbix 6.0 LTS for Ubuntu 2004,2204
#======================================================================#

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "请使用root用户执行此脚本" >&2
    exit 1
fi
# Global Environment Variables
ZABBIX_VER=6.0
URL="mirrors.aliyun.com/zabbix"
ID=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
YUM_VERSION_ID=$(grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"' | cut -d. -f1)
APT_VERSION_ID=$(grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"' | awk '{printf "%.2f", $1}')
MYSQL_HOST=localhost
MYSQL_ZABBIX_USER="zabbix@localhost"
MYSQL_ZABBIX_PASS='123456'
MYSQL_ROOT_PASS='123456'
FONT=msyhbd.ttc
ZABBIX_IP=$(hostname -I | awk '{print $1}')
GREEN="echo -e \E[32;1m"
END="\E[0m"

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

install_mysql() {
    [ $MYSQL_HOST != "localhost" ] && return
    if [ $ID = "centos" -o $ID = "rocky" -o $ID = "ol" ]; then
        if [ ${YUM_VERSION_ID} == "8" -o ${YUM_VERSION_ID} == "9" ]; then
            yum -y install mysql-server
            systemctl enable --now mysqld
        fi
    else
        apt update
        apt -y install mysql-server
        sed -i "/^bind-address.*/c bind-address  = 0.0.0.0" /etc/mysql/mysql.conf.d/mysqld.cnf
        systemctl restart mysql
    fi
    mysqladmin -uroot password $MYSQL_ROOT_PASS
    mysql -uroot -p$MYSQL_ROOT_PASS <<EOF
create database zabbix character set utf8 collate utf8_bin;
create user $MYSQL_ZABBIX_USER identified by "$MYSQL_ZABBIX_PASS";
grant all privileges on zabbix.* to $MYSQL_ZABBIX_USER;
set global log_bin_trust_function_creators = 1;
quit
EOF
    if [ $? -eq 0 ]; then
        color "MySQL数据库准备完成" 0
    else
        color "MySQL数据库配置失败,退出" 1
        exit
    fi
}

install_zabbix() {
    if [ $ID = "centos" -o $ID = "rocky" -o $ID = "ol" ]; then
        if [ ${YUM_VERSION_ID} == "8" -o ${YUM_VERSION_ID} == "9" ]; then
            rpm -Uvh https://${URL}/zabbix/${ZABBIX_VER}/rhel/${YUM_VERSION_ID}/x86_64/zabbix-release-${ZABBIX_VER}-4.el${YUM_VERSION_ID}.noarch.rpm
            if [ $? -eq 0 ]; then
                color "YUM仓库准备完成" 0
            else
                color "YUM仓库配置失败,退出" 1
                exit
            fi
            sed -i "s#repo.zabbix.com#${URL}#" /etc/yum.repos.d/zabbix.repo
        fi
        yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent zabbix-get langpacks-zh_CN yum-utils
    else
        wget https://${URL}/zabbix/${ZABBIX_VER}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VER}-3+ubuntu${APT_VERSION_ID}_all.deb
        if [ $? -eq 0 ]; then
            color "APT仓库准备完成" 0
        else
            color "APT仓库配置失败,退出" 1
            exit
        fi
        dpkg -i zabbix-release_${ZABBIX_VER}-3+ubuntu${APT_VERSION_ID}_all.deb
        sed -i "s#repo.zabbix.com#${URL}#" /etc/apt/sources.list.d/zabbix.list
        apt update
        apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent zabbix-get language-pack-zh-hans
    fi
}

config_mysql_zabbix() {
    if [ -f "$FONT" ]; then
        mv /usr/share/zabbix/assets/fonts/graphfont.ttf{,.bak}
        cp "$FONT" /usr/share/zabbix/assets/fonts/graphfont.ttf
    else
        color "缺少字体文件!" 1
    fi
    if [ $MYSQL_HOST = "localhost" ]; then
        zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p$MYSQL_ZABBIX_PASS -h$MYSQL_HOST zabbix
        sed -i -e "/.*DBPassword=.*/c DBPassword=$MYSQL_ZABBIX_PASS" -e "/.*DBHost=.*/c DBHost=$MYSQL_HOST" /etc/zabbix/zabbix_server.conf
        if [ $ID = "centos" -o $ID = "rocky" -o $ID = "ol" ]; then
            sed -i "/.*upload_max_filesize.*/c php_value[upload_max_filesize] = 20M" /etc/php-fpm.d/zabbix.conf
            sed -i '$a\php_value[date.timezone] = Asia/Shanghai' /etc/php-fpm.d/zabbix.conf
            systemctl enable --now zabbix-server zabbix-agent httpd php-fpm
            systemctl restart zabbix-server zabbix-agent httpd php-fpm
        fi
    fi
    if [ $ID = "ubuntu" ]; then
        sed -i "s/php_value upload_max_filesize 2M/php_value upload_max_filesize 20M/g" /etc/apache2/conf-available/zabbix.conf
        sed -i "/date.timezone/c\\\t\php_value date.timezone Asia/Shanghai" /etc/apache2/conf-available/zabbix.conf
        chown -R www-data.www-data /usr/share/zabbix/
        systemctl enable zabbix-server zabbix-agent apache2
        systemctl restart zabbix-server zabbix-agent apache2
    fi
    if [ $? -eq 0 ]; then
        echo
        color "ZABBIX-${ZABBIX_VER}安装完成!" 0
        echo "-------------------------------------------------------------------"
        ${GREEN}"请访问: http://$ZABBIX_IP/zabbix"${END}
    else
        color "ZABBIX-${ZABBIX_VER}安装失败!" 1
        exit
    fi
}

install_mysql
install_zabbix
config_mysql_zabbix
