#!/usr/bin/env bash
# Stage this repo's first-boot + CPU-affinity files into an Armbian userpatches overlay.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
dest=${1:-$root/armbian/userpatches/overlay}

mkdir -p "$dest/cpu-affinity" "$dest/first-boot"
cp -a "$root/klipper/cpu-affinity/." "$dest/cpu-affinity/"
cp -a "$root/first-boot/fly-start.txt" "$root/first-boot/README.txt" "$dest/first-boot/"
# Remove legacy name from overlay if present (apply script still accepts it if left).
rm -f "$dest/first-boot/fly-net.txt"
# swapfile/ lives in userpatches already; do not overwrite it from repo root.
echo "staged overlay -> $dest"
