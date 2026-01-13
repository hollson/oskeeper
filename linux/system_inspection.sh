#!/bin/bash
# 操作系统综合系统巡检工具 - HTML报告版本
# 功能整合：安全检测、性能监控、环境变量检查、句柄分析、服务状态监控等
# 使用前请以root权限运行，建议定期执行（如每日/每周）

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：此脚本需要以root权限运行，请使用sudo或切换到root用户"
    exit 1
fi

# 检查必要工具是否安装
check_dependencies() {
    local dependencies=("sysstat" "net-tools")
    local missing=()

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null && ! dpkg -s $dep &> /dev/null && ! rpm -q $dep &> /dev/null; then
            missing+=($dep)
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "检测到缺少必要工具，正在尝试安装..."
        if command -v apt &> /dev/null; then
            sudo apt update -y &> /dev/null
            sudo apt install -y "${missing[@]}" &> /dev/null
        elif command -v yum &> /dev/null; then
            sudo yum install -y "${missing[@]}" &> /dev/null
        else
            echo "无法自动安装依赖，请手动安装: ${missing[*]}"
            exit 1
        fi
    fi
}

# 初始化HTML巡检报告
REPORT_FILE="$(hostname)_$(hostname -I | awk '{print $1}')_$(date +"%Y%m%d")_操作系统巡检报告.html"
{
cat << EOF
<!DOCTYPE html>
<html>
<head>
    <title>$(hostname)服务器操作系统综合巡检报告-$(hostname)-$(hostname -I | awk '{print $1}')-$(date +"%Y%m%d")</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        h2 { color: #3498db; border-left: 4px solid #3498db; padding-left: 10px; }
        h3 { color: #2c3e50; }
        .section { margin-bottom: 25px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .warning { color: #e74c3c; font-weight: bold; }
        .success { color: #27ae60; }
        .info { color: #3498db; }
        .highlight { background-color: #fff8e1; padding: 15px; border-radius: 5px; border-left: 4px solid #ffc107; }
        .summary { background-color: #e3f2fd; padding: 15px; border-radius: 5px; margin-top: 20px; }
        .timestamp { color: #7f8c8d; text-align: right; font-size: 0.9em; }
        pre { background-color: #f8f9fa; padding: 10px; border-radius: 5px; overflow: auto; }
        .tab { overflow: hidden; border: 1px solid #ccc; background-color: #f1f1f1; border-radius: 5px; }
        .tab button { background-color: inherit; float: left; border: none; outline: none; cursor: pointer; padding: 10px 16px; transition: 0.3s; }
        .tab button:hover { background-color: #ddd; }
        .tab button.active { background-color: #ccc; }
        .tabcontent { display: none; padding: 6px 12px; border: 1px solid #ccc; border-top: none; animation: fadeEffect 1s; }
        @keyframes fadeEffect { from {opacity: 0;} to {opacity: 1;} }
        .risk-low { background-color: #d4edda; padding: 3px 6px; border-radius: 3px; }
        .risk-medium { background-color: #fff3cd; padding: 3px 6px; border-radius: 3px; }
        .risk-high { background-color: #f8d7da; padding: 3px 6px; border-radius: 3px; }
    </style>
</head>
<body>
<div class="container">
    <h1>$(hostname)服务器操作系统综合巡检报告</h1>
    <div class="tab">
        <button class="tablinks" onclick="openTab(event, 'Summary')" id="defaultOpen">概览</button>
        <button class="tablinks" onclick="openTab(event, 'SystemInfo')">系统信息</button>
        <button class="tablinks" onclick="openTab(event, 'Security')">安全检查</button>
        <button class="tablinks" onclick="openTab(event, 'Performance')">性能分析</button>
        <button class="tablinks" onclick="openTab(event, 'Services')">服务状态</button>
        <button class="tablinks" onclick="openTab(event, 'Logs')">日志分析</button>
    </div>
EOF
} > $REPORT_FILE

# 添加内容到HTML报告
add_to_report() {
    echo "$1" >> $REPORT_FILE
}

# 显示开始信息
echo "===== 操作系统综合巡检工具 ====="
echo "巡检时间: $(date)"
echo "报告将保存至: $REPORT_FILE"
echo "正在检查依赖工具..."
check_dependencies
echo "================================="

# 开始生成报告内容
add_to_report "<div id='Summary' class='tabcontent'>"
add_to_report "<h2>巡检概览</h2>"
add_to_report "<table>"
add_to_report "<td></td><td>"
add_to_report "<tr><td>项目名称</td><td></td></tr>"
add_to_report "<tr><td>项目编号</td><td></td></tr>"
add_to_report "<tr><td>巡检时间</td><td> $(date +"%Y-%m-%d %H:%M:%S")</td></tr>"
add_to_report "<tr><td>巡检单位</td><td> </td></tr>"
add_to_report "</td>"
add_to_report "</table>"
add_to_report "</div>"

# 1. 系统基本信息
echo "收集系统基本信息..."
add_to_report "<div id='SystemInfo' class='tabcontent'>"
add_to_report "<h2>1. 系统基本信息</h2>"

os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' 2>/dev/null || echo "未知")
kernel_version=$(uname -r)
hostname=$(hostname)
uptime=$(uptime | awk '{print $3 " " $4}' | sed 's/,//')
ip_address=$(hostname -I | awk '{print $1}')

add_to_report "<table>"
add_to_report "<tr><th>属性</th><th>结果</th></tr>"
add_to_report "<tr><td>系统版本</td><td>$os_info</td></tr>"
add_to_report "<tr><td>内核版本</td><td>$kernel_version</td></tr>"
add_to_report "<tr><td>主机名</td><td>$hostname</td></tr>"
add_to_report "<tr><td>IP地址</td><td>$ip_address</td></tr>"
add_to_report "<tr><td>运行时间</td><td>$uptime</td></tr>"
add_to_report "</table>"
add_to_report "</div>"

# 2. 环境变量安全检测
echo "进行环境变量安全检测..."
add_to_report "<div id='Security' class='tabcontent'>"
add_to_report "<h2>2. 环境变量安全检测</h2>"

# 2.1 PATH环境变量分析
add_to_report "<h3>PATH环境变量分析</h3>"
path_var=$PATH
IFS=':' read -ra path_array <<< "$path_var"
add_to_report "<p>PATH包含 <strong>${#path_array[@]}</strong> 个路径</p>"

dangerous_paths=("/" "/root" "/tmp" "/var/tmp" "/dev/shm")
dangerous_found=0
for path in "${path_array[@]}"; do
    if [[ " ${dangerous_paths[@]} " =~ " $path " ]]; then
        add_to_report "<p class='warning'>危险路径: $path (包含在PATH中)</p>"
        dangerous_found=1
    fi

    if [ -d "$path" ] && [ -w "$path" ] && ! ls -ld "$path" 2>/dev/null | grep -qE '^drwxr-xr-x'; then
        add_to_report "<p class='warning'>可写路径: $path (存在非授权写入风险)</p>"
        dangerous_found=1
    fi
done

if [ $dangerous_found -eq 0 ]; then
    add_to_report "<p class='success'>PATH环境变量检查正常</p>"
fi

# 2.2 敏感环境变量扫描
add_to_report "<h3>敏感环境变量扫描</h3>"
sensitive_vars=("PASSWORD" "SECRET" "KEY" "TOKEN" "CREDENTIAL" "PASS" "DB_PASS")
found_sensitive=0
for var in "${sensitive_vars[@]}"; do
    matches=$(env | grep -i "$var" | grep -v -E '^SHLVL=|^PWD=|^_=|^LS_COLORS=')
    if [ -n "$matches" ]; then
        found_sensitive=1
        add_to_report "<p class='warning'>潜在敏感变量:</p>"
        add_to_report "<div class='highlight'>"
        echo "$matches" | awk -F= '{print $1 "=***(内容已隐藏)***"}' >> $REPORT_FILE
        add_to_report "</div>"
    fi
done
if [ $found_sensitive -eq 0 ]; then
    add_to_report "<p class='success'>未发现明显敏感环境变量</p>"
fi

# 2.3 环境配置文件检查
add_to_report "<h3>环境配置文件权限检查</h3>"
env_files=("/etc/profile" "/etc/bashrc" "$HOME/.bashrc" "$HOME/.bash_profile")
add_to_report "<table>"
add_to_report "<tr><th>文件</th><th>权限</th><th>状态</th></tr>"
for file in "${env_files[@]}"; do
    if [ -f "$file" ]; then
        perms=$(stat -c "%a" "$file" 2>/dev/null)
        if [ "$perms" -gt 644 ]; then
            add_to_report "<tr><td>$file</td><td>$perms</td><td class='warning'>不安全权限 (建议≤644)</td></tr>"
        else
            add_to_report "<tr><td>$file</td><td>$perms</td><td class='success'>安全权限</td></tr>"
        fi
    else
        add_to_report "<tr><td>$file</td><td>N/A</td><td>文件不存在</td></tr>"
    fi
done
add_to_report "</table>"

# 3. 系统句柄数分析
echo "分析系统句柄数..."
add_to_report "<h2>3. 系统句柄数分析</h2>"

# 3.1 句柄限制配置
add_to_report "<h3>句柄限制配置</h3>"
sys_max_open=$(cat /proc/sys/fs/file-max 2>/dev/null || echo "未知")
sys_current_max=$(cat /proc/sys/fs/file-nr 2>/dev/null | awk '{print $1}' || echo "未知")
if [ "$sys_max_open" != "未知" ] && [ "$sys_current_max" != "未知" ]; then
    sys_available=$((sys_max_open - sys_current_max))
else
    sys_available="未知"
fi

add_to_report "<table>"
add_to_report "<tr><th>项目</th><th>值</th></tr>"
add_to_report "<tr><td>系统级最大句柄数</td><td>$sys_max_open</td></tr>"
add_to_report "<tr><td>当前系统已使用句柄</td><td>$sys_current_max</td></tr>"
add_to_report "<tr><td>系统句柄剩余可用</td><td>$sys_available</td></tr>"

user_soft=$(ulimit -Sn 2>/dev/null || echo "未知")
user_hard=$(ulimit -Hn 2>/dev/null || echo "未知")
add_to_report "<tr><td>用户级句柄限制(软)</td><td>$user_soft</td></tr>"
add_to_report "<tr><td>用户级句柄限制(硬)</td><td>$user_hard</td></tr>"

if [ "$sys_max_open" != "未知" ] && [ "$sys_current_max" != "未知" ] && [ "$sys_max_open" -ne 0 ]; then
    usage_rate=$(echo "scale=2; $sys_current_max / $sys_max_open * 100" | bc)
    add_to_report "<tr><td>系统句柄整体使用率</td><td>$usage_rate%</td></tr>"
    
    if (( $(echo "$usage_rate > 80" | bc -l 2>/dev/null) )); then
        add_to_report "<p class='warning'>警告: 系统句柄使用率超过80%，可能面临耗尽风险</p>"
    fi
else
    add_to_report "<tr><td>系统句柄整体使用率</td><td>未知</td></tr>"
fi
add_to_report "</table>"

# 3.2 进程句柄TOP分析
add_to_report "<h3>句柄使用TOP 10进程</h3>"
add_to_report "<table>"
add_to_report "<tr><th>排名</th><th>PID</th><th>句柄数</th><th>进程名</th></tr>"

if command -v lsof &> /dev/null; then
    rank=0
    lsof -n 2>/dev/null | awk '{print $2}' | sort | uniq -c | sort -nr | head -10 | while read count pid; do
        if [ -n "$pid" ] && [ "$pid" -gt 0 ]; then
            cmd=$(ps -p $pid -o comm= 2>/dev/null || echo "未知")
            rank=$((rank+1))
            add_to_report "<tr><td>$rank</td><td>$pid</td><td>$count</td><td>$cmd</td></tr>"
        fi
    done
else
    add_to_report "<tr><td colspan='4'>lsof命令未安装，无法获取进程句柄信息</td></tr>"
fi

add_to_report "</table>"

# 5. 系统安全检测
echo "进行系统安全检测..."
add_to_report "<h2>4. 系统安全检测</h2>"

# 5.1 用户安全检查
add_to_report "<h3>用户安全检查</h3>"
empty_passwords=$(awk -F: '($2 == "" && $1 != "root") {print $1}' /etc/shadow 2>/dev/null)
if [ -z "$empty_passwords" ]; then
    add_to_report "<p class='success'>未发现空密码账户</p>"
else
    add_to_report "<p class='warning'>发现以下空密码账户: $empty_passwords</p>"
fi

privileged_users=$(awk -F: '($3 == 0 && $1 != "root") {print $1}' /etc/passwd 2>/dev/null)
if [ -z "$privileged_users" ]; then
    add_to_report "<p class='success'>未发现除root外的特权用户</p>"
else
    add_to_report "<p class='warning'>发现以下非root特权用户: $privileged_users</p>"
fi

# 5.2 关键文件权限检查
add_to_report "<h3>关键文件权限检查</h3>"
critical_files=(
    "/etc/passwd" "/etc/shadow" "/etc/sudoers"
    "/etc/group" "/etc/hosts" "/etc/resolv.conf"
)

add_to_report "<table>"
add_to_report "<tr><th>文件</th><th>当前权限</th><th>建议权限</th><th>状态</th></tr>"
for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        perms=$(stat -c "%a" "$file" 2>/dev/null)
        case $file in
            "/etc/shadow")
                if [ "$perms" -ne 400 ] && [ "$perms" -ne 0 ]; then
                    add_to_report "<tr><td>$file</td><td>$perms</td><td>400</td><td class='warning'>不安全</td></tr>"
                else
                    add_to_report "<tr><td>$file</td><td>$perms</td><td>400</td><td class='success'>安全</td></tr>"
                fi
                ;;
            "/etc/sudoers")
                if [ "$perms" -ne 440 ] && [ "$perms" -ne 0 ]; then
                    add_to_report "<tr><td>$file</td><td>$perms</td><td>440</td><td class='warning'>不安全</td></tr>"
                else
                    add_to_report "<tr><td>$file</td><td>$perms</td><td>440</td><td class='success'>安全</td></tr>"
                fi
                ;;
            *)
                if [ "$perms" -gt 644 ] && [ "$perms" -ne 0 ]; then
                    add_to_report "<tr><td>$file</td><td>$perms</td><td>≤644</td><td class='warning'>不安全</td></tr>"
                else
                    add_to_report "<tr><td>$file</td><td>$perms</td><td>≤644</td><td class='success'>安全</td></tr>"
                fi
                ;;
        esac
    else
        add_to_report "<tr><td>$file</td><td>N/A</td><td>N/A</td><td class='warning'>文件不存在</td></tr>"
    fi
done
add_to_report "</table>"

# 5.3 SSH与防火墙检查
add_to_report "<h3>远程访问与防火墙检查</h3>"
ssh_config="/etc/ssh/sshd_config"
if [ -f "$ssh_config" ]; then
    root_login=$(grep -E '^PermitRootLogin' $ssh_config 2>/dev/null | awk '{print $2}')
    if [ "$root_login" = "no" ]; then
        add_to_report "<p class='success'>SSH已禁用root直接登录</p>"
    else
        add_to_report "<p class='warning'>SSH允许root直接登录 (建议设置为PermitRootLogin no)</p>"
    fi
fi

if command -v ufw &> /dev/null; then
    ufw_status=$(ufw status 2>/dev/null | grep "Status" | awk '{print $2}')
    if [ "$ufw_status" = "active" ]; then
        add_to_report "<p class='success'>UFW防火墙已激活</p>"
    else
        add_to_report "<p class='warning'>UFW防火墙未激活</p>"
    fi
elif command -v firewalld &> /dev/null; then
    firewalld_status=$(systemctl is-active firewalld 2>/dev/null)
    if [ "$firewalld_status" = "active" ]; then
        add_to_report "<p class='success'>firewalld防火墙已激活</p>"
    else
        add_to_report "<p class='warning'>firewalld防火墙未激活</p>"
    fi
else
    add_to_report "<p class='warning'>未检测到常用防火墙(UFW/firewalld)</p>"
fi
add_to_report "</div>"

# 4. 系统性能深度检测
echo "进行系统性能检测..."
add_to_report "<div id='Performance' class='tabcontent'>"
add_to_report "<h2>5. 系统性能检测</h2>"

# 4.1 CPU性能分析
add_to_report "<h3>CPU性能分析</h3>"
cpu_cores=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "未知")
cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed -e 's/^ *//' || echo "未知")

add_to_report "<table>"
add_to_report "<tr><th>项目</th><th>值</th></tr>"
add_to_report "<tr><td>CPU型号</td><td>$cpu_model</td></tr>"
add_to_report "<tr><td>CPU核心数</td><td>$cpu_cores</td></tr>"

if command -v vmstat &> /dev/null; then
    cpu_usage=$(vmstat 1 2 2>/dev/null | tail -n 1 | awk '{printf "%.2f", 100-$15}')
    add_to_report "<tr><td>CPU使用率</td><td>$cpu_usage%</td></tr>"
    
    # 比较逻辑：检查CPU使用率是否大于等于80%
    if (( $(echo "$cpu_usage >= 80" | bc -l 2>/dev/null) )); then
        add_to_report "<p class='warning'>警告: CPU使用率超过80%</p>"
    fi
else
    add_to_report "<tr><td>CPU平均使用率</td><td>sysstat未安装</td></tr>"
fi
add_to_report "</table>"

add_to_report "<h4>CPU占用TOP5进程</h4>"
add_to_report "<table>"
add_to_report "<tr><th>CPU%</th><th>PID</th><th>用户</th><th>命令</th></tr>"
ps -eo %cpu,pid,user,comm --sort=-%cpu 2>/dev/null | head -6 | awk 'NR>1 {printf "<tr><td>%.2f%%</td><td>%d</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4}' >> $REPORT_FILE
add_to_report "</table>"

# 4.2 内存性能分析
add_to_report "<h3>内存性能分析</h3>"
mem_info=$(free -h 2>/dev/null || echo "未知")
if [ "$mem_info" != "未知" ]; then
    mem_total=$(free -h | grep Mem | awk '{print $2}')
    mem_used=$(free -h | grep Mem | awk '{print $3}')
    mem_free=$(free -h | grep Mem | awk '{print $4}')
    mem_available=$(free -h | grep Mem | awk '{print $7}')
    mem_used_percent=$(free | grep Mem | awk '{printf "%.2f", $3/$2*100}')
else
    mem_total="未知"
    mem_used="未知"
    mem_free="未知"
    mem_available="未知"
    mem_used_percent="未知"
fi

add_to_report "<table>"
add_to_report "<tr><th>项目</th><th>属性</th></tr>"
add_to_report "<tr><td>总内存</td><td>$mem_total</td></tr>"
add_to_report "<tr><td>已使用</td><td>$mem_used ($mem_used_percent%)</td></tr>"
add_to_report "<tr><td>空闲内存</td><td>$mem_free</td></tr>"
add_to_report "<tr><td>可用内存</td><td>$mem_available</td></tr>"
add_to_report "</table>"

if [ "$mem_used_percent" != "未知" ] && (( $(echo "$mem_used_percent > 80" | bc -l 2>/dev/null) )); then
    add_to_report "<p class='warning'>警告: 内存使用率超过80%</p>"
fi

add_to_report "<h4>内存占用TOP5进程</h4>"
add_to_report "<table>"
add_to_report "<tr><th>内存%</th><th>内存大小</th><th>PID</th><th>用户</th><th>命令</th></tr>"
ps -eo %mem,rss,pid,user,comm --sort=-%mem 2>/dev/null | head -6 | awk 'NR>1 {printf "<tr><td>%.2f%%</td><td>%sK</td><td>%d</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4, $5}' >> $REPORT_FILE
add_to_report "</table>"

# 4.3 磁盘性能分析
add_to_report "<h3>磁盘性能分析</h3>"
add_to_report "<h4>文件系统使用率</h4>"
add_to_report "<table>"
add_to_report "<tr><th>文件系统</th><th>大小</th><th>已用</th><th>可用</th><th>使用%</th><th>挂载点</th><th>状态</th></tr>"
df -h 2>/dev/null | grep -vE 'tmpfs|loop|udev' | awk 'NR>1 {print $0}' | while read line; do
    fs=$(echo $line | awk '{print $1}')
    size=$(echo $line | awk '{print $2}')
    used=$(echo $line | awk '{print $3}')
    avail=$(echo $line | awk '{print $4}')
    usage=$(echo $line | awk '{print $5}')
    mount=$(echo $line | awk '{print $6}')
    usage_val=$(echo $usage | sed 's/%//')
    
    if [ "$usage_val" -gt 80 ] 2>/dev/null; then
        status="<span class='warning'>警告: 使用率超过80%</span>"
    else
        status="正常"
    fi
    
    add_to_report "<tr><td>$fs</td><td>$size</td><td>$used</td><td>$avail</td><td>$usage</td><td>$mount</td><td>$status</td></tr>"
done
add_to_report "</table>"

add_to_report "<h4>磁盘I/O性能(1秒采样)</h4>"
if command -v iostat &> /dev/null; then
    add_to_report "<pre>"
    iostat -x 1 1 2>/dev/null | tail -n +4 >> $REPORT_FILE
    add_to_report "</pre>"
else
    add_to_report "<p>iostat命令未安装，无法获取磁盘I/O信息</p>"
fi

# 4.4 网络性能分析
add_to_report "<h3>网络性能分析</h3>"
add_to_report "<h4>网络接口流量(1秒采样)</h4>"
if command -v sar &> /dev/null; then
    add_to_report "<pre>"
    sar -n DEV 1 1 2>/dev/null | tail -n +3 >> $REPORT_FILE
    add_to_report "</pre>"
else
    add_to_report "<p>sar命令未安装，无法获取网络流量信息</p>"
fi

add_to_report "<h4>网络连接状态分布</h4>"
add_to_report "<table>"
add_to_report "<tr><th>状态</th><th>连接数</th></tr>"
if command -v netstat &> /dev/null; then
    netstat -ant 2>/dev/null | awk '/^tcp/ {++S[$NF]} END {for(a in S) print "<tr><td>" a "</td><td>" S[a] "</td></tr>"}' >> $REPORT_FILE
else
    add_to_report "<tr><td colspan='2'>netstat命令未安装，无法获取网络连接信息</td></tr>"
fi
add_to_report "</table>"
add_to_report "</div>"

# 6. 服务与系统更新检查
echo "检查服务状态与系统更新..."
add_to_report "<div id='Services' class='tabcontent'>"
add_to_report "<h2>6. 服务状态与系统更新</h2>"

# 6.1 关键服务状态
add_to_report "<h3>关键服务状态检查</h3>"
critical_services=(
    "sshd"           # SSH服务
    "firewalld"      # 防火墙服务
    "crond"          # 定时任务服务
    "rsyslog"        # 日志服务
    "docker"         # Docker服务（如有）
    "nginx"          # Nginx服务（如有）
    "mysql"          # MySQL服务（如有）
    "redis"          # Redis服务（如有）
)

add_to_report "<table>"
add_to_report "<tr><th>服务</th><th>状态</th></tr>"
for service in "${critical_services[@]}"; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        add_to_report "<tr><td>$service</td><td class='success'>正常运行</td></tr>"
    else
        if systemctl list-unit-files --type=service 2>/dev/null | grep -q "$service"; then
            add_to_report "<tr><td>$service</td><td class='warning'>已安装但未运行</td></tr>"
        else
            add_to_report "<tr><td>$service</td><td>未安装</td></tr>"
        fi
    fi
done
add_to_report "</table>"

# 6.2 系统更新检查
add_to_report "<h3>系统更新检查</h3>"
if command -v apt &> /dev/null; then
    updates=$(apt list --upgradable 2>/dev/null | wc -l)
    updates=$((updates-1)) # 减去标题行
    security_updates=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
    add_to_report "<p>可用系统更新: $updates 个 (其中安全更新: $security_updates 个)</p>"
elif command -v yum &> /dev/null; then
    updates=$(yum check-update 2>/dev/null | grep -v "已加载插件" | wc -l)
    security_updates=$(yum check-update --security 2>/dev/null | wc -l)
    add_to_report "<p>可用系统更新: $updates 个 (其中安全更新: $security_updates 个)</p>"
else
    add_to_report "<p>无法检测可用更新(不支持apt/yum包管理器)</p>"
fi
add_to_report "</div>"

# 7. 日志与定时任务检查
echo "检查日志与定时任务..."
add_to_report "<div id='Logs' class='tabcontent'>"
add_to_report "<h2>7. 日志与定时任务检查</h2>"

# 7.1 错误日志检查
add_to_report "<h3>系统错误日志检查</h3>"
log_files=("/var/log/messages" "/var/log/syslog")
error_found=0
for log_file in "${log_files[@]}"; do
    if [ -f "$log_file" ]; then
        error_logs=$(grep -iE "error|fail|critical|alert|emergency" "$log_file" 2>/dev/null | grep -v "CRON" | tail -5)
        if [ -n "$error_logs" ]; then
            error_found=1
            add_to_report "<p class='warning'>$log_file 中发现错误日志记录:</p>"
            add_to_report "<div class='highlight'><pre>$error_logs</pre></div>"
        fi
    fi
done
if [ $error_found -eq 0 ]; then
    add_to_report "<p class='success'>未发现明显错误日志</p>"
fi

# 7.2 登录失败检查
add_to_report "<h3>登录失败记录检查</h3>"
auth_files=("/var/log/secure" "/var/log/auth.log")
login_failures=0
for auth_file in "${auth_files[@]}"; do
    if [ -f "$auth_file" ]; then
        failed_logins=$(grep "Failed password" "$auth_file" 2>/dev/null | tail -5)
        if [ -n "$failed_logins" ]; then
            login_failures=1
            add_to_report "<p class='warning'>$auth_file 中发现登录失败记录:</p>"
            add_to_report "<div class='highlight'><pre>$failed_logins</pre></div>"
        fi
    fi
done
if [ $login_failures -eq 0 ]; then
    add_to_report "<p class='success'>未发现登录失败记录</p>"
fi

# 7.3 定时任务检查
add_to_report "<h3>定时任务安全检查</h3>"
add_to_report "<div class='highlight'><pre>"
add_to_report "# 系统定时任务:"
cat /etc/crontab 2>/dev/null | grep -v '^#' | grep -v '^$' >> $REPORT_FILE

add_to_report ""
add_to_report "# 用户定时任务:"
for user in $(cut -f1 -d: /etc/passwd); do
    user_cron=$(crontab -l -u $user 2>/dev/null | grep -v '^#' | grep -v '^$')
    if [ -n "$user_cron" ]; then
        add_to_report "# $user 用户的定时任务:"
        echo "$user_cron" | sed "s/^/  /" >> $REPORT_FILE
    fi
done

add_to_report ""
#add_to_report "# 定时任务文件:"
#ls -la /etc/cron.* 2>/dev/null >> $REPORT_FILE
add_to_report "</pre></div>"

suspicious_crons=$(grep -r -E 'wget|curl|bash -i|nc |netcat' /etc/cron* 2>/dev/null | grep -v -E '#|/usr/bin/')
if [ -n "$suspicious_crons" ]; then
    add_to_report "<p class='warning'>发现可能存在风险的定时任务:</p>"
    add_to_report "<div class='highlight'><pre>$suspicious_crons</pre></div>"
else
    add_to_report "<p class='success'>未发现明显风险的系统级定时任务</p>"
fi
add_to_report "</div>"

# 巡检总结
add_to_report "<div class='summary'>"
add_to_report "<h2>巡检总结</h2>"
add_to_report "<p>检查完成时间: $(date +"%Y-%m-%d %H:%M:%S")</p>"
add_to_report "<h3>重点关注项:</h3>"
add_to_report "<ul>"
if [ "$usage_rate" != "未知" ] && (( $(echo "$usage_rate > 80" | bc -l 2>/dev/null) )); then 
    add_to_report "<li class='warning'>系统句柄使用率过高</li>"; 
fi
if [ "$cpu_usage" != "未知" ] && (( $(echo "$cpu_usage > 80" | bc -l 2>/dev/null) )); then 
    add_to_report "<li class='warning'>CPU使用率过高</li>"; 
fi
if [ "$mem_used_percent" != "未知" ] && (( $(echo "$mem_used_percent > 80" | bc -l 2>/dev/null) )); then 
    add_to_report "<li class='warning'>内存使用率过高</li>"; 
fi
if [ -n "$empty_passwords" ] || [ -n "$privileged_users" ]; then 
    add_to_report "<li class='warning'>用户安全配置存在问题</li>"; 
fi
add_to_report "</ul>"
add_to_report "</div>"

# 添加JavaScript标签页功能
add_to_report "<script>
function openTab(evt, tabName) {
    var i, tabcontent, tablinks;
    tabcontent = document.getElementsByClassName('tabcontent');
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = 'none';
    }
    tablinks = document.getElementsByClassName('tablinks');
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(' active', '');
    }
    document.getElementById(tabName).style.display = 'block';
    evt.currentTarget.className += ' active';
}

// 默认打开第一个标签页
document.getElementById('defaultOpen').click();
</script>"

# 完成HTML报告
add_to_report "</div></body></html>"

echo "===== 操作系统综合巡检完成 ====="
echo "HTML巡检报告已保存至: $REPORT_FILE"
echo "请使用浏览器打开查看详细报告"