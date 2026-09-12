#!/bin/bash
# Runs inside the Armbian image customize stage (chroot / nspawn).
# Do not delete /root/.not_logged_in_yet — new users must get the wizard.
set -euo pipefail

echo "Fly Lite 2.1 customize-image: affinity, HDMI, golden overlays, 2G swapfile, hold kernel"

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

# FAT volume (BOOTFS_TYPE=fat → /boot is p1). Put fly-net.txt here so Windows
# sees it after flash. fly-windows-bootfs also labels p1 FLY-SETUP.
install -d /usr/share/fly-debian/first-boot /boot
if [[ -f $OVERLAY/first-boot/fly-net.txt ]]; then
  install -m 0644 "$OVERLAY/first-boot/fly-net.txt" /usr/share/fly-debian/first-boot/fly-net.txt
  install -m 0644 "$OVERLAY/first-boot/fly-net.txt" /boot/fly-net.txt
fi
if [[ -f $OVERLAY/first-boot/README.txt ]]; then
  install -m 0644 "$OVERLAY/first-boot/README.txt" /usr/share/fly-debian/first-boot/README.txt
  install -m 0644 "$OVERLAY/first-boot/README.txt" /boot/README.txt
fi
if [[ -f $OVERLAY/fly-apply-fly-net.sh && -f $OVERLAY/fly-apply-fly-net.service ]]; then
  install -m 0755 "$OVERLAY/fly-apply-fly-net.sh" /usr/local/sbin/fly-apply-fly-net.sh
  install -m 0644 "$OVERLAY/fly-apply-fly-net.service" /etc/systemd/system/fly-apply-fly-net.service
  if command -v systemctl >/dev/null; then
    systemctl enable fly-apply-fly-net.service
  else
    install -d /etc/systemd/system/multi-user.target.wants
    ln -sf /etc/systemd/system/fly-apply-fly-net.service \
      /etc/systemd/system/multi-user.target.wants/fly-apply-fly-net.service
  fi
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

GOLDEN="${OVERLAY}/from-golden"

# Fly DTB (HDMI is disabled in this DTB; fly-lite-hdmi overlay turns it on).
if [[ -f $GOLDEN/boot/sun8i-h3-fly-lite.dtb ]]; then
  install -d /boot/dtb /boot/dtb/sunxi
  install -m 0644 "$GOLDEN/boot/sun8i-h3-fly-lite.dtb" /boot/dtb/sun8i-h3-fly-lite.dtb
  install -m 0644 "$GOLDEN/boot/sun8i-h3-fly-lite.dtb" /boot/dtb/sunxi/sun8i-h3-fly-lite.dtb
fi

# User overlays: mmc-broken-cd, IO, TFT, HDMI. Never load fly-lite-leds (-EBUSY).
install -d /boot/overlay-user
if [[ -d $GOLDEN/overlay-user ]]; then
  for f in "$GOLDEN/overlay-user"/*; do
    [[ -f $f ]] || continue
    case "$(basename "$f")" in
      fly-lite-leds.*) continue ;;
    esac
    install -m 0644 "$f" "/boot/overlay-user/$(basename "$f")"
  done
fi
if [[ -d $OVERLAY/hdmi ]]; then
  for f in "$OVERLAY/hdmi"/*; do
    [[ -f $f ]] || continue
    install -m 0644 "$f" "/boot/overlay-user/$(basename "$f")"
  done
fi
if command -v dtc >/dev/null; then
  for dts in /boot/overlay-user/*.dts; do
    [[ -f $dts ]] || continue
    dtbo="${dts%.dts}.dtbo"
    if [[ ! -f $dtbo ]]; then
      dtc -@ -I dts -O dtb -o "$dtbo" "$dts" || true
    fi
  done
fi

if [[ -f $GOLDEN/firmware/ST7796S.bin ]]; then
  install -d /lib/firmware
  install -m 0644 "$GOLDEN/firmware/ST7796S.bin" /lib/firmware/ST7796S.bin
fi

if [[ -f $GOLDEN/sbin/load-8189fs ]]; then
  install -m 0755 "$GOLDEN/sbin/load-8189fs" /usr/local/sbin/load-8189fs
fi
if [[ -f $GOLDEN/sbin/fly-online-isolated-cpus.sh ]]; then
  install -m 0755 "$GOLDEN/sbin/fly-online-isolated-cpus.sh" \
    /usr/local/sbin/fly-online-isolated-cpus.sh
fi
install -d /etc/systemd/system/multi-user.target.wants
if [[ -f $GOLDEN/systemd/load-8189fs.service ]]; then
  install -m 0644 "$GOLDEN/systemd/load-8189fs.service" \
    /etc/systemd/system/load-8189fs.service
  systemctl enable load-8189fs.service 2>/dev/null || \
    ln -sf /etc/systemd/system/load-8189fs.service \
      /etc/systemd/system/multi-user.target.wants/load-8189fs.service
fi
if [[ -f $GOLDEN/systemd/fly-online-isolated-cpus.service ]]; then
  install -m 0644 "$GOLDEN/systemd/fly-online-isolated-cpus.service" \
    /etc/systemd/system/fly-online-isolated-cpus.service
  systemctl enable fly-online-isolated-cpus.service 2>/dev/null || \
    ln -sf /etc/systemd/system/fly-online-isolated-cpus.service \
      /etc/systemd/system/multi-user.target.wants/fly-online-isolated-cpus.service
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
  if grep -q '^user_overlays=' /boot/armbianEnv.txt; then
    sed -i 's/^user_overlays=.*/user_overlays=mmc-broken-cd fly-lite-io fly-lite-tft fly-lite-hdmi/' \
      /boot/armbianEnv.txt
  else
    echo 'user_overlays=mmc-broken-cd fly-lite-io fly-lite-tft fly-lite-hdmi' >>/boot/armbianEnv.txt
  fi
  if grep -q '^disp_mode=' /boot/armbianEnv.txt; then
    sed -i 's/^disp_mode=.*/disp_mode=800x480p60/' /boot/armbianEnv.txt
  else
    echo 'disp_mode=800x480p60' >>/boot/armbianEnv.txt
  fi
fi

# greetd + agreety: HDMI login without X / LightDM. graphical.target
# otherwise sits on a splash with no greeter (BOOT_LOGO=desktop).
if command -v apt-get >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  if ! apt-get install -y --no-install-recommends greetd; then
    echo "customize-image: greetd not available; leave getty on tty1"
  fi
fi
if [[ -f $OVERLAY/greetd/config.toml ]]; then
  install -d /etc/greetd
  install -m 0644 "$OVERLAY/greetd/config.toml" /etc/greetd/config.toml
fi
if [[ -f $OVERLAY/greetd/tty1.conf ]]; then
  install -d /etc/systemd/system/greetd.service.d
  install -m 0644 "$OVERLAY/greetd/tty1.conf" /etc/systemd/system/greetd.service.d/tty1.conf
fi
if command -v systemctl >/dev/null; then
  systemctl enable greetd.service
  systemctl set-default graphical.target
fi

# Fly-bian SSH splash (replaces Armbian-unofficial figlet in 10-armbian-header)
install -d /usr/share/fly-debian/motd
if [[ -f $OVERLAY/motd/flybian.txt ]]; then
  install -m 0644 "$OVERLAY/motd/flybian.txt" /usr/share/fly-debian/motd/flybian.txt
fi
if [[ -f $OVERLAY/motd/flybian.ansi ]]; then
  install -m 0644 "$OVERLAY/motd/flybian.ansi" /usr/share/fly-debian/motd/flybian.ansi
fi
if [[ -f $OVERLAY/motd/print-flybian.sh ]]; then
  install -m 0755 "$OVERLAY/motd/print-flybian.sh" /usr/share/fly-debian/motd/print-flybian.sh
fi
if [[ -f $OVERLAY/motd/patch-armbian-header.py ]]; then
  install -m 0755 "$OVERLAY/motd/patch-armbian-header.py" \
    /usr/share/fly-debian/motd/patch-armbian-header.py
fi
if [[ -x /usr/share/fly-debian/motd/patch-armbian-header.py && -f /etc/update-motd.d/10-armbian-header ]]; then
  if ! python3 /usr/share/fly-debian/motd/patch-armbian-header.py; then
    echo "customize-image: could not patch 10-armbian-header; install 05-flybian-splash"
    cat >/etc/update-motd.d/05-flybian-splash <<'EOF'
#!/bin/bash
[[ -x /usr/share/fly-debian/motd/print-flybian.sh ]] && /usr/share/fly-debian/motd/print-flybian.sh
EOF
    chmod 0755 /etc/update-motd.d/05-flybian-splash
  fi
fi

if command -v apt-mark >/dev/null; then
  apt-mark hold linux-image-current-sunxi linux-dtb-current-sunxi linux-u-boot-fly-lite-21-current 2>/dev/null || true
  apt-mark hold linux-u-boot-fly-lite-21-simpleaf-current \
    linux-u-boot-fly-lite-21-kiauh-current 2>/dev/null || true
fi

# Flavor bake (Simple-AF or KIAUH). Base fly-lite-21 stays installer-agnostic.
BOARD_ARG="${3:-}"
FLAVOR=""
if [[ -f $OVERLAY/fly-flavor ]]; then
  FLAVOR=$(tr -d '\r\n' <"$OVERLAY/fly-flavor")
fi
if [[ -z $FLAVOR ]]; then
  case "$BOARD_ARG" in
    fly-lite-21-simpleaf) FLAVOR=simpleaf ;;
    fly-lite-21-kiauh) FLAVOR=kiauh ;;
  esac
fi

if [[ -n $FLAVOR && -f $OVERLAY/klipper-stack/fly-bind-klipper-stack.sh ]]; then
  install -m 0755 "$OVERLAY/klipper-stack/fly-bind-klipper-stack.sh" \
    /usr/local/sbin/fly-bind-klipper-stack
  install -m 0644 "$OVERLAY/klipper-stack/fly-bind-klipper-stack.service" \
    /etc/systemd/system/fly-bind-klipper-stack.service
  systemctl enable fly-bind-klipper-stack.service 2>/dev/null || \
    ln -sf /etc/systemd/system/fly-bind-klipper-stack.service \
      /etc/systemd/system/multi-user.target.wants/fly-bind-klipper-stack.service
fi

case "$FLAVOR" in
  simpleaf)
    # shellcheck source=/dev/null
    source "$OVERLAY/simpleaf/bake.sh"
    ;;
  kiauh)
    # shellcheck source=/dev/null
    source "$OVERLAY/kiauh/bake.sh"
    ;;
esac

# Wizard must remain. Never create user fly here.
