# EmuELEC 携帯機で SSH を起動する

最初のランチャーは、純正の 64 ビット EmuELEC 4.7 を搭載した XiFan XF45V V8-2 で動作を確認しました。PC に SSH クライアントを用意し、携帯機と PC を同じ LAN に接続します。

## 1. ダウンロード

[Releases → Assets](https://github.com/ohnobug/emuelec-ssh-launcher/releases/latest) から **ARM64 ZIP** をダウンロードし、PC で展開します。確認する場合は、ZIP の SHA-256 を `SHA256SUMS` の該当行と照合します。

## 2. ログイン方法を設定する

ユーザー名は **`root`**、TCP ポートは **`2222`** です。配布パッケージに初期パスワードはありません。次のいずれかを設定します。

**SSH キー。** PC の自分だけが管理するフォルダーで `ssh-keygen -t ed25519 -f emuelec_ed25519` を実行します。`emuelec_ed25519.pub` を展開先の `ports/emuelec-ssh-launcher/` にコピーし、拡張子のない `authorized_keys` に名前を変更します。秘密鍵 `emuelec_ed25519` は PC に保管します。

**パスワード。** Git Bash や WSL など、OpenSSL を使える端末で展開先のルートに移動します。次のコマンドを実行し、画面の指示に従って自分で選んだパスワードを入力します。保存されるのはハッシュです。SSH ではここで設定したパスワードを使います。Wi-Fi と純正システムのパスワードは別です。

~~~sh
openssl passwd -6 > ports/emuelec-ssh-launcher/password.hash
~~~

## 3. ゲームカードにコピーする

携帯機の電源を切り、**ゲーム用カード**を PC に挿します。展開した `ports_scripts` と `ports` をカードのルートにある同名フォルダーに統合します。XF45V では MBR と FAT32 の基本パーティション、ボリューム名 `EEROMS` の構成で確認しました。

~~~text
EEROMS/
├── ports_scripts/Start-SSH.sh
└── ports/emuelec-ssh-launcher/
    ├── dropbear
    ├── dropbearkey
    ├── authorized_keys
    └── password.hash
~~~

使用するログイン方法のファイルを置きます。両方使う場合は両方配置します。カードを安全に取り外し、携帯機のゲーム用スロットに戻します。

## 4. Wi-Fi に接続して SSH を起動する

1. 携帯機の電源を入れ、**Start → Network Settings** を開きます。Wi-Fi を有効にし、SSID を選んで Wi-Fi パスワードを入力します。項目名はファームウェアによって異なる場合があります。
2. 表示された IP アドレスを控えます。PC も同じ LAN に接続します。
3. システム一覧に戻り、**Ports → Start-SSH** を実行します。Ports が表示されない場合はカードの配置を確認し、ゲーム一覧を更新するか EmulationStation を再起動します。
4. SSH は TCP `2222` で待ち受けます。`ports_scripts/Start-SSH.log` に IP アドレスとホスト鍵のフィンガープリントが出力されます。

## 5. PC からログインする

`192.168.1.42` は携帯機の IP アドレスに置き換えます。初回接続時は、SSH が表示するフィンガープリントをログと照合します。

- キーを使う場合は、秘密鍵のあるフォルダーで `ssh -i ./emuelec_ed25519 -p 2222 root@192.168.1.42` を実行します。
- パスワードを使う場合は、`ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -p 2222 root@192.168.1.42` を実行し、手順 2 で設定したパスワードを入力します。

タイムアウト時は Wi-Fi と IP アドレスを確認します。接続を拒否された場合は Start-SSH とログを確認します。認証に失敗したら設定ファイル名とコマンドを見直します。電源を切ると SSH は停止します。次回起動後は Ports から再度実行します。

## 6. 自分でビルドする

Ubuntu 24.04 または WSL で依存パッケージを入れ、リポジトリのルートで実行します。スクリプトはソースと Dropbear の署名を検証し、libxcrypt、Dropbear、dropbearkey を ARM64 向けにビルドします。ZIP、ソースアーカイブ、チェックサムの保存先は `dist/`、ビルドログの保存先は `build/` です。

~~~bash
sudo apt-get update
sudo apt-get install -y build-essential gcc-aarch64-linux-gnu libc6-dev-arm64-cross \
    binutils-aarch64-linux-gnu ca-certificates curl gnupg file python3
bash scripts/build.sh
~~~

[ビルドと XF45V での導入記録](build.md)
