#!/usr/bin/env bash
# Pull FlyOS-FAST board-support files from a live Fly Lite 2.1.
# Run this on a PC that can reach the board (same LAN or serial-forwarded SSH).
# This cloud workspace cannot see 192.168.1.147.
set -euo pipefail

HOST="${FLYOS_HOST:-192.168.1.147}"
USER="${FLYOS_USER:-root}"
PASS="${FLYOS_PASS:-mellow}"
PORT="${FLYOS_PORT:-22}"

root=$(cd "$(dirname "$0")/.." && pwd)
dest="$root/flyos-artifacts/live"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
work="$dest/pull-$stamp"

ssh_opts=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -p "$PORT")

remote() {
  if [[ -n ${FLYOS_SSH_IDENTITY:-} ]]; then
    ssh "${ssh_opts[@]}" -i "$FLYOS_SSH_IDENTITY" "$USER@$HOST" "$@"
  elif command -v sshpass >/dev/null; then
    sshpass -p "$PASS" ssh "${ssh_opts[@]}" "$USER@$HOST" "$@"
  else
    ssh "${ssh_opts[@]}" "$USER@$HOST" "$@"
  fi
}

remote_copy() {
  local src=$1 dst=$2
  if [[ -n ${FLYOS_SSH_IDENTITY:-} ]]; then
    scp "${ssh_opts[@]}" -i "$FLYOS_SSH_IDENTITY" "$USER@$HOST:$src" "$dst"
  elif command -v sshpass >/dev/null; then
    sshpass -p "$PASS" scp "${ssh_opts[@]}" "$USER@$HOST:$src" "$dst"
  else
    scp "${ssh_opts[@]}" "$USER@$HOST:$src" "$dst"
  fi
}

usage() {
  cat <<EOF
Usage: pull-live-flyos.sh

Environment:
  FLYOS_HOST           default $HOST
  FLYOS_USER           default $USER
  FLYOS_PASS           default official FAST password (used only with sshpass)
  FLYOS_PORT           default $PORT
  FLYOS_SSH_IDENTITY   optional private key; skips password auth

Writes flyos-artifacts/live/pull-<utc>/ and updates flyos-artifacts/live/LATEST
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "connecting to $USER@$HOST:$PORT …"
remote 'echo connected; uname -a; tr -d "\0" </proc/device-tree/model; echo'

mkdir -p "$work"/{dtb,overlays,firmware,klipper-config,etc,proc,boot}

{
  echo "# Live FlyOS pull"
  echo
  echo "- Host: \`$HOST\`"
  echo "- When: $stamp"
  echo
} >"$work/REPORT.md"

section() {
  printf '\n======== %s ========\n' "$1"
}

# Identity and buses
remote 'set +e
echo "======== identity ========"
uname -a
echo "model: $(tr -d "\0" </proc/device-tree/model 2>/dev/null)"
echo "compatible: $(tr "\0" " " </proc/device-tree/compatible 2>/dev/null)"
cat /proc/cmdline
echo
echo "======== memory ========"
free -h
echo
echo "======== block ========"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
echo
echo "======== mmc ========"
ls /sys/bus/mmc/devices 2>/dev/null
for d in /sys/bus/mmc/devices/*; do
  [ -e "$d" ] || continue
  echo "-- $d"
  cat "$d/type" 2>/dev/null
  cat "$d/uevent" 2>/dev/null
done
echo
echo "======== usb ========"
lsusb 2>/dev/null || echo "(no lsusb)"
ls -l /dev/serial/by-id/ 2>/dev/null || true
echo
echo "======== net ========"
ip -br link
ip -br add
echo
echo "======== gpio ========"
command -v gpioinfo >/dev/null && gpioinfo || ls /sys/class/gpio /dev/gpiochip* 2>/dev/null
echo
echo "======== modules ========"
lsmod
echo
echo "======== display ========"
ls /dev/fb* /dev/dri/card* 2>/dev/null || echo "(no fb/drm)"
' >"$work/probe.txt" || true

remote 'dmesg' >"$work/dmesg.txt" || true
remote 'cat /proc/cmdline' >"$work/proc/cmdline" || true
remote 'ls -la /boot /boot/dtb /boot/overlay /boot/overlays /usr/lib/linux-image-* 2>/dev/null; find /boot /usr/lib/firmware /lib/firmware -iname "*.dtb" -o -iname "*.dtbo" 2>/dev/null | head -n 200' >"$work/find-dtb.txt" || true

# Pack device-tree and common FlyOS config locations on the remote, then copy.
remote 'set +e
tmp=/tmp/flyos-pull-$$
mkdir -p "$tmp"
if [ -d /proc/device-tree ]; then
  tar -C /proc -cf "$tmp/device-tree.tar" device-tree
fi
# Boot / DTB / overlays (paths differ across FAST versions)
for d in /boot /boot/dtb /boot/overlay /boot/overlays /usr/lib/linux-image-*; do
  [ -d "$d" ] || continue
  find "$d" -iname "*.dtb" -o -iname "*.dtbo" -o -iname "*.dts" | while read -r f; do
    cp -a "$f" "$tmp/" 2>/dev/null
  done
done
for name in sys-config.conf config.txt armbianEnv.txt FlyOS-Env.txt flyos_net.txt; do
  find / -name "$name" 2>/dev/null | head -n 20 | while read -r f; do
    mkdir -p "$tmp/cfg$(dirname "$f")"
    cp -a "$f" "$tmp/cfg$f" 2>/dev/null
  done
done
# FAST writable trees
for d in /data/printer_data/config /root/printer_data/config /home/fly/printer_data/config /opt/printer_data/config; do
  if [ -d "$d" ]; then
    mkdir -p "$tmp/klipper-config"
    cp -a "$d/." "$tmp/klipper-config/" 2>/dev/null
  fi
done
if [ -d /data/.flyos-config ]; then
  cp -a /data/.flyos-config "$tmp/"
fi
if [ -d /etc/.flyos-config ]; then
  cp -a /etc/.flyos-config "$tmp/etc-flyos-config"
fi
# Wireless firmware that Debian will want
mkdir -p "$tmp/firmware"
for p in /lib/firmware/rtlwifi /lib/firmware/rtl_bt /usr/lib/firmware/rtlwifi; do
  [ -d "$p" ] && cp -a "$p" "$tmp/firmware/" 2>/dev/null
done
find /lib/firmware /usr/lib/firmware -iname "*8189*" -o -iname "*8723*" -o -iname "*8821*" 2>/dev/null \
  | while read -r f; do cp -a "$f" "$tmp/firmware/" 2>/dev/null; done
tar -C "$tmp" -czf /tmp/flyos-pull.tgz .
ls -l /tmp/flyos-pull.tgz
' || true

mkdir -p "$work/remote-pack"
if remote_copy /tmp/flyos-pull.tgz "$work/remote-pack/flyos-pull.tgz"; then
  tar -C "$work/remote-pack" -xzf "$work/remote-pack/flyos-pull.tgz"
  # Promote well-known pieces
  find "$work/remote-pack" -iname '*.dtb' -exec cp -a {} "$work/dtb/" \;
  find "$work/remote-pack" -iname '*.dtbo' -exec cp -a {} "$work/overlays/" \;
  if [[ -d $work/remote-pack/firmware ]]; then
    cp -a "$work/remote-pack/firmware/." "$work/firmware/"
  fi
  if [[ -d $work/remote-pack/klipper-config ]]; then
    cp -a "$work/remote-pack/klipper-config/." "$work/klipper-config/"
  fi
  find "$work/remote-pack" -name 'sys-config.conf' -exec cp -a {} "$work/sys-config.conf" \;
  find "$work/remote-pack" -name 'config.txt' -exec cp -a {} "$work/flyos-conf-config.txt" \;
  if [[ -f $work/remote-pack/device-tree.tar ]]; then
    cp -a "$work/remote-pack/device-tree.tar" "$work/device-tree.tar"
  fi
fi
remote 'rm -f /tmp/flyos-pull.tgz' || true

# Decompile DTB if dtc is available locally
if command -v dtc >/dev/null; then
  mkdir -p "$work/dts"
  for dtb in "$work"/dtb/*.dtb; do
    [[ -f $dtb ]] || continue
    dtc -I dtb -O dts -o "$work/dts/$(basename "$dtb" .dtb).dts" "$dtb" 2>/dev/null || true
  done
fi

{
  echo "## Collected"
  echo
  find "$work" -type f ! -path '*/remote-pack/*' | sed "s|$work/|- |"
  echo
  echo "## Next"
  echo
  echo "1. Diff DTS against flyos-artifacts/reference/sun8i-h3-orangepi-lite.dts"
  echo "2. Copy sys-config.conf values into docs/klipper-pins-and-macros.md section 6/12"
  echo "3. Do not commit printer.cfg if it has secrets; review first"
} >>"$work/REPORT.md"

ln -sfn "pull-$stamp" "$dest/LATEST"
echo "wrote $work"
cat "$work/REPORT.md"
