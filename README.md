# EmuELEC SSH Launcher

Start a portable Dropbear SSH server from the **Ports** menu on an EmuELEC handheld. The launcher uses the games card and generates a host key on the handheld.

[简体中文](docs/zh-CN.md) · [English](docs/en.md) · [Русский](docs/ru.md) · [日本語](docs/ja.md) · [한국어](docs/ko.md) · [Español](docs/es.md)

| Setting | Value |
|---|---|
| Tested handheld | XiFan XF45V V8-2 Wi-Fi/eMMC, stock 64-bit EmuELEC 4.7 |
| Username | `root` |
| Port | TCP `2222` |
| Login | Your SSH key or a password you set. The release has no preset password. |
| Network | Connect the handheld to Wi-Fi and put the computer on the same local network. |

1. Download the **ARM64 ZIP** from [Releases](https://github.com/ohnobug/emuelec-ssh-launcher/releases/latest).
2. Extract it on your computer and configure [a key or password](docs/en.md#2-configure-login).
3. Merge `ports_scripts` and `ports` into the root of the EmuELEC games card.
4. Connect the handheld to Wi-Fi in **Start → Network Settings** and note its IP address.
5. Open **Ports → Start-SSH** and connect with `ssh -p 2222 root@192.168.1.42`. Replace the example IP with the handheld's IP. For a key with a custom filename, pass `-i` as shown in the guide.

Keep the service on your local network. Turn the handheld off when you finish. Other models need a 64-bit ARM kernel and an EmuELEC Ports launcher that runs as root.

[Build from source](docs/build.md) · [2026-11-17 build and card deployment record](docs/build.md#2026-11-17-xf45v-build-and-deployment)
