

### 一、安装依赖（必须）
```bash
sudo apt update && sudo apt install -y \
  build-essential \
  linux-headers-$(uname -r) \
  gcc make
```

### 二、下载 VMware Player 17.6.3（适配 Ubuntu 24.04）
```bash
wget https://softwareupdate.vmware.com/cds/vmw-desktop/player/17.6.3/24238078/linux/core/VMware-Player-17.6.3-24238078.x86_64.bundle
```

### 三、静默安装（无界面）
```bash
chmod +x VMware-Player-17.6.3-24238078.x86_64.bundle
sudo ./VMware-Player-17.6.3-24238078.x86_64.bundle \
  --console --eulas-agreed --required
```
出现 `The installation succeeded` 即成功。

### 四、修复内核模块（Ubuntu 24.04 必做）
Ubuntu 24.04 内核较新，直接编译会失败，用社区补丁：
```bash
# 下载对应版本补丁
wget https://github.com/mkubecek/vmware-host-modules/archive/workstation-17.6.3.tar.gz
tar -xzf workstation-17.6.3.tar.gz
cd vmware-host-modules-workstation-17.6.3

# 打包覆盖 VMware 源码
tar -cf vmmon.tar vmmon-only
tar -cf vmnet.tar vmnet-only
sudo cp -v vmmon.tar vmnet.tar /usr/lib/vmware/modules/source/

# 重新编译安装
sudo vmware-modconfig --console --install-all
```

### 五、验证安装
```bash
vmplayer -v
# 输出：VMware Player 17.6.3 build-24238078 即正常
```

### 六、常用无界面命令（Server 必备）
```bash
# 后台启动虚拟机
vmrun start "/path/to/xxx.vmx" nogui

# 查看运行中虚拟机
vmrun list

# 停止虚拟机
vmrun stop "/path/to/xxx.vmx" soft

# 内核更新后一键修复 VMware
sudo vmware-modconfig --console --install-all
```

### 七、常见问题
- **报错：Key was rejected by service**
  → 重启进入 BIOS/UEFI，**关闭 Secure Boot**
- **找不到 vmmon/vmnet**
  → 重新执行 **第四步** 补丁修复

---

需要我帮你生成一个**开机自动启动指定虚拟机**的 systemd 服务脚本吗？