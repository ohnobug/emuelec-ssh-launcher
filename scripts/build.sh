#!/usr/bin/env bash
set -euo pipefail

project=$(cd -- "$(dirname -- "$0")/.." && pwd)
release=$(cd -- "$project" && cat VERSION)
cache="$project/.cache"
output="$project/dist"
mkdir -p "$cache" "$output" "$project/build"
work=$(mktemp -d)
cleanup() { rm -rf -- "$work"; }
trap cleanup EXIT
jobs=$(nproc)

dropbear=dropbear-2026.94
libxcrypt=libxcrypt-4.4.38
dropbear_url=https://matt.ucc.asn.au/dropbear/releases
libxcrypt_url=https://github.com/besser82/libxcrypt/releases/download/v4.4.38

fetch() {
    local url=$1 filename=${1##*/}
    if [[ ! -f "$cache/$filename" ]]; then
        curl --fail --location --silent --show-error --retry 3 --connect-timeout 15 \
            --output "$cache/$filename.part" "$url"
        mv "$cache/$filename.part" "$cache/$filename"
    fi
}

fetch "$dropbear_url/$dropbear.tar.bz2"
fetch "$dropbear_url/$dropbear.tar.bz2.asc"
fetch "$dropbear_url/dropbear-key-2015.asc"
fetch "$libxcrypt_url/$libxcrypt.tar.xz"
(
    cd "$cache"
    sha256sum -c "$project/scripts/sources.sha256"
)
install -d -m 700 "$work/gnupg"
gpg --homedir "$work/gnupg" --batch --import "$cache/dropbear-key-2015.asc"
fingerprint=$(gpg --homedir "$work/gnupg" --batch --with-colons --fingerprint |
    awk -F: '$1 == "fpr" && !found { print $10; found=1 }')
test "$fingerprint" = F7347EF2EE2E07A267628CA944931494F29C6773
gpg --homedir "$work/gnupg" --batch --verify \
    "$cache/$dropbear.tar.bz2.asc" "$cache/$dropbear.tar.bz2"
tar -xf "$cache/$libxcrypt.tar.xz" -C "$work"
tar -xf "$cache/$dropbear.tar.bz2" -C "$work"

echo "Cross-compiling $libxcrypt for ARM64"
if ! (
    cd "$work/$libxcrypt"
    ./configure --build="$(gcc -dumpmachine)" --host=aarch64-linux-gnu \
        --disable-shared --enable-static --disable-obsolete-api --enable-hashes=sha512crypt \
        --prefix="$work/crypt"
    make -j "$jobs"
    make install
) >"$project/build/libxcrypt.log" 2>&1; then
    tail -n 45 "$project/build/libxcrypt.log" >&2
    exit 1
fi

echo "Cross-compiling $dropbear for ARM64"
if ! (
    cd "$work/$dropbear"
    cp "$project/scripts/localoptions.h" .
    python3 "$project/scripts/use-password-hash.py"
    CPPFLAGS="-I$work/crypt/include" LIBS="$work/crypt/lib/libcrypt.a" \
        ./configure --build="$(gcc -dumpmachine)" --host=aarch64-linux-gnu \
        --enable-static --disable-zlib
    make -j "$jobs" PROGRAMS='dropbear dropbearkey'
    aarch64-linux-gnu-strip dropbear dropbearkey
) >"$project/build/dropbear.log" 2>&1; then
    tail -n 45 "$project/build/dropbear.log" >&2
    exit 1
fi

cp -R "$project/card" "$work/package"
payload="$work/package/ports/emuelec-ssh-launcher"
for binary in dropbear dropbearkey; do
    path="$work/$dropbear/$binary"
    readelf -h "$path" | grep -E 'Machine:[[:space:]]+AArch64'
    if readelf -l "$path" | grep -q INTERP; then
        echo "$binary has an unexpected dynamic interpreter." >&2
        exit 1
    fi
    install -m 755 "$path" "$payload/$binary"
done
install -m 644 "$work/$dropbear/LICENSE" "$payload/Dropbear-LICENSE.txt"
install -m 644 "$work/$libxcrypt/COPYING.LIB" "$payload/libxcrypt-COPYING.LIB"
libc_notice=/usr/share/doc/libc6-dev-arm64-cross/copyright
if [[ -r "$libc_notice" ]]; then
    install -m 644 "$libc_notice" "$payload/glibc-COPYRIGHT.txt"
fi
install -m 644 "$project/LICENSE" "$work/package/LICENSE"
install -m 644 "$project/README.md" "$work/package/README.md"
cp -R "$project/docs" "$work/package/docs"

base="emuelec-ssh-launcher-$release"
(
    cd "$work/package"
    python3 -m zipfile -c "$output/$base-arm64.zip.part" ports ports_scripts README.md LICENSE docs
    python3 -m zipfile -t "$output/$base-arm64.zip.part"
)
mv "$output/$base-arm64.zip.part" "$output/$base-arm64.zip"
mkdir "$work/corresponding-source"
mkdir "$work/corresponding-source/.cache"
cp "$project/VERSION" "$project/LICENSE" "$work/corresponding-source/"
cp -R "$project/scripts" "$project/card" "$work/corresponding-source/"
for filename in "$dropbear.tar.bz2" "$dropbear.tar.bz2.asc" dropbear-key-2015.asc "$libxcrypt.tar.xz"; do
    cp "$cache/$filename" "$work/corresponding-source/.cache/"
done
cp "$project/README.md" "$work/corresponding-source/"
cp -R "$project/docs" "$work/corresponding-source/"
{
    aarch64-linux-gnu-gcc -dumpfullversion
    dpkg-query -W libc6-dev-arm64-cross gcc-aarch64-linux-gnu
    libc_version=$(dpkg-query -W -f='${Version}' libc6-dev-arm64-cross)
    printf 'Ubuntu GNU C Library source: https://launchpad.net/ubuntu/+source/glibc/%s\n' "${libc_version%cross*}"
    echo 'Ubuntu cross toolchain source: https://launchpad.net/ubuntu/+source/cross-toolchain-base'
} >"$work/corresponding-source/BUILD-ENVIRONMENT.txt"
tar -czf "$output/$base-source.tar.gz" -C "$work/corresponding-source" .
(
    cd "$output"
    sha256sum "$base-arm64.zip" "$base-source.tar.gz" > SHA256SUMS
    sha256sum -c SHA256SUMS
)
printf '%s\n' "$output/$base-arm64.zip"
