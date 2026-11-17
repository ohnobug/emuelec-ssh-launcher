# Set up SSH on an EmuELEC handheld

The original launcher was used on a XiFan XF45V V8-2 running stock 64-bit EmuELEC 4.7. The computer needs an SSH client, and the handheld and computer must be on the same local network.

## 1. Download

Download the **ARM64 ZIP** under [Releases → Assets](https://github.com/ohnobug/emuelec-ssh-launcher/releases/latest) and extract it on your computer. Compare the ZIP's SHA-256 with the line for that file in `SHA256SUMS` if you want to verify the download.

## 2. Configure login

The account is **`root`** and the TCP port is **`2222`**. The release has no preset password. Choose one of these methods.

**SSH key.** In a private folder on your computer, run `ssh-keygen -t ed25519 -f emuelec_ed25519`. Copy `emuelec_ed25519.pub` to the extracted `ports/emuelec-ssh-launcher/` folder and name it `authorized_keys` with no extension. Keep `emuelec_ed25519`, the private key, on your computer.

**Password.** Open a terminal with OpenSSL, such as Git Bash, WSL, macOS Terminal, or a Linux terminal. From the extracted ZIP's root, run the command below and enter a password of your choice at the prompt. This creates a hash file. Use the password you entered to log in. It is separate from the Wi-Fi password and the firmware password.

~~~sh
openssl passwd -6 > ports/emuelec-ssh-launcher/password.hash
~~~

## 3. Put the files on the games card

With the handheld off, insert its **games card** into the computer. Merge the extracted `ports_scripts` and `ports` folders into the root of that card, next to the existing game folders. The layout tested on the XF45V was an MBR card with a primary FAT32 partition labelled `EEROMS`.

The paths should look like this. Keep either credential file, or both if you intentionally enabled both login methods.

~~~text
EEROMS/
├── ports_scripts/
│   └── Start-SSH.sh
└── ports/
    └── emuelec-ssh-launcher/
        ├── dropbear
        ├── dropbearkey
        ├── authorized_keys        (key login)
        └── password.hash          (password login)
~~~

Safely eject the card and put it back in the handheld's games slot.

## 4. Connect to Wi-Fi and start SSH

1. Turn on the handheld. Press **Start → Network Settings**, enable Wi-Fi, select your SSID and enter its Wi-Fi password. Menu names can vary by firmware.
2. Wait for an IP address to appear and note it. Connect your computer to the same local network. The computer can use Ethernet if it is on the same LAN.
3. Return to the system list and choose **Ports → Start-SSH**. If Ports is missing, refresh the game list or restart EmulationStation after checking the card layout.
4. Start-SSH opens TCP `2222`. The launcher writes `ports_scripts/Start-SSH.log` on the card with the IP and host key fingerprint.

## 5. Log in

Replace `192.168.1.42` with the IP shown on your handheld. On the first connection, compare the SSH prompt's host key fingerprint with the launch log.

- Key login from the computer folder that contains your private key: `ssh -i ./emuelec_ed25519 -p 2222 root@192.168.1.42`
- Password login: `ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -p 2222 root@192.168.1.42`. Enter the password you chose in step 2.

If the connection times out, check Wi-Fi, the IP address and whether your network isolates clients. If it is refused, run Start-SSH and check its log. If authentication fails, check the credential filename and the selected SSH command. The service stops when the handheld is turned off. Run Start-SSH again after reboot.

[Build from source](build.md)
