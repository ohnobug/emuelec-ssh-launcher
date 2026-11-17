#!/usr/bin/env bash
set -euo pipefail

project=$(cd -- "$(dirname -- "$0")/.." && pwd)
release=$(cat "$project/VERSION")
zipfile="$project/dist/emuelec-ssh-launcher-$release-arm64.zip"
qemu=${QEMU_AARCH64:-qemu-aarch64-static}
work=$(mktemp -d "$HOME/.emuelec-ssh-test.XXXXXX")
server=
cleanup() {
    local status=$?
    if [[ "$status" -ne 0 && -f "$work/server.log" ]]; then
        cat "$work/server.log" >&2
    fi
    if [[ -n "$server" ]]; then kill "$server" 2>/dev/null || true; fi
    rm -rf -- "$work"
}
trap cleanup EXIT
[[ $(id -u) == 0 ]] || { echo 'Run this test as root to test the root account.' >&2; exit 1; }

python3 -m zipfile -e "$zipfile" "$work"
sh -n "$work/ports_scripts/Start-SSH.sh"
payload="$work/ports/emuelec-ssh-launcher"
chmod +x "$payload/dropbear" "$payload/dropbearkey"
test ! -e "$payload/password.hash"
test ! -e "$payload/authorized_keys"
"$qemu" "$payload/dropbear" -V
"$qemu" "$payload/dropbearkey" -t ed25519 -f "$work/host" >/dev/null
ssh-keygen -q -t ed25519 -N '' -f "$work/client"
mkdir -m 700 "$work/keys"
install -m 600 "$work/client.pub" "$work/keys/authorized_keys"
fingerprint=$("$qemu" "$payload/dropbearkey" -y -f "$work/host" |
    awk '/^ssh-ed25519 / { print $1, $2; exit }')
test -n "$fingerprint"
port=$(python3 - <<'PY'
import socket
with socket.socket() as listener:
    listener.bind(("127.0.0.1", 0))
    print(listener.getsockname()[1])
PY
)
printf '[127.0.0.1]:%s %s\n' "$port" "$fingerprint" >"$work/known_hosts"
args=(-F /dev/null -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=$work/known_hosts"
      -o ConnectTimeout=4 -p "$port")

start_server() {
    "$qemu" "$payload/dropbear" -F -E -r "$work/host" -p "127.0.0.1:$port" \
        -D "$work/keys" -P "$work/pid" "$@" >"$work/server.log" 2>&1 &
    server=$!
    for attempt in 1 2 3 4 5; do
        if grep -q 'Not backgrounding' "$work/server.log"; then return; fi
        if ! kill -0 "$server" 2>/dev/null; then break; fi
        sleep 1
    done
    cat "$work/server.log" >&2
    return 1
}

start_server -s
result=$(ssh "${args[@]}" -o BatchMode=yes -o IdentitiesOnly=yes -i "$work/client" \
    root@127.0.0.1 'printf "key-ok"')
test "$result" = key-ok
echo 'ARM64 SSH key login passed'
kill "$server"
wait "$server" 2>/dev/null || true
server=

export EMUELEC_TEST_PASSWORD
EMUELEC_TEST_PASSWORD=$(openssl rand -hex 24)
printf '%s\n' "$EMUELEC_TEST_PASSWORD" | openssl passwd -6 -stdin >"$work/password.hash"
chmod 600 "$work/password.hash"
export EMUELEC_SSH_HASH_FILE="$work/password.hash"
cat >"$work/askpass" <<'EOF'
#!/bin/sh
printf '%s\n' "$EMUELEC_TEST_PASSWORD"
EOF
chmod 700 "$work/askpass"
export SSH_ASKPASS="$work/askpass" SSH_ASKPASS_REQUIRE=force DISPLAY=:0
start_server
password_args=(-o PreferredAuthentications=password -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1)
result=$(ssh -n "${args[@]}" "${password_args[@]}" root@127.0.0.1 'printf "password-ok"')
test "$result" = password-ok
if EMUELEC_TEST_PASSWORD=incorrect ssh -n "${args[@]}" "${password_args[@]}" \
    root@127.0.0.1 true >"$work/rejected.log" 2>&1; then
    echo 'An incorrect password was accepted.' >&2
    exit 1
fi
grep -q 'Permission denied' "$work/rejected.log"
echo 'ARM64 custom password login and incorrect password rejection passed'
