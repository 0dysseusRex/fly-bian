#!/bin/bash
# First boot (after rootfs grow): 2 GiB /swapfile. Do not bake this into the
# image file — that would add 2 GiB to every download.
set -euo pipefail

SWAPFILE=/swapfile
SIZE_BYTES=$((2 * 1024 * 1024 * 1024))
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
echo "fly-swapfile: $SWAPFILE is $SIZE_BYTES bytes and on"
