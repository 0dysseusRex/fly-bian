#!/bin/bash
# First boot (after rootfs grow): create /swapfile. Do not bake it into the
# image — that would bloat every download.
# Size: FLY_SWAP_MIB from /etc/default/fly-swapfile (default 2048 for Lite).
set -euo pipefail

SWAPFILE=/swapfile
FLY_SWAP_MIB=2048
if [[ -f /etc/default/fly-swapfile ]]; then
  # shellcheck source=/dev/null
  . /etc/default/fly-swapfile
fi
SIZE_BYTES=$((FLY_SWAP_MIB * 1024 * 1024))
NEED=$((SIZE_BYTES + 256 * 1024 * 1024))

avail=$(df -B1 --output=avail / | tail -n 1)
avail=${avail// /}
if [[ -z $avail || $avail -lt $NEED ]]; then
  echo "fly-swapfile: not enough free space on / (avail=${avail:-?} need=$NEED); skip"
  exit 0
fi

if [[ -f $SWAPFILE ]]; then
  cur=$(stat -c %s "$SWAPFILE")
  if [[ $cur -ge $SIZE_BYTES ]]; then
    chmod 600 "$SWAPFILE"
    grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
    swapon --show | grep -q '^/swapfile ' || swapon "$SWAPFILE" || true
    exit 0
  fi
  swapoff "$SWAPFILE" 2>/dev/null || true
  rm -f "$SWAPFILE"
fi

fallocate -l "$SIZE_BYTES" "$SWAPFILE"
chmod 600 "$SWAPFILE"
mkswap "$SWAPFILE"
grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
swapon "$SWAPFILE"
echo "fly-swapfile: $SWAPFILE is ${FLY_SWAP_MIB} MiB ($SIZE_BYTES bytes) and on"
