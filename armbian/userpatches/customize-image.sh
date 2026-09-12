#!/bin/bash
# Runs inside the Armbian image customize stage (chroot / nspawn).
# Do not delete /root/.not_logged_in_yet — new users must get the wizard.
set -euo pipefail

echo "Fly Lite 2.1 customize-image: affinity, first-boot files, 2G swapfile, hold kernel"

OVERLAY="${OVERLAY:-/tmp/overlay}"

install -d /etc/systemd/system-generators
if [[ -f $OVERLAY/cpu-affinity/fly-klipper-cpu-affinity ]]; then
  install -m 0755 "$OVERLAY/cpu-affinity/fly-klipper-cpu-affinity" \
    /etc/systemd/system-generators/fly-klipper-cpu-affinity
fi
if [[ -f $OVERLAY/cpu-affinity/50-fly-cpu-affinity.conf && -f $OVERLAY/cpu-affinity/units ]]; then
  while read -r unit; do
    [[ -z $unit || $unit == \#* ]] && continue
    install -d "/etc/systemd/system/${unit}.d"
    install -m 0644 "$OVERLAY/cpu-affinity/50-fly-cpu-affinity.conf" \
      "/etc/systemd/system/${unit}.d/50-fly-cpu-affinity.conf"
  done <"$OVERLAY/cpu-affinity/units"
fi

# FAT volume files: customize-image cannot always see FLY-SETUP. The image
# hook in docs/build-named-image.md must also copy these onto p1. Staging here
# keeps a copy in the rootfs for the builder to clone onto FAT.
install -d /usr/share/fly-debian/first-boot
if [[ -f $OVERLAY/first-boot/fly-net.txt ]]; then
  install -m 0644 "$OVERLAY/first-boot/fly-net.txt" /usr/share/fly-debian/first-boot/fly-net.txt
fi
if [[ -f $OVERLAY/first-boot/README.txt ]]; then
  install -m 0644 "$OVERLAY/first-boot/README.txt" /usr/share/fly-debian/first-boot/README.txt
fi

# 2 GiB /swapfile is created on first boot after armbian-resize-filesystem.
# Do not fallocate it here — that would bloat the named image by 2 GiB.
if [[ -f $OVERLAY/swapfile/fly-swapfile.sh && -f $OVERLAY/swapfile/fly-swapfile.service ]]; then
  install -m 0755 "$OVERLAY/swapfile/fly-swapfile.sh" /usr/local/sbin/fly-swapfile.sh
  install -m 0644 "$OVERLAY/swapfile/fly-swapfile.service" /etc/systemd/system/fly-swapfile.service
  if command -v systemctl >/dev/null; then
    systemctl enable fly-swapfile.service
  else
    install -d /etc/systemd/system/multi-user.target.wants
    ln -sf /etc/systemd/system/fly-swapfile.service \
      /etc/systemd/system/multi-user.target.wants/fly-swapfile.service
  fi
fi

if [[ -f /boot/armbianEnv.txt ]]; then
  if ! grep -q '^fdtfile=' /boot/armbianEnv.txt; then
    echo 'fdtfile=sun8i-h3-fly-lite.dtb' >>/boot/armbianEnv.txt
  fi
  if ! grep -q 'maxcpus=1' /boot/armbianEnv.txt; then
    echo 'extraargs=nohz=off clocksource=timer cma=16M maxcpus=1 isolcpus=1-3 irqaffinity=0 cgroup_disable=cpu,cpuacct' >>/boot/armbianEnv.txt
  fi
  if ! grep -q '^console=' /boot/armbianEnv.txt; then
    echo 'console=serial' >>/boot/armbianEnv.txt
  fi
fi

if command -v apt-mark >/dev/null; then
  apt-mark hold linux-image-current-sunxi linux-dtb-current-sunxi linux-u-boot-fly-lite-21-current 2>/dev/null || true
fi

# Wizard must remain. Never create user fly here.
