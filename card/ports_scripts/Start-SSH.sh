#!/bin/sh
set -eu
umask 077

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
payload="$script_dir/../ports/emuelec-ssh-launcher"
run_dir=/run/emuelec-ssh-launcher
state_dir=/storage/.cache/emuelec-ssh-launcher
pidfile="$run_dir/dropbear.pid"
port=2222
log="$script_dir/Start-SSH.log"

exec >"$log" 2>&1

running() {
    [ -s "$pidfile" ] || return 1
    pid=$(cat "$pidfile")
    case "$pid" in ''|*[!0-9]*) return 1 ;; esac
    [ "$(readlink "/proc/$pid/exe" 2>/dev/null)" = "$run_dir/dropbear" ]
}

if [ "$(uname -m)" != aarch64 ] || [ "$(id -u)" != 0 ]; then
    echo 'Start-SSH needs 64-bit ARM and must run as root.'
    exit 1
fi

mkdir -p "$run_dir" "$state_dir"
chmod 700 "$run_dir" "$state_dir"

if ! running; then
    lock="$run_dir/start.lock"
    if ! mkdir "$lock" 2>/dev/null; then
        echo 'Another startup is in progress. Check the log or reboot before retrying.'
        exit 1
    fi
    trap 'rmdir "$lock"' EXIT

    mkdir -p "$run_dir/keys"
    chmod 700 "$run_dir/keys"
    rm -f "$run_dir/keys/authorized_keys" "$run_dir/password.hash"

    key_enabled=0
    if [ -s "$payload/authorized_keys" ] &&
        grep -Eq '^[[:space:]]*(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521))[[:space:]]+[A-Za-z0-9+/=]+' "$payload/authorized_keys"
    then
        tr -d '\r' <"$payload/authorized_keys" >"$run_dir/keys/authorized_keys"
        chmod 600 "$run_dir/keys/authorized_keys"
        key_enabled=1
    fi

    password_enabled=0
    if [ -s "$payload/password.hash" ]; then
        tr -d '\r' <"$payload/password.hash" >"$run_dir/password.hash"
        if ! grep -Eq '^\$6\$(rounds=[0-9]+\$)?[./A-Za-z0-9]{1,16}\$[./A-Za-z0-9]{86}$' "$run_dir/password.hash"; then
            echo 'Invalid password.hash. Generate one with openssl passwd -6.'
            exit 1
        fi
        chmod 600 "$run_dir/password.hash"
        export EMUELEC_SSH_HASH_FILE="$run_dir/password.hash"
        password_enabled=1
    fi

    if [ "$key_enabled" -eq 0 ] && [ "$password_enabled" -eq 0 ]; then
        echo 'Configure authorized_keys or password.hash in ports/emuelec-ssh-launcher first.'
        exit 1
    fi

    cp "$payload/dropbear" "$payload/dropbearkey" "$run_dir/"
    chmod 700 "$run_dir/dropbear" "$run_dir/dropbearkey"
    host_key="$state_dir/host_ed25519"
    if [ ! -s "$host_key" ]; then
        "$run_dir/dropbearkey" -t ed25519 -f "$host_key"
    fi

    set -- "$run_dir/dropbear" -F -E -r "$host_key" -p "0.0.0.0:$port" \
        -D "$run_dir/keys" -P "$pidfile"
    if [ "$password_enabled" -eq 0 ]; then set -- "$@" -s; fi
    (
        trap '' HUP
        if command -v setsid >/dev/null 2>&1; then exec setsid "$@"; fi
        exec "$@"
    ) </dev/null &

    for delay in 1 2 3 4 5; do
        if running; then break; fi
        sleep 1
    done
fi

if ! running; then
    echo 'Dropbear did not stay running. Check the messages above for the cause.'
    exit 1
fi

printf 'Portable SSH is running on TCP %s. Login as root.\n' "$port"
"$run_dir/dropbearkey" -y -f "$state_dir/host_ed25519"
if command -v ip >/dev/null 2>&1; then ip -4 addr show scope global; fi
