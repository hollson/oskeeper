#===================================================
#       Powershell SSH 登录远程主机
#===================================================

# 配置SSH公钥可免登录
while ($true) {
    write-host "============== SSH 登录主机 ==============" -ForegroundColor Green -BackgroundColor Black
    write-host "1.  10.0.0.11       root        虚拟机"         # 密码：xxxxxx
    write-host "2.  192.168.0.211   root        测试服务器"     # 密码：xxxxxx
    write-host "3.  192.168.0.211   root        测试服务器"
    Write-Output ""

    $choice = read-host "输入序号并按enter键确认"

    # 退出
    if ($choice -eq "q") {
        break
    }

    # 执行用户选择的命令
    switch ($choice) {
        1 {
            ssh root@10.0.0.11
            break
        }
        2 {
            ssh root@192.168.0.211
            break
        }
        3 {
            get-wmiobject -class win32_computersystem
            break
        }

        default {
            write-host "无效的选项，请重新运行脚本并输入正确的序号。"
            break
        }  
    }
}
read-host ""