#!/bin/bash
#
#=========================================================================#
# Author:            li lei
# QQ:                45646231
# Date:              2024-08-03
# FileName:          install_zabbix_server7
# E-Mail:            lilei@xacdyun.com
# Version:           3.0.0
# Description:       install zabbix server 7.0 with Apache2 PHP8 MariaDB11
# Copyright (C) 2024 li lei
# OS DISTRIBUTION and OS VERSION:
# zabbix 7.0 LTS for RHEL\CentOS\OL\Rocky 8,9
# zabbix 7.0 LTS for Ubuntu 2204,2404
#=========================================================================#

#==============================================================#
#                Global Environment Variables                  #
#==============================================================#
#
# 定义安装zabbix的版本
ZABBIX_VER=7.0
# 配置阿里云的源地址
URL="mirrors.aliyun.com/zabbix"
# 获取系统版本
ID=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
# 获取系统版本号
YUM_VERSION_ID=$(grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"' | cut -d. -f1)
# 获取系统版本号
APT_VERSION_ID=$(grep 'VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
# 获取系统小版本号
# RELEASE_VER=$(grep -oP 'release \K[0-9]+\.[0-9]+' /etc/redhat-release)
# 定义数据库为localhost
MYSQL_HOST=localhost
# 定义数据库zabbix用户名
MYSQL_ZABBIX_USER="zabbix@localhost"
# 定义数据库zabbix用户的密码
MYSQL_ZABBIX_PASS='123456'
# 定义数据库root用户的密码
MYSQL_ROOT_PASS='123456'
# 使用微软雅黑中文字体
FONT=msyhbd.ttc
# 获取当前操作系统IP地址
ZABBIX_IP=$(hostname -I | awk '{print $1}')
# 当前执行脚本系统时间
current=$(date +%Y%m%d%H%M%S)
# 脚本安装日志文件
zabbixinstalllog=/root/shell_install_output_$current.log
# 定义颜色
GREEN="echo -e \E[32;1m"
# 定义颜色
END="\E[0m"

function color() {
    # ANSI 转义码定义
    local -r color_reset='\e[0m'
    local -r color_red='\e[0;31m'
    local -r color_green='\e[0;32m'
    local -r color_yellow='\e[0;33m'
    local -r color_cyan='\e[0;36m'
    # 输出参数选择相应的颜色
    case "$1" in
    red) printf "${color_red}%s${color_reset}\n" "$2" ;;
    green) printf "${color_green}%s${color_reset}\n" "$2" ;;
    yellow) printf "${color_yellow}%s${color_reset}\n" "$2" ;;
    cyan) printf "${color_cyan}%s${color_reset}\n" "$2" ;;
    *) printf "Unsupported color\n" ;;
    esac
}

function check_internet_connectivity() {
    # 检查网络连接是否正常
    if ! ping -c 2 www.baidu.com >/dev/null 2>&1; then
        # 网络不通，输出错误并退出脚本
        color "red" "当前操作系统需要配置网络软件源，必须联网，否则安装失败！"
        exit 1 # 退出脚本，返回错误码1
    fi
}

function disabled_selinux() {
    if [ $ID = "centos" -o $ID = "rocky" -o $ID = "ol" -o $ID = "rhel" ]; then
        color "green" "为RHEL\CentOS\OL\Rocky Linux关闭SElinux..."
        if sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config; then
            color "green" "SELinux配置文件已更改为禁用状态" 0
        else
            color "red" "无法修改SELinux配置文件" 1
            return 1
        fi
        color "yellow" "SELinux的永久更改需要重启系统才能生效" 0
        return 0
    fi
}

function config_firewalld_on_centos_or_rocky() {
    if [ $ID = "centos" -o $ID = "rocky" -o $ID = "ol" -o $ID = "rhel" ]; then
        color "green" "为RHEL\CentOS\OL\Rocky Linux配置防火墙..."
        # 如果防火墙正在运行,配置防火墙
        if systemctl status firewalld | grep -q "active (running)"; then
            firewall-cmd --permanent --add-port=80/tcp
            firewall-cmd --permanent --add-port=10051/tcp
            firewall-cmd --permanent --add-port=443/tcp
            firewall-cmd --reload
            color "green" "配置防火墙完成"
        fi
    fi
}

function config_ufw_on_ubuntu_or_debian() {
    if [ $ID = "ubuntu" -o $ID = "debian" ]; then
        color "green" "为Ubuntu或Debian配置防火墙..."
        # 检查ufw是否已安装
        if command -v ufw &>/dev/null; then
            color "green" "ufw已安装在系统中."
            # 检查ufw是否已启用
            if ufw status verbose | grep -q 'Status: active'; then
                ecolor "green" "ufw已启用, 正在配置防火墙..."
                ufw allow 80/tcp
                ufw allow 443/tcp
                ufw allow 10051/tcp
                ufw reload
                color "green" "配置防火墙完成"
            fi
        fi
    fi
}

function install_mariadb_release() {
    color "green" "安装MariaDB源..."
    curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version=11.0 >>$zabbixinstalllog 2>&1
}

function install_mariadb() {
    color "green" "安装并初始化MariaDB数据库..."
    [ $MYSQL_HOST != "localhost" ] && return
    if [ $ID = "centos" -o $ID = "rocky" -o $ID = "ol" -o $ID = "rhel" ]; then
        if [ ${YUM_VERSION_ID} == "8" -o ${YUM_VERSION_ID} == "9" ]; then
            dnf -y install MariaDB-server MariaDB-client MariaDB-backup MariaDB-devel >>$zabbixinstalllog 2>&1
            systemctl enable mariadb --now
        fi
    else
        apt update
        apt -y install mariadb-server mariadb-client mariadb-backup >>$zabbixinstalllog 2>&1
        # sed -i "/^bind-address.*/c bind-address  = 0.0.0.0" /etc/mysql/mysql.conf.d/mysqld.cnf
        systemctl enable mariadb --now
    fi
    mariadb -uroot <<EOF
alter user 'root'@'localhost' identified by "$MYSQL_ROOT_PASS";
create database zabbix character set utf8 collate utf8_bin;
create user $MYSQL_ZABBIX_USER identified by "$MYSQL_ZABBIX_PASS";
grant all privileges on zabbix.* to $MYSQL_ZABBIX_USER;
set global log_bin_trust_function_creators = 1;
quit
EOF
    if [ $? -eq 0 ]; then
        color "green" "MariaDB数据库准备完成" 0
    else
        color "red" "MariaDB数据库配置失败,退出" 1
        exit
    fi
}

function change_PHP7_to_PHP8() {
    color "green" "针对CentOS8和RHEL8系统使用remi源安装PHP8..."
    if [ $ID = "centos" ]; then
        if [ ${YUM_VERSION_ID} = "8" ]; then
            # dnf -y install epel-release >>$zabbixinstalllog 2>&1
            cp /etc/yum.repos.d/CentOS-Base.repo /root
            dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.5.rpm >>$zabbixinstalllog 2>&1
            mkdir /etc/yum.repos.d/backup
            mv /etc/yum.repos.d/CentOS* /etc/yum.repos.d/backup
            mv /root/CentOS-Base.repo /etc/yum.repos.d/
            dnf -y module enable php:remi-8.0 >>$zabbixinstalllog 2>&1
        else
            color "red" "不支持的CentOS or RHEL版本" 1
            return 1
        fi
    elif [ $ID = "rocky" -o $ID = "ol" -o $ID = "rhel" ]; then
        if [ ${YUM_VERSION_ID} = "8" ]; then
            dnf -y install epel-release >>$zabbixinstalllog 2>&1
            dnf -y module switch-to php:8.0 >>$zabbixinstalllog 2>&1
        else
            color "red" "不支持的Rocky Linux or Oracle Linux版本" 1
            return 1
        fi
    fi
    if [ $? -eq 0 ]; then
        color "green" "PHP 8.0 安装和配置完成" 0
    else
        color "red" "PHP 8.0 安装和配置过程中出现问题" 1
        return 1
    fi
}

function install_zabbix() {
    color "green" "安装zabbix服务端..."
    if [ $ID = "centos" -o $ID = "rocky" -o $ID = "ol" -o $ID = "rhel" ]; then
        if [ ${YUM_VERSION_ID} == "8" ]; then
            rpm -Uvh https://${URL}/zabbix/${ZABBIX_VER}/rhel/${YUM_VERSION_ID}/x86_64/zabbix-release-${ZABBIX_VER}-1.el${YUM_VERSION_ID}.noarch.rpm >>$zabbixinstalllog 2>&1
        elif [ ${YUM_VERSION_ID} == "9" ]; then
            rpm -Uvh https://${URL}/zabbix/${ZABBIX_VER}/rhel/${YUM_VERSION_ID}/x86_64/zabbix-release-${ZABBIX_VER}-2.el${YUM_VERSION_ID}.noarch.rpm >>$zabbixinstalllog 2>&1
        fi
        if [ $? -eq 0 ]; then
            color "green" "YUM仓库准备完成" 0
            sed -i "s#repo.zabbix.com#${URL}#" /etc/yum.repos.d/zabbix.repo
            dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent zabbix-get langpacks-zh_CN >>$zabbixinstalllog 2>&1
        else
            color "red" "YUM仓库配置失败,退出" 1
            exit
        fi
    else
        wget https://${URL}/zabbix/${ZABBIX_VER}/${ID}/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VER}-1+${ID}${APT_VERSION_ID}_all.deb >>$zabbixinstalllog 2>&1
        if [ $? -eq 0 ]; then
            color "green" "APT仓库准备完成" 0
        else
            color "red" "APT仓库配置失败,退出" 1
            exit
        fi
        dpkg -i zabbix-release_${ZABBIX_VER}-1+${ID}${APT_VERSION_ID}_all.deb >>$zabbixinstalllog 2>&1
        sed -i "s#repo.zabbix.com#${URL}#" /etc/apt/sources.list.d/zabbix.list
        apt update
        apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent zabbix-get language-pack-zh-hans >>$zabbixinstalllog 2>&1
    fi
}

function config_mysql_zabbix() {
    color "green" "配置zabbix服务端..."
    if [ -f "$FONT" ]; then
        mv /usr/share/zabbix/assets/fonts/graphfont.ttf{,.bak}
        cp "$FONT" /usr/share/zabbix/assets/fonts/graphfont.ttf
    else
        color "red" "缺少字体文件!" 1
    fi
    if [ $MYSQL_HOST = "localhost" ]; then
        zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mariadb -uzabbix -p$MYSQL_ZABBIX_PASS -h$MYSQL_HOST zabbix
        sed -i -e "/.*DBPassword=.*/c DBPassword=$MYSQL_ZABBIX_PASS" -e "/.*DBHost=.*/c DBHost=$MYSQL_HOST" /etc/zabbix/zabbix_server.conf
        echo "set global log_bin_trust_function_creators = 0;" | mariadb -uroot -p$MYSQL_ROOT_PASS
        if [ $ID = "centos" -o $ID = "rocky" -o $ID = "ol" -o $ID = "rhel" ]; then
            sed -i "/.*upload_max_filesize.*/c php_value[upload_max_filesize] = 20M" /etc/php-fpm.d/zabbix.conf
            sed -i '$a\php_value[date.timezone] = Asia/Shanghai' /etc/php-fpm.d/zabbix.conf
            systemctl enable --now zabbix-server zabbix-agent httpd php-fpm
            systemctl restart zabbix-server zabbix-agent httpd php-fpm
        fi
    fi
    if [ $ID = "ubuntu" -o $ID = "debian" ]; then
        sed -i "s/php_value upload_max_filesize 2M/php_value upload_max_filesize 20M/g" /etc/apache2/conf-available/zabbix.conf
        sed -i "/date.timezone/c\\\t\php_value date.timezone Asia/Shanghai" /etc/apache2/conf-available/zabbix.conf
        chown -R www-data.www-data /usr/share/zabbix/
        systemctl enable zabbix-server zabbix-agent apache2
        systemctl restart zabbix-server zabbix-agent apache2
    fi
    if [ $? -eq 0 ]; then
        echo
        color "green" "ZABBIX-${ZABBIX_VER}安装完成!" 0
        echo "-------------------------------------------------------------------"
        ${GREEN}"请访问: http://$ZABBIX_IP/zabbix  默认用户名密码:  Admin / zabbix 数据库密码 123456"${END}
    else
        color "red" "ZABBIX-${ZABBIX_VER}安装失败!" 1
        exit
    fi
}

#==============================================================#
#                            主函数                             #
#==============================================================#
function main() {
    # 检查是否使用root用户执行脚本
    if [ "$EUID" -ne 0 ]; then
        color "red" "请使用root用户执行此脚本" >&2
        exit 1
    fi
    # 检查脚本名称是否为 install_zabbix_server7
    if [[ "$(basename "$0")" != "install_zabbix_server7" ]]; then
        color "red" "本脚本不允许修改脚本名称，请修改回：install_zabbix_server7，已退出!"
        exit 1
    fi
    check_internet_connectivity
    disabled_selinux
    config_firewalld_on_centos_or_rocky
    config_ufw_on_ubuntu_or_debian
    install_mariadb_release
    install_mariadb
    change_PHP7_to_PHP8
    install_zabbix
    config_mysql_zabbix
}
# 执行主函数
main "$@" | tee -a "$zabbixinstalllog"
