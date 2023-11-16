#===================================================
#       Powershell SSH 登录远程主机
#===================================================

while ($true) {
    write-host "=================== SSH 登录主机 ===================" -ForegroundColor Green -BackgroundColor Black
    write-host "1.  10.0.0.11       root        [Linux] 虚拟机"         # 密码： 123456
    write-host "2.  192.168.0.211   root        [Linux] 测试01"         # 密码： 123456
    write-host "3.  192.168.0.202   root        [Windows]测试02"        # 密码： 123456
    Write-Output ""
    $choice = read-host "输入序号并按enter键确认"

    # 退出
    if ($choice -eq "q") {
        break
    }

    # 执行用户选择的命令
    switch ($choice) {
        1 {
            # 免密登录：https://blog.csdn.net/Gusand/article/details/102713894
            ssh root@10.0.0.11
            break
        }
        2 {
            ssh root@192.168.0.211
            break
        }
        3 {
            # 添加凭证
            # cmdkey --help
            # cmdkey /generic:TERMSRV/192.168.0.202 /user:"Administrator" /pass:"xxxxxx"

            # mstsc --help
            mstsc /v:192.168.0.202:3389 /f /admin
            break
        }
        default {
            write-host "无效的选项，请重新运行脚本并输入正确的序号。"
            break
        }  
    }
}
read-host ""

# 查看系统信息：get-wmiobject -class win32_computersystem