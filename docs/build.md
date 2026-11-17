# Build and package

The public release cross-compiles Dropbear 2026.94 and libxcrypt 4.4.38 for ARM64. Use Ubuntu 24.04 or its WSL distribution. The launcher needs a statically linked ARM64 executable because the handheld firmware supplies its own system libraries.

```bash
sudo apt-get update
sudo apt-get install -y build-essential gcc-aarch64-linux-gnu libc6-dev-arm64-cross \
    binutils-aarch64-linux-gnu ca-certificates curl gnupg file python3
git clone https://github.com/ohnobug/emuelec-ssh-launcher.git
cd emuelec-ssh-launcher
bash scripts/build.sh
```

The script performs these steps:

1. Fetches the upstream archives and checks their SHA-256 values. It verifies the Dropbear release signature with the pinned upstream key.
2. Builds libxcrypt as an ARM64 static library with SHA-512 crypt enabled.
3. Applies the root password adaptation and builds static `dropbear` and `dropbearkey`. The server takes the optional password from a launcher-supplied hash file. It does not change the firmware password.
4. Strips both executables and checks their ELF architecture and interpreter headers.
5. Produces an installable ARM64 ZIP, a source bundle with the upstream inputs, and `SHA256SUMS` in `dist/`. Compiler output is in `build/`.

A tag matching `VERSION` runs the same build in GitHub Actions, verifies SSH authentication under ARM64 emulation, and attaches the assets to the release. On the handheld, both executables are copied to `/run` before starting. This gives them Unix permissions even when the games card is FAT32.

## 2026-11-17 XF45V build and deployment

The original test used a XiFan XF45V V8-2 Wi-Fi/eMMC with stock 64-bit EmuELEC 4.7.

1. The first Dropbear 2026.94 build used `aarch64-linux-gnu-gcc`, `--enable-static --disable-zlib`, and `make PROGRAMS='dropbear dropbearkey'`. Password authentication and forwarding were disabled for that first key-only build.
2. The second build enabled password authentication and linked ARM64 `libcrypt.a` from Ubuntu's `libcrypt-dev` package, version `1:4.4.36-4build1`. The password check read a separate SHA-512 crypt hash file for the root account. The release now builds libxcrypt from source and uses the same login method.
3. ARM64 user-mode emulation verified the executables and the two authentication modes. The password build was then used to log in as `root` on TCP `2222` over the XF45V's Wi-Fi connection.
4. The games card that worked on this handheld was MBR with a primary FAT32 partition labelled `EEROMS`. The launcher went in `ports_scripts/` at the card root, and the binaries and private configuration went into the matching payload directory under `ports/` at the card root.
5. After safely ejecting the card, it was inserted in the games slot. With Wi-Fi connected, **Ports → Portable-SSH** launched the original test package. The public version shows up as **Start-SSH**. The SSH connection was made using the IP from the handheld's network settings.

[Dropbear source and release signature](https://matt.ucc.asn.au/dropbear/releases/) · [libxcrypt source](https://github.com/besser82/libxcrypt/releases/tag/v4.4.38)
