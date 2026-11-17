# 在 EmuELEC 掌机上启动 SSH

最初的启动器在 XiFan XF45V V8-2 的原厂 64 位 EmuELEC 4.7 上验证过。电脑要有 SSH 客户端，掌机和电脑要在同一个局域网里。

## 1. 下载

打开 [Releases → Assets](https://github.com/ohnobug/emuelec-ssh-launcher/releases/latest)，下载 **ARM64 ZIP** 并在电脑上解压。需要校验时，把 ZIP 的 SHA-256 与同一版本 `SHA256SUMS` 中对应的值比对。

## 2. 设置登录方式

登录账号是 **`root`**，TCP 端口是 **`2222`**。发布包没有预设密码。选下面一种方式配置即可。

**密钥登录。** 在电脑上一个自己保管的目录里运行 `ssh-keygen -t ed25519 -f emuelec_ed25519`。把 `emuelec_ed25519.pub` 复制到解压后的 `ports/emuelec-ssh-launcher/`，改名为 `authorized_keys`，不要带 `.txt` 等扩展名。私钥 `emuelec_ed25519` 留在电脑上。

**密码登录。** 打开带有 OpenSSL 的终端，例如 Windows 的 Git Bash 或 WSL。进入解压目录根目录，运行下面的命令，按提示输入自己设置的密码。命令会生成哈希文件。SSH 登录时输入你刚设置的密码，Wi-Fi 和原厂系统密码各自独立。

~~~sh
openssl passwd -6 > ports/emuelec-ssh-launcher/password.hash
~~~

## 3. 把文件放进游戏卡

关闭掌机，把**游戏卡**插到电脑。将解压后的 `ports_scripts` 和 `ports` 合并到游戏卡根目录，与原有游戏目录同级。XF45V 实测使用的布局是 **MBR + FAT32 主分区**，卷标为 `EEROMS`。

目录应如下。按你选择的方式保留对应的登录文件，也可以同时启用两种方式。

~~~text
EEROMS/
├── ports_scripts/
│   └── Start-SSH.sh
└── ports/
    └── emuelec-ssh-launcher/
        ├── dropbear
        ├── dropbearkey
        ├── authorized_keys        （密钥登录）
        └── password.hash          （密码登录）
~~~

在电脑安全弹出游戏卡，再插回掌机的游戏卡槽。

## 4. 连 Wi-Fi 并启动 SSH

1. 掌机开机，按 **START → 网络设置**，打开 Wi-Fi，选择无线网络（SSID），输入 Wi-Fi 密码。菜单名称可能因固件而异。
2. 等网络设置显示 IP 地址后记下来。电脑也要接入同一个局域网，可以接同一路由器的网线。
3. 返回系统列表，进入 **Ports（移植游戏）→ Start-SSH**。如果找不到 Ports，检查游戏卡目录，再刷新游戏列表或重启 EmulationStation。
4. 启动后会监听 TCP `2222`。游戏卡上的 `ports_scripts/Start-SSH.log` 会记录 IP 和 SSH 主机密钥指纹。

## 5. 在电脑上登录

把下面示例中的 `192.168.1.42` 换成掌机显示的 IP。首次连接时，可把 SSH 提示里的主机密钥指纹和启动日志核对。

- 密钥登录，在保存私钥的目录执行 `ssh -i ./emuelec_ed25519 -p 2222 root@192.168.1.42`。
- 密码登录，执行 `ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -p 2222 root@192.168.1.42`，输入第 2 步设置的密码。

连接超时，检查 Wi-Fi、IP 和路由器是否隔离了设备。连接被拒绝，重新运行 Start-SSH 并查看日志。认证失败，检查登录文件名和所用命令。关机后 SSH 会停止，下次开机时从 Ports 再启动一次。

## 6. 自己编译

在 Ubuntu 24.04（或 WSL）安装下面的依赖，在仓库根目录执行构建命令。脚本校验上游源码和 Dropbear 签名，交叉编译 ARM64 的 libxcrypt、Dropbear 和 dropbearkey，最后把安装包、源码包和校验文件放到 `dist/`。编译日志在 `build/`。

~~~bash
sudo apt-get update
sudo apt-get install -y build-essential gcc-aarch64-linux-gnu libc6-dev-arm64-cross \
    binutils-aarch64-linux-gnu ca-certificates curl gnupg file python3
bash scripts/build.sh
~~~

[2026 年 11 月 17 日的编译和放卡过程](build.md#2026-11-17-xf45v-build-and-deployment)
