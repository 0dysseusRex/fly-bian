#!/usr/bin/env bash
# Extract board-support files from an official Mellow H3 FlyOS image.
# Run on a Linux PC. Needs sudo for loop mounts.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: extract-flyos.sh <FlyOS_h3_image.img|*.img.xz|*.img.zip>

Writes out/flyos-extract/{dtb,overlays,firmware,modules,REPORT.md}

The Lite 2.1 shares the H3 FlyOS family image with MiniPad / Lite2.
You want DTB, overlays, and wireless firmware — not the FAST rootfs.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

src=$1
if [[ ! -f $src ]]; then
  echo "image not found: $src" >&2
  exit 1
fi

root=$(cd "$(dirname "$0")/.." && pwd)
out=$root/out/flyos-extract
work=$(mktemp -d)
cleanup() {
  if [[ -n ${bootmnt:-} && -d $bootmnt ]]; then
    sudo umount "$bootmnt" 2>/dev/null || true
  fi
  if [[ -n ${rootmnt:-} && -d $rootmnt ]]; then
    sudo umount "$rootmnt" 2>/dev/null || true
  fi
  if [[ -n ${loop:-} ]]; then
    sudo losetup -d "$loop" 2>/dev/null || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

mkdir -p "$out"/{dtb,overlays,firmware,modules}
img=$work/flyos.img

case $src in
  *.xz) xz -dc "$src" >"$img" ;;
  *.zip)
    unzip -p "$src" '*.img' >"$img" 2>/dev/null || unzip -p "$src" >"$img"
    ;;
  *) cp "$src" "$img" ;;
esac

loop=$(sudo losetup -fP --show "$img")
bootmnt=$work/boot
rootmnt=$work/root
mkdir -p "$bootmnt" "$rootmnt"

# FlyOS images usually have a small FAT boot and an ext4 root.
# Try labeled mounts first, then partition order.
mounted_boot=0
mounted_root=0
for part in "$loop"p*; do
  [[ -b $part ]] || continue
  fstype=$(lsblk -no FSTYPE "$part" || true)
  label=$(lsblk -no LABEL "$part" || true)
  if [[ $mounted_boot -eq 0 && ( $fstype == vfat || $fstype == fat || $label == *BOOT* || $label == *boot* ) ]]; then
    sudo mount -o ro "$part" "$bootmnt" && mounted_boot=1
    continue
  fi
  if [[ $mounted_root -eq 0 && ( $fstype == ext4 || $fstype == ext2 || $label == *root* || $label == *ROOT* ) ]]; then
    sudo mount -o ro "$part" "$rootmnt" && mounted_root=1
  fi
done

if [[ $mounted_boot -eq 0 ]]; then
  echo "could not mount a FAT boot partition from $src" >&2
  lsblk "$loop" >&2 || true
  exit 1
fi

sudo find "$bootmnt" -iname '*.dtb' -exec cp -v {} "$out/dtb/" \;
sudo find "$bootmnt" \( -iname '*.dtbo' -o -iname '*.dts' \) -exec cp -v {} "$out/overlays/" \;
# Common FlyOS / Armbian boot metadata
for name in armbianEnv.txt orangepiEnv.txt FlyOS-Env.txt flyos_net.txt sys-config.conf config.txt; do
  sudo find "$bootmnt" -name "$name" -exec cp -v {} "$out/" \;
done

if [[ $mounted_root -eq 1 ]]; then
  if [[ -d $rootmnt/lib/firmware ]]; then
    sudo cp -a "$rootmnt/lib/firmware/rtlwifi" "$out/firmware/" 2>/dev/null || true
    sudo cp -a "$rootmnt/lib/firmware/rtl_bt" "$out/firmware/" 2>/dev/null || true
    sudo find "$rootmnt/lib/firmware" -iname '*8189*' -o -iname '*8723*' -o -iname '*8821*' \
      | while read -r f; do sudo cp -v "$f" "$out/firmware/"; done
  fi
  sudo find "$rootmnt/lib/modules" -iname '*8189*' -o -iname '*8723*' -o -iname '*brcmfmac*' \
    | head -n 50 \
    | while read -r f; do sudo cp -v --parents "$f" "$out/modules/" 2>/dev/null || sudo cp -v "$f" "$out/modules/"; done
fi

sudo chown -R "$(id -u):$(id -g)" "$out"

{
  echo "# FlyOS H3 extract"
  echo
  echo "- Source: \`$src\`"
  echo "- Date: $(date -Iseconds)"
  echo
  echo "## DTB files"
  echo
  find "$out/dtb" -type f | sed 's/^/- /'
  echo
  echo "## Overlays"
  echo
  find "$out/overlays" -type f | sed 's/^/- /'
  echo
  echo "## Firmware"
  echo
  find "$out/firmware" -type f | sed 's/^/- /'
  echo
  echo "## Next"
  echo
  echo 'Decompile the closest DTB and diff MMC1, USB, HDMI, SPI, UART against `sun8i-h3-orangepi-lite.dts`:'
  echo
  echo '```'
  echo "dtc -I dtb -O dts -o /tmp/fly.dts $out/dtb/*.dtb"
  echo '```'
} >"$out/REPORT.md"

echo "wrote $out/REPORT.md"
cat "$out/REPORT.md"
