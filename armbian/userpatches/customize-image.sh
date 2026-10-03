#!/bin/bash
# Runs inside the Armbian image customize stage (chroot / nspawn).
# Do not delete /root/.not_logged_in_yet — new users must get the wizard.
set -euo pipefail

echo "Fly Lite 2.1 customize-image: affinity, HDMI, golden overlays, 2G swapfile, hold kernel"

OVERLAY="${OVERLAY:-/tmp/overlay}"

# Product identity (Fly-bian version + release stem). See docs/image-naming.md.
install -d /etc/fly-debian
FLYBIAN_VER=0.1
if [[ -f $OVERLAY/FLYBIAN_VERSION ]]; then
  FLYBIAN_VER=$(tr -d '[:space:]' <"$OVERLAY/FLYBIAN_VERSION")
fi
printf '%s\n' "$FLYBIAN_VER" >/etc/fly-debian/flybian-version
DEVICE_TOKEN=Fly-Lite-2.1
FLAVOR_TOKEN=Base
if [[ -f $OVERLAY/fly-flavor ]]; then
  case "$(tr -d '[:space:]' <"$OVERLAY/fly-flavor")" in
    simpleaf) FLAVOR_TOKEN=Simple-AF ;;
    kiauh) FLAVOR_TOKEN=KIAUH ;;
    *) FLAVOR_TOKEN=Base ;;
  esac
fi
printf 'Fly-bian-%s_%s_%s\n' "$FLYBIAN_VER" "$DEVICE_TOKEN" "$FLAVOR_TOKEN" \
  >/etc/fly-debian/flybian-image

# Static CPUAffinity drop-ins only — do NOT install a systemd generator.
# fly-klipper-cpu-affinity as a generator OOMs this 512 MB board during early
# boot (COMM truncates to fly-klipper-cpu; create_pipe2 / irqs disabled).
if [[ -f $OVERLAY/cpu-affinity/50-fly-cpu-affinity.conf && -f $OVERLAY/cpu-affinity/units ]]; then
  while read -r unit; do
    [[ -z $unit || $unit == \#* ]] && continue
    install -d "/etc/systemd/system/${unit}.d"
    install -m 0644 "$OVERLAY/cpu-affinity/50-fly-cpu-affinity.conf" \
      "/etc/systemd/system/${unit}.d/50-fly-cpu-affinity.conf"
  done <"$OVERLAY/cpu-affinity/units"
fi
# Remove a generator left from older images if the overlay still ships the file.
rm -f /etc/systemd/system-generators/fly-klipper-cpu-affinity 2>/dev/null || true

# FAT volume (BOOTFS_TYPE=fat → /boot is p1). Put fly-start.txt here so Windows
# sees it after flash. fly-windows-bootfs also labels p1 FLY-SETUP.
install -d /usr/share/fly-debian/first-boot /boot
if [[ -f $OVERLAY/first-boot/fly-start.txt ]]; then
  install -m 0644 "$OVERLAY/first-boot/fly-start.txt" /usr/share/fly-debian/first-boot/fly-start.txt
  install -m 0644 "$OVERLAY/first-boot/fly-start.txt" /boot/fly-start.txt
elif [[ -f $OVERLAY/first-boot/fly-net.txt ]]; then
  # Legacy filename during transition
  install -m 0644 "$OVERLAY/first-boot/fly-net.txt" /usr/share/fly-debian/first-boot/fly-start.txt
  install -m 0644 "$OVERLAY/first-boot/fly-net.txt" /boot/fly-start.txt
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
install -d /boot/overlay-use
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
# TFT overlays (panel + Cap GT911 companion). Prefer overlay/tft sources.
if [[ -d $OVERLAY/tft ]]; then
  for f in "$OVERLAY/tft"/*; do
    [[ -f $f ]] || continue
    install -m 0644 "$f" "/boot/overlay-user/$(basename "$f")"
  done
fi
if command -v dtc >/dev/null; then
  for dts in /boot/overlay-user/*.dts; do
    [[ -f $dts ]] || continue
    dtbo="${dts%.dts}.dtbo"
    dtc -@ -I dts -O dtb -o "$dtbo" "$dts" || true
  done
fi

if [[ -f $GOLDEN/firmware/ST7796S.bin ]]; then
  install -d /lib/firmware
  install -m 0644 "$GOLDEN/firmware/ST7796S.bin" /lib/firmware/ST7796S.bin
fi

# panel-mipi-dbi does not autoload from modalias spi:ST7796S; Cap needs goodix_ts.
install -d /etc/modules-load.d
printf '%s\n' panel-mipi-dbi goodix_ts >/etc/modules-load.d/fly-tft.conf

if [[ -f $GOLDEN/sbin/load-8189fs ]]; then
  install -m 0755 "$GOLDEN/sbin/load-8189fs" /usr/local/sbin/load-8189fs
fi
if [[ -f $OVERLAY/network/fly-disable-wlan1.sh ]]; then
  install -m 0755 "$OVERLAY/network/fly-disable-wlan1.sh" \
    /usr/local/sbin/fly-disable-wlan1.sh
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
  # fly-lite-tft-c: Cap DIP GT911 (disables ADS7846). Omit for Resi DIP.
  if grep -q '^user_overlays=' /boot/armbianEnv.txt; then
    sed -i 's/^user_overlays=.*/user_overlays=mmc-broken-cd fly-lite-io fly-lite-tft fly-lite-tft-c fly-lite-hdmi/' \
      /boot/armbianEnv.txt
  else
    echo 'user_overlays=mmc-broken-cd fly-lite-io fly-lite-tft fly-lite-tft-c fly-lite-hdmi' >>/boot/armbianEnv.txt
  fi
  if grep -q '^disp_mode=' /boot/armbianEnv.txt; then
    sed -i 's/^disp_mode=.*/disp_mode=800x480p60/' /boot/armbianEnv.txt
  else
    echo 'disp_mode=800x480p60' >>/boot/armbianEnv.txt
  fi
fi

# Console login: multi-user + getty on tty1 until Simple-AF bind.
# greetd fought touch UIs, crashed on large MOTD, and left HDMI stuck
# on graphical.target. Prefer GrumpyScreen (fbdev, ARMv7) over
# KlipperScreen (X/Mesa) on this 512 MB board — KS installs OOM.
# fly-start ENABLE_GRUMPYSCREEN enables grumpyscreen and frees tty1.
# fly-ip-announce prints wlan0 IPv4 on consoles after network-online.
if command -v apt-get >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends locales openssh-server || true
  # Minimal images ship LANG=en_US.UTF-8 but only C.utf8 compiled.
  if [[ -f /etc/locale.gen ]]; then
    sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen en_US.UTF-8 || true
    update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 || true
  fi
  # Moonraker machine endpoints need the DBus PolKit interface.
  apt-get install -y --no-install-recommends polkitd || true
  # Plymouth for optional early-boot splash (Simple-AF theme baked in flavor bake).
  apt-get install -y --no-install-recommends plymouth plymouth-themes unzip || true
  # Cap touch / TFT diagnostics (GT911 on i2c2).
  apt-get install -y --no-install-recommends i2c-tools || true
fi
# Host keys must exist before first boot or ssh.service crash-loops.
if command -v ssh-keygen >/dev/null; then
  ssh-keygen -A
fi
for motd_heavy in 30-armbian-sysinfo 35-armbian-tips 41-armbian-config \
  30-armbian-updates 40-armbian-messages; do
  [[ -f /etc/update-motd.d/$motd_heavy ]] && chmod a-x "/etc/update-motd.d/$motd_heavy" || true
done
# 512 MB + maxcpus=1: Armbian's @reboot apt simulate (armbian-apt-updates)
# OOMs during first boot (COMM truncates to armbian-apt-upd). MOTD update
# counts stay empty; run apt manually when the board is idle with swap up.
rm -f /etc/cron.d/armbian-updates 2>/dev/null || true
if [[ -x /usr/lib/armbian/armbian-apt-updates ]]; then
  chmod a-x /usr/lib/armbian/armbian-apt-updates || true
fi
if command -v systemctl >/dev/null; then
  systemctl disable --now apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
  systemctl mask apt-daily.service apt-daily-upgrade.service 2>/dev/null || true
fi
rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true
if command -v systemctl >/dev/null; then
  systemctl disable greetd.service 2>/dev/null || true
  systemctl set-default multi-user.target
  systemctl enable getty@tty1.service 2>/dev/null || true
fi
echo "customize-image: console -> getty@tty1, multi-user.target (no greetd; no @reboot apt)"

if [[ -f $OVERLAY/network/fly-ip-announce.sh && -f $OVERLAY/network/fly-ip-announce.service ]]; then
  install -m 0755 "$OVERLAY/network/fly-ip-announce.sh" \
    /usr/local/sbin/fly-ip-announce.sh
  install -m 0644 "$OVERLAY/network/fly-ip-announce.service" \
    /etc/systemd/system/fly-ip-announce.service
  if command -v systemctl >/dev/null; then
    systemctl enable fly-ip-announce.service
  else
    mkdir -p /etc/systemd/system/multi-user.target.wants
    ln -sf /etc/systemd/system/fly-ip-announce.service \
      /etc/systemd/system/multi-user.target.wants/fly-ip-announce.service
  fi
fi

# After multi-user.target: print "Boot Complete" on consoles.
if [[ -f $OVERLAY/boot/fly-boot-complete.sh && -f $OVERLAY/boot/fly-boot-complete.service ]]; then
  install -m 0755 "$OVERLAY/boot/fly-boot-complete.sh" \
    /usr/local/sbin/fly-boot-complete.sh
  install -m 0644 "$OVERLAY/boot/fly-boot-complete.service" \
    /etc/systemd/system/fly-boot-complete.service
  if [[ -f $OVERLAY/boot/plymouth-quit-wait-fly.conf ]]; then
    install -d /etc/systemd/system/plymouth-quit.service.d
    install -d /etc/systemd/system/plymouth-quit-wait.service.d
    install -m 0644 "$OVERLAY/boot/plymouth-quit-wait-fly.conf" \
      /etc/systemd/system/plymouth-quit.service.d/wait-fly.conf
    install -m 0644 "$OVERLAY/boot/plymouth-quit-wait-fly.conf" \
      /etc/systemd/system/plymouth-quit-wait.service.d/wait-fly.conf
  fi
  if command -v systemctl >/dev/null; then
    systemctl enable fly-boot-complete.service
  else
    mkdir -p /etc/systemd/system/default.target.wants
    ln -sf /etc/systemd/system/fly-boot-complete.service \
      /etc/systemd/system/default.target.wants/fly-boot-complete.service
  fi
fi

# SSH helpers: help, guided start, cameras, GrumpyScreen, boot display, KIAUH
if [[ -f $OVERLAY/tools/fly-help ]]; then
  install -m 0755 "$OVERLAY/tools/fly-help" /usr/local/bin/fly-help
fi
if [[ -f $OVERLAY/tools/fly-start ]]; then
  install -m 0755 "$OVERLAY/tools/fly-start" /usr/local/bin/fly-start
fi
if [[ -f $OVERLAY/tools/fly-boot-display ]]; then
  install -m 0755 "$OVERLAY/tools/fly-boot-display" /usr/local/bin/fly-boot-display
fi
if [[ -f $OVERLAY/tools/fly-moonraker-polkit ]]; then
  install -m 0755 "$OVERLAY/tools/fly-moonraker-polkit" /usr/local/bin/fly-moonraker-polkit
fi
if [[ -f $OVERLAY/tools/fly-ensure-shaketune ]]; then
  install -m 0755 "$OVERLAY/tools/fly-ensure-shaketune" /usr/local/bin/fly-ensure-shaketune
fi
if [[ -f $OVERLAY/tools/fly-tft-check ]]; then
  install -m 0755 "$OVERLAY/tools/fly-tft-check" /usr/local/bin/fly-tft-check
fi
if [[ -f $OVERLAY/crowsnest/fly-crowsnest-add-cams ]]; then
  install -m 0755 "$OVERLAY/crowsnest/fly-crowsnest-add-cams" \
    /usr/local/bin/fly-crowsnest-add-cams
fi
if [[ -f $OVERLAY/crowsnest/fly-crowsnest-strip-placeholders ]]; then
  install -m 0755 "$OVERLAY/crowsnest/fly-crowsnest-strip-placeholders" \
    /usr/local/bin/fly-crowsnest-strip-placeholders
fi
# Rotate helper: tools/ first (all flavors), then simpleaf/ copy.
if [[ -f $OVERLAY/tools/fly-grumpy-rotate ]]; then
  install -m 0755 "$OVERLAY/tools/fly-grumpy-rotate" /usr/local/bin/fly-grumpy-rotate
elif [[ -f $OVERLAY/simpleaf/fly-grumpy-rotate ]]; then
  install -m 0755 "$OVERLAY/simpleaf/fly-grumpy-rotate" \
    /usr/local/bin/fly-grumpy-rotate
fi
if [[ -f $OVERLAY/simpleaf/fly-grumpy-evdev.sh ]]; then
  install -m 0755 "$OVERLAY/simpleaf/fly-grumpy-evdev.sh" \
    /usr/local/sbin/fly-grumpy-evdev.sh
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
if [[ -f $OVERLAY/motd/patch-armbian-commands.py ]]; then
  install -m 0755 "$OVERLAY/motd/patch-armbian-commands.py" \
    /usr/share/fly-debian/motd/patch-armbian-commands.py
fi
if [[ -f $OVERLAY/motd/42-fly-commands ]]; then
  install -m 0755 "$OVERLAY/motd/42-fly-commands" /etc/update-motd.d/42-fly-commands
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

# MOTD Commands after flavor so Simple-AF vs KIAUH labels are correct.
if [[ -x /usr/share/fly-debian/motd/patch-armbian-commands.py ]]; then
  python3 /usr/share/fly-debian/motd/patch-armbian-commands.py \
    /etc/update-motd.d/41-commands "${FLAVOR:-base}" || true
fi

# Wizard must remain. Never create user fly here.
