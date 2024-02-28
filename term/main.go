package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"

	"github.com/jedib0t/go-pretty/v6/table"
)

const (
	ColorHeader  = "\033[95m"
	ColorBlue    = "\033[94m"
	ColorRed     = "\033[91m"
	ColorGreen   = "\033[92m"
	ColorWarning = "\033[93m"
	ColorFail    = "\033[91m"
	ColorEnd     = "\033[0m"
	ColorBold    = "\033[1m"
)

// Host 主机信息
type Host struct {
	ID   int
	Host string
	Port int
	User string
	Key  string
	OS   string
	Arch string
	Addr string
	Mark string
}

func loadHosts(filePath string) []Host {
	// 读取主机信息
	var hosts []Host
	// 这里你可以根据实际需要使用 Go 的文件操作函数读取 JSON 文件并解析成结构体切片
	// 此处省略，你可以在这里添加你的文件读取和 JSON 解析逻辑

	// 临时示例数据
	hosts = append(hosts, Host{1, "192.168.0.1", 22, "root", "", "ubuntu22.04", "arm64", "新加坡", "我的开发虚拟机"})
	hosts = append(hosts, Host{2, "192.168.0.2", 22, "root", "", "ubuntu22.04", "arm64", "新加坡002", "我的开发虚拟机"})

	return hosts
}

func printHosts(hosts []Host) {
	// 创建表格
	t := table.NewWriter()
	t.SetOutputMirror(os.Stdout)
	t.AppendHeader(table.Row{"ID", "主机地址", "用户", "操作系统", "架构", "位置", "备注"})

	// 添加数据行
	for _, host := range hosts {
		t.AppendRow(table.Row{host.ID, host.Host, host.User, host.OS, host.Arch, host.Addr, host.Mark})
	}

	// 设置样式
	t.SetStyle(table.StyleLight)

	// 输出表格
	fmt.Println(fmt.Sprintf("%s\t\t\t(Linux)SSH远程主机管理 v1.0 \t\t\t\t %s", ColorHeader, ColorEnd))
	t.Render()
}

func sshConnect(host Host) {
	// 连接到远程主机
	trySSHConnect(host)
}

func trySSHConnect(host Host) {
	// 尝试 SSH 连接
	portOption := ""
	if host.Port != 22 {
		portOption = fmt.Sprintf("-p %d", host.Port)
	}

	keyOption := ""
	if host.Key != "" && host.Key != "null" {
		keyOption = fmt.Sprintf("-i %s", host.Key)
	}

	cmd := exec.Command("ssh", portOption, keyOption, fmt.Sprintf("%s@%s", host.User, host.Host))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	fmt.Printf("%s=> 正在尝试登录: %s %s\n", ColorGreen, ColorEnd, fmt.Sprintf("%s@%s", host.User, host.Host))
	err := cmd.Run()
	if err != nil {
		fmt.Printf("%s连接到 %s 时发生错误：%s%s\n", ColorFail, host.Host, err, ColorEnd)
	}
}

func main() {
	// 读取主机信息
	filePath := "./hosts.json"
	hosts := loadHosts(filePath)

	// 打印主机信息
	printHosts(hosts)

	// 选择主机
	selectedID := getUserInput(fmt.Sprintf("%s请输入主机ID：%s", ColorBold, ColorEnd))
	selectedHost := getHostByID(hosts, selectedID)

	if selectedHost != nil {
		// 尝试连接到远程主机
		sshConnect(*selectedHost)
	} else {
		fmt.Printf("%s无效的主机ID。退出。%s\n", ColorFail, ColorEnd)
	}
}

func getUserInput(prompt string) int {
	// 获取用户输入并转换为整数
	var userInput string
	fmt.Print(prompt)
	fmt.Scanln(&userInput)
	id, err := strconv.Atoi(userInput)
	if err != nil {
		fmt.Printf("%s无效的输入。请输入有效的ID。%s\n", ColorFail, ColorEnd)
		return getUserInput(prompt)
	}
	return id
}

func getHostByID(hosts []Host, id int) *Host {
	// 根据主机ID获取主机信息
	for _, host := range hosts {
		if host.ID == id {
			return &host
		}
	}
	return nil
}
