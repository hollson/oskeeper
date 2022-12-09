#!/bin/bash
# shellcheck disable=SC1090
import() { . "$1" &>/dev/null; }

# ============================================================================================

# 全局变量
cmd=$1                            #二级命令
params="${@:2}"                   #二级命令参数
BACK_PATH="./backup"              # 备份目录
LOG_PATH="./dump.log"             # 日志文件(可通过环境变量(SDK_LOG_PATH)覆盖)
MIN_SIZE=1048576                  # 文件最小字节(1M)
ConsoleLog=on                     # 是否打印控制台日志(on/off)
CronSPEC="*/1 * * * *"            # 1分钟执行1次
ReportURL="http://localhost:8080" # 上报中心URL

## 导入脚本
import ~/.sdk/env.sh
import ./script/env.sh
import ./env.sh
import ~/.sdk/sdk.sh
import ./script/sdk.sh
import ./sdk.sh
# ============================================================================================

#删除空行
#function delLine() {
#  sed -i '/hello/d' test_temp
#}

# 发送邮件
function reportstatus() {
  status=$1
  body=$2
  prefix="mysql备份报告"

  if [[ $1 == 0 ]]; then
    subject="${prefix}——备份成功"
  else
    subject="${prefix}——备份失败"
  fi

  reqbody="{\"subject\":\"${subject}\",\"body\":\"${body}\"}"
  echo "reqbody: ${reqbody}"
  curl -X POST -H 'Content-Type:application/json' "$ReportURL/inspect/report" -d "${reqbody}"
}

# 检查备份数据
# 调用：checkSync "$BACK_PATH/$(date +%Y%m%d).tar"
function checkSync() {
  TarFile=$1
  if [ -f "$TarFile" ]; then
    size=$(wc -c "$TarFile" | awk '{print $1}')
    if [[ $size -le $MIN_SIZE ]]; then
      logError "文件大小异常 $TarFile size=${size}B"
      return 2
    fi
    return 0
  else
    logError "备份文件不存在 $TarFile"
    return 1
  fi
}

#添加定时作业
function registerJob() {
  jobs=$(crontab -l | grep 'sync_report.sh')
  echo "$jobs"
}

#echo $0
#checkSync "$BACK_PATH/$(date +%Y%m%d).tar"
#registerJob

function install() {
  echo "$!" >./pid
  logInfo "服务已启动"
}

function run() {
  set +e
  #  echo "$(pwd)"
  echo "$(basename "$0")"
  #  jobs=$(crontab -l | grep 'sync_report.sh')

  service crond reload &>/dev/null || service cron reload &>/dev/null
  if [ $? -ne 3 ]; then
    logFail "执行失败，请以root身份再次再次尝试运行."
    return 3
  fi
  logInfo "服务已启动..."
  crontab -l
  echo

  #  echo $?
  #  set -e
}

function usage() {
  echo "usage"
  #  echo "$2"
  #  echo "$params"
}

function testJob() {
  # shellcheck disable=SC2048
  echo $*
  echo "$(dateTime) [$1]" >>/var/logs/a.txt
  tail /var/logs/a.txt
}

function load() {
  case $cmd in
  testJob) testJob $params ;;
  install | ins) install $params ;;
  run) run $params ;;
  *) usage $params ;;
  esac
}
loadF
#testJob $1

#sed -i '/hello/d' ./a.txt # 删除关键字行
#sed -i '1d' a.txt         # 删首行
#sed -i '2d' a.txt         # 删除第2行
#sed -i '$d' a.txt         # 删除尾行
#sed -i 's/[ ]*//g' a.txt  # 删除空格
#sed -i '/^$/d' a.txt      # 删除空行

#echo /etc/nginx/nginx.conf |xargs basename
#https://blog.csdn.net/d1240673769/article/details/122072963


#* * * * * sleep 10; echo $(date) >> /home/hollson/udcp/source/udcp-monitor/script/a.txt
#*/1 * * * * /home/hollson/udcp/source/udcp-monitor/script/sync_report.sh