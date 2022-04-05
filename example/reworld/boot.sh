#!/bin/bash

#==========================================================
#  脚本说明: 跟服务,网络,项目等个性化相关的参数配置与脚本
#           1. 优先加载/etc/reworld/boot.sh
#==========================================================

#=======================应用变量=============================
REWORLD_ENV="国内-MST-测试 -> bj-rd-uat-master-test"

#=======================环境变量=============================
export GIN_MODE=release

#======================服务启动项=============================
service[0]="ZkmAgent"
service[1]="LoginServer"
service[2]="ForumServer"
service[3]="MainServer"
service[4]="DiyServer"
service[5]="PlatAPIServer"
service[6]="SyncServer"
service[7]="PushServer"
service[8]="GateServer"
service[9]="NotifyServer"
service[10]="FileServer"
service[11]="TeamworkServer"
service[12]="GameDataServer"
service[13]="DownloadServer"
service[14]="FavoriteServer"
service[15]="MaintenanceServer"
service[16]="MatchServer"
service[17]="PushCenter"
