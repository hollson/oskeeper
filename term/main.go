package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"

	"github.com/jedib0t/go-pretty/v6/table"
)

// Host represents a host configuration.
type Host struct {
	ID     int    `json:"id"`
	Host   string `json:"host"`
	Port   int    `json:"port"`
	User   string `json:"user"`
	Key    string `json:"key"`
	OS     string `json:"os"`
	Arch   string `json:"arch"`
	Region string `json:"region"`
	Mark   string `json:"mark"`
}

// Color represents ANSI color codes.
type Color string

const (
	Bold  Color = "\033[1m"
	Blue  Color = "\033[94m"
	Green Color = "\033[92m"
	Red   Color = "\033[91m"
	End   Color = "\033[0m"
)

func (t Color) string() string {
	return string(t)
}

func loadHosts(configPath string) ([]Host, error) {
	data, err := ioutil.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	var hosts []Host
	if err := json.Unmarshal(data, &hosts); err != nil {
		return nil, err
	}

	// Check for duplicate IDs
	idSet := make(map[int]bool)
	for _, host := range hosts {
		if idSet[host.ID] {
			return nil, fmt.Errorf("duplicate host ID: %d", host.ID)
		}
		idSet[host.ID] = true
	}

	return hosts, nil
}

func createSample(filePath string) {
	data := []Host{
		{ID: 1001, Host: "192.168.10.1", User: "root", OS: "CentOS Stream 9", Arch: "x86_64", Region: "香港", Mark: "开发环境"},
		{ID: 1002, Host: "example.com", User: "root", OS: "ubuntu22.04", Arch: "arm64", Region: "新加坡", Mark: "生产环境"},
		{ID: 1003, Host: "example.com", User: "root", Mark: "测试环境"},
	}

	fileData, err := json.MarshalIndent(data, "", "\t")
	if err != nil {
		fmt.Printf("Error creating sample file: %v\n", err)
		return
	}

	err = ioutil.WriteFile(filePath, fileData, 0644)
	if err != nil {
		fmt.Printf("Error creating sample file: %v\n", err)
		return
	}

	fmt.Printf("Sample file created: %s\n", filePath)
}

func printHosts(hosts []Host) {
	t := table.NewWriter()
	t.SetOutputMirror(os.Stdout)
	t.AppendHeader(table.Row{
		Bold + Blue + "ID" + End,
		Bold + Blue + "主机" + End,
		Bold + Blue + "用户" + End,
		Bold + Blue + "系统" + End,
		Bold + Blue + "架构" + End,
		Bold + Blue + "位置" + End,
		Bold + Blue + "备注" + End,
	})

	for _, host := range hosts {
		id := strconv.Itoa(host.ID)
		hostName := host.Host
		userName := host.User
		osInfo := host.OS
		archInfo := host.Arch
		regionInfo := host.Region
		markInfo := host.Mark

		if id != "" && hostName != "" && userName != "" {
			if id != "" || hostName != "" || userName != "" || osInfo != "" || archInfo != "" || regionInfo != "" || markInfo != "" {
				t.AppendRow([]interface{}{Green.string() + id + End.string(), Green.string() + hostName + End.string(), Green.string() + userName + End.string(), osInfo, archInfo, regionInfo, markInfo})
			}
		}
	}

	if t.Length() > 0 {
		fmt.Printf("%s(Linux)SSH远程主机管理\t\t\t\t%s\n", Bold+Blue, End)
		t.Render()
	} else {
		fmt.Printf("%s所有行都为空，无法生成表格%s\n", Red, End)
	}
}

func sshConnect(host Host) {
	portOption := ""
	if host.Port != 22 {
		portOption = fmt.Sprintf("-p %d", host.Port)
	}

	keyOption := ""
	if host.Key != "" && strings.ToLower(host.Key) != "null" {
		keyOption = fmt.Sprintf("-i %s", host.Key)
	}

	cmd := fmt.Sprintf("ssh %s %s %s@%s", portOption, keyOption, host.User, host.Host)
	fmt.Printf("%s=> 正在尝试登录: %s%s\n", Green, Red.string()+cmd+End.string(), End)

	// Add your SSH connection logic here
}

func main() {
	configPath := "./term_hosts_example.json"
	hosts, err := loadHosts(configPath)
	if err != nil {
		fmt.Printf("Error loading hosts: %v\n", err)
		return
	}

	printHosts(hosts)

	var id int
	fmt.Printf("%s%s请输入主机ID：%s", Bold+Blue, End, End)
	_, err = fmt.Scan(&id)
	if err != nil {
		fmt.Printf("%s输入无效，退出。%s\n", Red, End)
		return
	}

	var selectedHost Host
	for _, host := range hosts {
		if host.ID == id {
			selectedHost = host
			break
		}
	}

	if selectedHost.ID != 0 {
		sshConnect(selectedHost)
	} else {
		fmt.Printf("%s参数错误，退出。%s\n", Red, End)
	}
}
