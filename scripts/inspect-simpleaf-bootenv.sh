#!/usr/bin/env bash
set -euo pipefail
imgxz='/mnt/c/Users/udrdr/fly-lite-armbian-image/Releases/Fly-bian-0.1/Fly-Lite-2.1/Simple-AF/Fly-bian-0.1_Fly-Lite-2.1_Simple-AF.img.xz'
tmpdir=$(mktemp -d /tmp/flyimg.XXXXXX)
trap 'sudo umount "$tmpdir/bootmnt" 2>/dev/null || true; sudo losetup -D 2>/dev/null || true; rm -rf "$tmpdir"' EXIT
cd "$tmpdir"
mkdir -p bootmnt
echo "decompressing..."
xzcat "$imgxz" > disk.img
fdisk -l disk.img
sudo losetup -Pf --show disk.img | tee loopdev
loop=$(cat loopdev)
sleep 1
ls -l "${loop}"* || true
if [ -b "${loop}p1" ]; then
  sudo mount -o ro "${loop}p1" bootmnt
else
  echo "no p1"
  exit 1
fi
echo '=== armbianEnv.txt ==='
cat bootmnt/armbianEnv.txt
echo
echo '=== online cpus scripts on rootfs? ==='
# also mount root briefly
mkdir -p rootmnt
sudo mount -o ro "${loop}p2" rootmnt
ls -la rootmnt/usr/local/sbin/fly-online* rootmnt/etc/systemd/system/fly-online* 2>&1 | head -n 20
grep -n maxcpus rootmnt/boot/armbianEnv.txt 2>/dev/null || true
# sometimes boot files also on ext4 /boot
if [ -f rootmnt/boot/armbianEnv.txt ]; then
  echo '=== rootmnt/boot/armbianEnv.txt ==='
  cat rootmnt/boot/armbianEnv.txt
fi
echo '=== cmdline from /proc not available; check boot.cmd snippet ==='
grep -n extraargs bootmnt/boot.cmd 2>/dev/null | head || true
