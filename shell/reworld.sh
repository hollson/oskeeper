#!/bin/bash

#==========================================================
#  脚本说明：
#    1.reworld脚本附随于打包文件根目录,用于项目服务自动化管理;
#    2.个性化shell脚本位于项目配置文件根目录,用于配置个性化服务;
#    3.执行install命令会将reworld脚本和项目文件安装到固定路径下;
#    4.开发环境可配源码路径的环境变量,用于自动化同步源码并更新服务;
#    5.请确保Makefile,setup,conf等主要文件和目录的结构路径固定.
#==========================================================

# 配置项
install_path=/app/reworld # 默认安装目录

# 公共变量
cmd=$1                   # 命令参数
params=$@                # 扩展参数
count=$#                 # 参数数量
app_root=${install_path} # 当前程序路径
shell_path=$(
    cd $(dirname $0)
    pwd
) #当前脚本路径
# echo $(readlink -f ./demo)

# 检查服务文件
function check_server() {
    # 优先使用当前目录(调制环境)
    if [[ -x ${shell_path}/reworld-server ]]; then
        app_root=${shell_path}
        return
    fi

    if [[ -x $install_path/reworld-server ]]; then
        return
    fi

    echo -e "「\033[31m未找到reworld-server程序文件！\033[0m」"
    exit 1
}

# 检查环境变量
function check_env() {
    # 危险操作,使用环境变量强约束
    if [[ $REWORLD_CODE == "" ]]; then
        echo -e "\033[35m ▲ 请配置本地代码仓库路径,如:\n\033[0mexport REWORLD_CODE=/go/src/github.com/reworld\n"
        exit 1
    else
        if [[ ! -f $REWORLD_CODE/Makefile ]]; then
            echo -e "\033[35m 🚫  REWORLD_CODE环境变量错误或源码目录文件异常.\033[0m\n"
            exit 1
        fi
    fi
}

#环境变量配置优先
function init() {
    check_server

    if [[ ! -x /etc/reworld/boot.sh ]]; then
        source $app_root/boot.sh
    else
        source /etc/reworld/boot.sh
    fi

    if [[ $REWORLD_CONF == "" ]]; then
        REWORLD_CONF="tpl-default"
    fi

    if [[ $REWORLD_DUMP == "" ]]; then
        REWORLD_DUMP="${HOME}/reworld_dump"
    fi
}
init

## config-cfg@编辑项目配置文件
function config() {
    vim $app_root/conf/reworld.toml
}

## list-lis@查看可用服务列表
function list() {
    echo -e "\033[1;35m可用服务列表:\033[0m "
    echo -e "注: 可在/etc/reworld/boot.sh【优先】或./boot.sh中设置服务启动项"
    echo "*********************************************"
    for key in $(echo ${!service[*]}); do
        echo -e "[$key]\t${service[$key]}"
    done
    echo -e "*********************************************\n"
}

## info-inf@查看服务信息
function info() {
    echo -e "\033[1;34m「REWORLD」游戏平台服务信息:\033[0m"
    echo -e "\033[33m当前环境:\033[0m \t$REWORLD_ENV"
    echo -e "\033[33m程序目录:\033[0m \t$app_root"
    #echo -e "\033[33m版本信息:\033[0m \t『`git rev-parse --abbrev-ref @{u}`』`git describe --tags --abbrev`"
    echo -e "\033[33m配置目录:\033[0m \t$app_root/conf"
    echo -e "\033[33m日志目录:\033[0m \t$app_root/log"

    #export|grep REWORLD|sed -n "s/^declare -x /\t\t/p"
    echo -e "\033[33m环境变量:\033[0m "
    echo -e "\t\033[36mREWORLD_CODE=\033[0m $REWORLD_CODE"       # 源码路径
    echo -e "\t\033[36mREWORLD_CONF=\033[0m $REWORLD_CONF"       # ./conf下的配置文件名,如:"tpl-inner-mst"
    echo -e "\t\033[36mREWORLD_LANG=\033[0m $REWORLD_LANG"       # 语言环境(翻译)
    echo -e "\t\033[36mREWORLD_DUMP=\033[0m $REWORLD_DUMP"       # 打包输出路径 "tpl-inner-mst"   ——> 默认编译配置文件
    echo -e "\t\033[36mREWORLD_ZK_ROOT=\033[0m $REWORLD_ZK_ROOT" # ZK目录(优先加载环境变量)
}

## install-ins@安装应用
function install() {
    if [[ ${install_path} == $(pwd) ]]; then
        echo -e "\033[1;31m不能在安装目录下操作. \033[0m \n"
        exit 1
    fi

    if [[ ! -x ./reworld-server || ! -x ./reworld || ! -d ./conf ]]; then
        echo -e "\033[1;31m发布文件缺失,请检查当前目录下的发布包文件是否完整. \033[0m \n"
        exit 1
    fi

    if [[ -d $install_path && $(ls $install_path | wc -w) -gt 0 ]]; then
        echo -e "\033[1;31m安装将会覆盖原有配置文件和程序文件(不会删除日志等动态数据).\n是否继续?(Y:继续;N/回车：退出)\033[0m"
        read forword
        if [[ "$forword" != "y" && "$forword" != "Y" ]]; then
            echo "退出安装..."
            exit 1
        fi
    fi

    echo -e "\033[1;34m正在安装... \033[0m"
    sleep 1s

    # 安装程序
    cur=$(pwd)
    sudo mkdir -p $install_path || {
        return
        exit 0
    } &&
        sudo /bin/cp -rf $cur/* $install_path/ || {
        return
        exit 0
    } &&
        sudo ln -fs $install_path/reworld /usr/local/bin/reworld
    echo -e "\033[1;32m安装成功: \033[0m$install_path"
    ls -hl $install_path --color=auto
    echo
    echo -e "\033[1;31m版本信息( ▶▶▶ 请检查服务安装是否正确 ◀◀◀ ) \033[0m" && cat $install_path/version
    echo
}

## deploy-dep@发布为打包文件
function deploy() {
    check_env
    cd "$REWORLD_CODE" || exit
    make deploy
    cd -
}

## run-run@启动服务
function run() {
    echo " ⚽  启动服务..."
    cd "$app_root" || exit
    for key in ${!service[*]}; do
        ./reworld-server ${service[$(expr ${key})]} &
    done
    cd -

    status
    echo " 🚗 服务已开启，更多内容请访问 https://api.reworld.com" # 服务列表
    echo
}

## restart-res@重启服务
function restart() {
    stop
    run
}

## stop-stp@停止服务
function stop() {
    echo -e " 🚫 停止现有服务..."
    sudo pkill reworld-server
    status
}

## status-stt@查看服务状态
function status() {
    ps -ef | grep -v 'grep' | grep -E 'reworld-server|UID' --color=auto
    count=$(ps -ef | grep -c 'reworld-server')
    echo -e "当前Reworld服务进程数： \033[1;31m $(("$count" - 1)) \033[0m.\n"
}

## update-upd@在线更新源码和服务(默认dev环境)
function update() {
    check_env

    sudo echo -e "\033[1;31m更新将会重新编译安装最新应用,并覆盖原有配置文件和程序文件.\n是否继续?(Y:继续;N/回车：退出)\033[0m"
    read forword
    if [[ "$forword" != "y" && "$forword" != "Y" ]]; then
        echo "退出更新..."
        exit 1
    fi

    cd $REWORLD_CODE
    echo -e "\033[1;32m  同步远程仓库...\033[0m"
    if [[ ! $(git pull) ]]; then
        echo -e "\033[1;31m 源码同步失败,退出更新服务...\033[0m"
        exit 1
    fi

    # 编译并更新服务
    make build

    # 安装程序
    sudo /bin/cp -rf ./release/${REWORLD_CONF:4}/* $install_path/ || {
        return
        exit 0
    }
    cd -
    echo -e "\033[1;33m 已更新到最新版本,可执行“reworld restart”重启服务.\033[0m"
    echo
}

## uninstall-uni@卸载服务
function uninstall() {
    stop
    sudo rm -rf /usr/local/reworld
    sudo rm -rf $app_root
    echo -e " ■  服务已卸载...\n"
}

## docker-dok@生成容器镜像并运行容器
function docker() {
    docker rmi -f reworld:1.0
    docker build -t reworld:1.0 .
    docker run -d --name reworld-server -p 8080:8080 reworld:1.0
    #docler exec -ti reworld-server /bin/sh
}

## version-ver@项目版本信息
function version() {
    cat $install_path/version
}

## help-*@帮助说明
function usage() {
    echo -e "\033[1;34m====================================================================\033[0m"
    echo -e "\033[1;34m     「REWORLD」游戏平台服务 - 自动化管理工具(v.21.04.07.15)\033[0m"
    echo -e "\033[1;34m====================================================================\033[0m"
    echo -e "用法：\n reworld [command] <param>"
    echo
    echo "Available Commands:"
    echo -e "\033[35m 命令  \t简写  \t说明:\033[0m"
    sed -n "s/^##//p" $0 | column -t -s '@-' | grep --color=auto "^[[:space:]][a-z]\+[[:space:]]"
    echo
    echo -e "For more to see https://support.reworlder.com\n"
}

# 调试输出
function debug() {
    echo -e "\033[1;35m install_path:\033[0m \t$install_path"
    echo -e "\033[1;35m app_root:\033[0m \t$app_root"
    echo -e "\033[1;35m shell_path:\033[0m \t$shell_path"
}

# 添加开屏提示
function coop() {
    echo -e "\033[1;35m=================================================================\n\t欢迎进入[Reworld]服务器系统\n\n提示：当前系统添加了Reworld自动化管理工具，编译、安装、启动、\n      停止、打包等相关操作，都可由reworld完成。\n      执行“reworld help”可查看帮助说明\n=================================================================\033[0m\n" >>/etc/motd
}

# 加载初始项
function load() {
    case $cmd in
    cfg | config) config ;;
    lis | list) list ;;
    inf | info) info ;;
    ins | install) install ;;
    dep | deploy) deploy ;;
    uni | uninstall) uninstall ;;
    run) run ;;
    upd | update) update ;;
    res | restart) restart ;;
    stp | stop) stop ;;
    stt | status) status ;;
    dok | docker) docker ;;
    ver | version) version ;;
    bug | debug) debug ;;
    cop | coop) coop ;;
    *) usage ;;
    esac
}
load
