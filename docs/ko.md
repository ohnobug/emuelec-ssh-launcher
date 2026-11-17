# EmuELEC 휴대용 게임기에서 SSH 시작하기

초기 실행기는 순정 64비트 EmuELEC 4.7이 설치된 XiFan XF45V V8-2에서 확인했습니다. 컴퓨터에 SSH 클라이언트가 필요하며, 게임기와 컴퓨터는 같은 로컬 네트워크에 있어야 합니다.

## 1. 다운로드

[Releases → Assets](https://github.com/ohnobug/emuelec-ssh-launcher/releases/latest)에서 **ARM64 ZIP**을 내려받아 컴퓨터에서 압축을 풉니다. 파일을 확인하려면 ZIP의 SHA-256을 `SHA256SUMS`의 해당 값과 비교합니다.

## 2. 로그인 설정

사용자 이름은 **`root`**, TCP 포트는 **`2222`**입니다. 배포본에는 미리 설정된 암호가 없습니다. 아래 방법 중 하나를 설정합니다.

**SSH 키.** 컴퓨터의 개인 폴더에서 `ssh-keygen -t ed25519 -f emuelec_ed25519`를 실행합니다. `emuelec_ed25519.pub`를 압축을 푼 `ports/emuelec-ssh-launcher/` 폴더로 복사한 뒤 확장자 없이 `authorized_keys`로 이름을 바꿉니다. 개인 키인 `emuelec_ed25519`는 컴퓨터에 보관합니다.

**암호.** Git Bash나 WSL처럼 OpenSSL을 사용할 수 있는 터미널에서 압축을 푼 최상위 폴더로 이동합니다. 아래 명령을 실행하고 사용할 암호를 입력합니다. 파일에는 해시가 저장됩니다. SSH에는 여기서 설정한 암호를 사용합니다. Wi-Fi 암호와 순정 시스템 암호는 별개입니다.

~~~sh
openssl passwd -6 > ports/emuelec-ssh-launcher/password.hash
~~~

## 3. 게임 카드에 복사

게임기의 전원을 끄고 **게임용 카드**를 컴퓨터에 연결합니다. 압축을 푼 `ports_scripts`와 `ports`를 카드 최상위의 같은 이름 폴더에 합칩니다. XF45V에서는 MBR과 FAT32 기본 파티션, 볼륨 이름 `EEROMS`인 구성으로 확인했습니다.

~~~text
EEROMS/
├── ports_scripts/Start-SSH.sh
└── ports/emuelec-ssh-launcher/
    ├── dropbear
    ├── dropbearkey
    ├── authorized_keys
    └── password.hash
~~~

선택한 로그인에 필요한 파일을 넣습니다. 두 방식을 쓰려면 두 파일을 모두 넣습니다. 카드를 안전하게 꺼내 게임기의 게임 카드 슬롯에 다시 넣습니다.

## 4. Wi-Fi 연결과 SSH 시작

1. 게임기의 전원을 켜고 **Start → Network Settings**를 엽니다. Wi-Fi를 켜고 SSID를 선택한 다음 Wi-Fi 암호를 입력합니다. 메뉴 이름은 펌웨어에 따라 다를 수 있습니다.
2. 화면에 표시되는 IP 주소를 기록합니다. 컴퓨터도 같은 로컬 네트워크에 연결합니다.
3. 시스템 목록으로 돌아가 **Ports → Start-SSH**를 실행합니다. Ports가 보이지 않으면 카드의 파일 구조를 확인하고 게임 목록을 갱신하거나 EmulationStation을 다시 시작합니다.
4. SSH는 TCP `2222`에서 연결을 기다립니다. `ports_scripts/Start-SSH.log`에 IP 주소와 호스트 키 지문이 기록됩니다.

## 5. 컴퓨터에서 로그인

`192.168.1.42`를 게임기의 IP 주소로 바꿉니다. 처음 연결할 때 SSH에 표시되는 호스트 키 지문이 로그와 일치하는지 확인합니다.

- 키 로그인은 개인 키가 있는 폴더에서 `ssh -i ./emuelec_ed25519 -p 2222 root@192.168.1.42`를 실행합니다.
- 암호 로그인은 `ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -p 2222 root@192.168.1.42`를 실행하고 2단계에서 정한 암호를 입력합니다.

연결 시간이 초과되면 Wi-Fi와 IP 주소를 확인합니다. 연결이 거부되면 Start-SSH를 실행하고 로그를 확인합니다. 인증에 실패하면 설정 파일 이름과 명령을 확인합니다. 전원을 끄면 SSH가 종료되며, 다음 부팅 뒤 Ports에서 다시 실행하면 됩니다.

## 6. 직접 빌드

Ubuntu 24.04 또는 WSL에서 의존성을 설치한 뒤 저장소 최상위 폴더에서 실행합니다. 스크립트는 소스와 Dropbear 서명을 검증하고 libxcrypt, Dropbear, dropbearkey를 ARM64로 빌드합니다. ZIP, 소스 묶음, 체크섬은 `dist/`에 저장되며 로그는 `build/`에서 확인할 수 있습니다.

~~~bash
sudo apt-get update
sudo apt-get install -y build-essential gcc-aarch64-linux-gnu libc6-dev-arm64-cross \
    binutils-aarch64-linux-gnu ca-certificates curl gnupg file python3
bash scripts/build.sh
~~~

[빌드와 XF45V에 설치한 기록](build.md)
