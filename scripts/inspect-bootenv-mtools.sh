#!/usr/bin/env bash
set -euo pipefail
pkill -f inspect-simpleaf-bootenv 2>/dev/null || true
sudo losetup -D 2>/dev/null || true

imgxz='/mnt/c/Users/udrdr/fly-lite-armbian-image/Releases/Fly-bian-0.1/Fly-Lite-2.1/Simple-AF/Fly-bian-0.1_Fly-Lite-2.1_Simple-AF.img.xz'
workdir=/tmp/fly-bootenv-inspect
rm -rf "$workdir"
mkdir -p "$workdir"
cd "$workdir"

if ! command -v mtype >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq mtools
fi

echo "xzcat to disk.img..."
xzcat "$imgxz" > disk.img
echo "reading FAT @ offset 4194304..."
mtype -i disk.img@@4194304 ::armbianEnv.txt
echo
echo "--- done armbianEnv ---"
# list sbin on rootfs via debugfs if available
if command -v debugfs >/dev/null; then
  echo "rootfs fly-online / load-8189fs:"
  debugfs -R 'ls -l /usr/local/sbin' disk.img 2>/dev/null | grep -E 'fly-|load-8189' || true
fi
