#!/usr/bin/env python3
import json
import os
import argparse
import subprocess
from prettytable import PrettyTable

class Color:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    WARN = '\033[93m 🔔'
    FAIL = '\033[91m ⛔️'
    END = '\033[0m'
    BOLD = '\033[1m'

def load_hosts(_config):
    try:
        with open(_config, 'r') as file:
            hosts = json.load(file)
    except FileNotFoundError:
        print(f"{Color.FAIL}未找到配置文件: {_config},请根据示例文件进行添加。{Color.END}\n")
        create_sample("./term_hosts_example.json")
        exit(1)

    # 检查ID是否重复
    id_set = set()
    for host in hosts:
        host_id = host.get('id')
        if host_id is not None:
            if host_id in id_set:
                print(f"{Color.FAIL}重复的主机ID: {host_id}, 请检查配置文件{Color.END}")
                exit(1)
            id_set.add(host_id)

    return hosts

# 创建示例文件
def create_sample(file_path):
    data = [
        {"id": 1001, "host": "192.168.10.1","port":22, "user": "root", "key":"~/.ssh/id_rsa", "os": "CentOS Stream 9", "arch": "x86_64", "region": "香港", "mark": "开发环境"},
        {"id": 1002, "host": "example.com", "user": "root", "os": "ubuntu22.04", "arch": "arm64", "region": "新加坡🇸🇬", "mark": "生产环境"},
        {"id": 1003, "host": "example.com", "user": "root",  "mark": "测试环境"},
    ]
    with open(file_path, 'w',encoding='utf-8') as file:
        json.dump(data, file, indent='\t', ensure_ascii=False)

def print_hosts(hosts):
    table = PrettyTable()
    table.field_names = [
        f"{Color.BOLD}{Color.BLUE}ID{Color.END}",
        f"{Color.BOLD}{Color.BLUE}主机{Color.END}",
        f"{Color.BOLD}{Color.BLUE}用户{Color.END}",
        f"{Color.BOLD}{Color.BLUE}系统{Color.END}",
        f"{Color.BOLD}{Color.BLUE}架构{Color.END}",
        f"{Color.BOLD}{Color.BLUE}位置{Color.END}",
        f"{Color.BOLD}{Color.BLUE}备注{Color.END}"
    ]

    for host in hosts:
        table.add_row([
            f"{Color.GREEN}{host['id']}{Color.END}",
            f"{Color.GREEN}{host['host']}{Color.END}",
            f"{Color.GREEN}{host['user']}{Color.END}",
            f"{Color.GREEN}{host['os']}{Color.END}",
            f"{Color.GREEN}{host['arch']}{Color.END}",
            f"{Color.GREEN}{host['region']}{Color.END}",
            f"{Color.GREEN}{host['mark']}{Color.END}"
        ])
    # print("\033]8;;https://www.a.com\033\\我是超链接\033]8;;\033\\")
    print(f"{Color.BOLD}{Color.BLUE}\t\t\t (Linux)\033]8;; https://github.com/hollson\033\\SSH远程主机管理\033]8;;\033\\v1.0 \t\t\t\t {Color.END}")
   
    print(table)

# ssh登录到远程主机
def ssh_connect(host):
    try:
        port = host.get('port', 22)                          # 默认端口
        key = host.get('key', '~/.ssh/id_rsa.pub')           # 默认私钥文件
        key = key if key and key.lower() != 'null' else None  
        port_option = f"-p {port}" if port != 22 else "" 

        cmd = f"ssh {port_option}" + (f" -i {key}" if key else "") + f" {host['user']}@{host['host']}"
        print(f"{Color.GREEN}=> 正在尝试登录: {Color.END}{Color.RED}{cmd}{Color.END}")
        subprocess.run(cmd, shell=True,check=True)
        
    except subprocess.CalledProcessError as e:
        print(f"{Color.FAIL}连接到 {host['host']} 时发生错误：{e}{Color.END}")
    except Exception as e:
        print(f"{Color.FAIL}连接到 {host['host']} 时发生错误：{str(e)}{Color.END}")

# ./term.py  --config ./term_hosts_example.json
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SSH远程主机管理")
    parser.add_argument("--config", help="指定配置文件路径")
    args = parser.parse_args()

    # 根据命令行参数获取配置文件路径
    _config = args.config if args.config else "~/.term_hosts.json"
    _config = os.path.expanduser(_config) 

    hosts = load_hosts(_config)
    print_hosts(hosts)
    
    try:
        id = int(input(f"{Color.BOLD}{Color.BLUE}请输入主机ID：{Color.END}"))
        host = next((host for host in hosts if host['id'] == id), None)

        if host:
            ssh_connect(host)
        else:
            print(f"{Color.FAIL}参数错误，退出。{Color.END}\n")
    except ValueError:
        print(f"{Color.FAIL}输入无效，退出。{Color.END}\n")
