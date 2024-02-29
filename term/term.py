#!/usr/bin/env python3

import os
import json
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
        print(f"{Color.BOLD}{Color.BLUE}Usage:\n\tterm.py <CONFIG>\n\nExample: \n\t./term.py --config ~/.ssh/term_hosts.json{Color.END}\n")
        print(f"{Color.FAIL}未找到配置文件: {_config}, 请根据示例文件进行添加。{Color.END}\n")
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
        {"id": 1, "host": "example1.com", "port": 22, "user": "root", "key": "~/.ssh/id_rsa", "os": "CentOS Stream 9", "arch": "x86_64", "region": "北京", "mark": "生产环境"},
        {"id": 2, "host": "example2.com", "user": "root", "os": "ubuntu22.04", "arch": "arm64", "region": "西安", "mark": "测试环境"},
        {"id": 3, "host": "192.168.10.1", "user": "root", "mark": "开发环境"},
    ]
    with open(file_path, 'w', encoding='utf-8') as file:
        json.dump(data, file, indent='\t', ensure_ascii=False)

def print_hosts1(hosts):
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
            f"{Color.GREEN}{host.get('os', '-')}{Color.END}",
            f"{Color.GREEN}{host.get('arch', '-')}{Color.END}",
            f"{Color.GREEN}{host.get('region', '-')}{Color.END}",
            f"{Color.GREEN}{host.get('mark', '-')}{Color.END}"
        ])
    
    print(f"{Color.BOLD}{Color.BLUE}\t\t\t (Linux)\033]8;; https://github.com/hollson\033\\SSH远程主机管理\033]8;;\033\\v1.0 \t\t\t\t {Color.END}")
    print(table)

def print_hosts2(hosts):
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
        try:
            host_id = f"{Color.GREEN}{host['id']}{Color.END}"
            host_name = f"{Color.GREEN}{host['host']}{Color.END}"
            user_name = f"{Color.GREEN}{host['user']}{Color.END}"

            os_info = host.get('os', '-')
            arch_info = host.get('arch', '-')
            region_info = host.get('region', '-')
            mark_info = host.get('mark', '-')

            if host_name and user_name:
                # 如果某一列都为空，则不需要打印这一列
                if any(info != '-' for info in [host_id, host_name, user_name, os_info, arch_info, region_info, mark_info]):
                    table.add_row([host_id, host_name, user_name, os_info, arch_info, region_info, mark_info])

        except KeyError:
            print(f"{Color.FAIL}主机信息缺失或格式不正确，请检查配置文件{Color.END}")
            exit(1)

    print(f"{Color.BOLD}{Color.BLUE}\t\t\t (Linux)\033]8;; https://github.com/hollson\033\\SSH远程主机管理\033]8;;\033\\v1.0 \t\t\t\t {Color.END}")
    print(table)

def print_hosts3(hosts):
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
        try:
            host_id = host.get('id')
            host_name = host.get('host')
            user_name = host.get('user')

            os_info = host.get('os', '-')
            arch_info = host.get('arch', '-')
            region_info = host.get('region', '-')
            mark_info = host.get('mark', '-')

            # host和user不能为None或空字符串
            if host_id is not None and host_name and user_name:
                # 如果某一列都为空，则不添加到表格中
                if any(info != '-' for info in [host_id, host_name, user_name, os_info, arch_info, region_info, mark_info]):
                    table.add_row([f"{Color.GREEN}{host_id}{Color.END}", f"{Color.GREEN}{host_name}{Color.END}", f"{Color.GREEN}{user_name}{Color.END}", os_info, arch_info, region_info, mark_info])

        except KeyError:
            print(f"{Color.FAIL}主机信息缺失或格式不正确，请检查配置文件{Color.END}")
            exit(1)

    if table._rows:  # 只有当表格非空时才打印
        print(f"{Color.BOLD}{Color.BLUE}\t\t\t (Linux)\033]8;; https://github.com/hollson\033\\SSH远程主机管理\033]8;;\033\\v1.0 \t\t\t\t {Color.END}")
        print(table)
    else:
        print(f"{Color.FAIL}所有列都为空，无法生成表格{Color.END}")

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

    # 检查标题是否全为空，全为空则不打印
    if not any(title != '' for title in table.field_names):
        print(f"{Color.FAIL}所有标题都为空，无法生成表格{Color.END}")
        return

    for host in hosts:
        try:
            host_id = host.get('id')
            host_name = host.get('host')
            user_name = host.get('user')

            os_info = host.get('os', '-')
            arch_info = host.get('arch', '-')
            region_info = host.get('region', '-')
            mark_info = host.get('mark', '-')

            # host和user不能为空
            if host_id is not None and host_name and user_name:
                table.add_row([f"{Color.GREEN}{host_id}{Color.END}", f"{Color.GREEN}{host_name}{Color.END}", f"{Color.GREEN}{user_name}{Color.END}", os_info, arch_info, region_info, mark_info])

        except KeyError:
            print(f"{Color.FAIL}主机信息缺失或格式不正确，请检查配置文件{Color.END}")
            exit(1)

    if table._rows:  # 只有当表格非空时才打印
        print(f"{Color.BOLD}{Color.BLUE}\t\t\t (Linux)\033]8;; https://github.com/hollson\033\\SSH远程主机管理\033]8;;\033\\v1.0 \t\t\t\t {Color.END}")
        print(table)
    else:
        print(f"{Color.FAIL}所有行都为空，无法生成表格{Color.END}")


# ssh登录到远程主机
def ssh_connect(host):
    try:
        port = host.get('port', 22)             # 默认端口
        key = host.get('key', '~/.ssh/id_rsa')  # 默认私钥文件
        key = key if key and key.lower() != 'null' else None
        port_option = f"-p {port}" if port != 22 else ""

        cmd = f"ssh {port_option}" + (f" -i {key}" if key else "") + f" {host['user']}@{host['host']}"
        print(f"{Color.GREEN}=> 正在尝试登录: {Color.END}{Color.RED}{cmd}{Color.END}")
        subprocess.run(cmd, shell=True, check=True)

    except subprocess.CalledProcessError as e:
        print(f"{Color.FAIL}连接到 {host['host']} 时发生错误：{e}{Color.END}")
    except Exception as e:
        print(f"{Color.FAIL}连接到 {host['host']} 时发生错误：{str(e)}{Color.END}")

# ./term --config ./term_hosts_example.json
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SSH远程主机管理")
    parser.add_argument("--config", help="指定配置文件路径")
    args = parser.parse_args()

    # 根据命令行参数获取配置文件路径
    _config = args.config if args.config else "~/.ssh/term_hosts.json"
    _config = os.path.expanduser(_config)

    hosts = load_hosts(_config)
    print_hosts(hosts)

    try:
        id = int(input(f"{Color.BOLD}{Color.BLUE}请输入主机ID(q退出)：{Color.END}"))
        host = next((host for host in hosts if host['id'] == id), None)

        if host:
            ssh_connect(host)
        else:
            print(f"{Color.FAIL}参数错误，退出。{Color.END}\n")
    except ValueError:
        print(f"{Color.FAIL}输入无效，退出。{Color.END}\n")
