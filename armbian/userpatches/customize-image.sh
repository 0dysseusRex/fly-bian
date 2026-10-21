#!/bin/bash
# Runs inside the Armbian image customize stage (chroot / nspawn).
# Do not delete /root/.not_logged_in_yet — new users must get the wizard.
set -euo pipefail

OVERLAY="${OVERLAY:-/tmp/overlay}"

# Armbian passes: $1=RELEASE $2=LINUXFAMILY $3=BOARD $4=BUILD_DESKTOP
BOARD_ARG="${3:-}"
if [[ -z $BOARD_ARG && -f /etc/armbian-release ]]; then
  # shellcheck disable=SC1091
  BOARD_ARG=$(. /etc/armbian-release; printf '%s' "${BOARD:-}")
fi

FLY_BOARD_FAMILY=lite
DEVICE_TOKEN=Fly-Lite-2.1
case "$BOARD_ARG" in
  fly-pi-v3*)
    FLY_BOARD_FAMILY=pi-v3
    DEVICE_TOKEN=Fly-Pi-V3
    ;;
esac

echo "Fly-bian customize-image: board=$BOARD_ARG family=$FLY_BOARD_FAMILY"

# Product identity (Fly-bian version + release stem). See docs/image-naming.md.
install -d /etc/fly-debian
FLYBIAN_VER=0.1
if [[ -f $OVERLAY/FLYBIAN_VERSION ]]; then
  FLYBIAN_VER=$(tr -d '[:space:]' <"$OVERLAY/FLYBIAN_VERSION")
fi
printf '%s\n' "$FLYBIAN_VER" >/etc/fly-debian/flybian-version
# Frozen at bake. flybian-version may move later via Fly-bian apt packages.
printf '%s\n' "$FLYBIAN_VER" >/etc/fly-debian/flybian-image-baked
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
printf '%s\n' "$DEVICE_TOKEN" >/etc/fly-debian/flybian-device

# Fly-bian apt (helpers only). Source stays Disabled until the public
# repo is published; flybian-update / docs/howto-update.md enable it.
if [[ -f $OVERLAY/apt/flybian.sources ]]; then
  install -d /etc/apt/sources.list.d /usr/lib/fly-debian /usr/share/fly-debian
  install -m 0644 "$OVERLAY/apt/flybian.sources" \
    /etc/apt/sources.list.d/flybian.sources
fi
if [[ -f $OVERLAY/apt/min-image ]]; then
  install -m 0644 "$OVERLAY/apt/min-image" /usr/share/fly-debian/min-image
fi
if [[ -f $OVERLAY/apt/infer-identity ]]; then
  install -m 0644 "$OVERLAY/apt/infer-identity" \
    /usr/lib/fly-debian/infer-identity
fi
if [[ -f $OVERLAY/apt/check-min-image ]]; then
  install -m 0755 "$OVERLAY/apt/check-min-image" \
    /usr/lib/fly-debian/check-min-image
fi
if [[ -f $OVERLAY/apt/flybian-update ]]; then
  install -m 0755 "$OVERLAY/apt/flybian-update" /usr/sbin/flybian-update
fi

# Static CPUAffinity drop-ins (Lite 512 MB pattern). Safe no-op on Pi V3.
# Do NOT install a systemd generator — OOMs Lite during early boot.
if [[ -f $OVERLAY/cpu-affinity/50-fly-cpu-affinity.conf && -f $OVERLAY/cpu-affinity/units ]]; then
  while read -r unit; do
    [[ -z $unit || $unit == \#* ]] && continue
    install -d "/etc/systemd/system/${unit}.d"
    install -m 0644 "$OVERLAY/cpu-affinity/50-fly-cpu-affinity.conf" \
      "/etc/systemd/system/${unit}.d/50-fly-cpu-affinity.conf"
  done <"$OVERLAY/cpu-affinity/units"
fi
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

# /swapfile is created on first boot after resize (not baked into the image).
# Lite default 2048 MiB; Pi V3 (1 GiB RAM) uses 512 MiB via /etc/default.
if [[ -f $OVERLAY/swapfile/fly-swapfile.sh && -f $OVERLAY/swapfile/fly-swapfile.service ]]; then
  install -m 0755 "$OVERLAY/swapfile/fly-swapfile.sh" /usr/local/sbin/fly-swapfile.sh
  install -m 0644 "$OVERLAY/swapfile/fly-swapfile.service" /etc/systemd/system/fly-swapfile.service
  if [[ $FLY_BOARD_FAMILY == pi-v3 ]]; then
    printf 'FLY_SWAP_MIB=512\n' >/etc/default/fly-swapfile
  else
    printf 'FLY_SWAP_MIB=2048\n' >/etc/default/fly-swapfile
  fi
  if command -v systemctl >/dev/null; then
    systemctl enable fly-swapfile.service
  else
    install -d /etc/systemd/system/multi-user.target.wants
    ln -sf /etc/systemd/system/fly-swapfile.service \
      /etc/systemd/system/multi-user.target.wants/fly-swapfile.service
  fi
fi

GOLDEN="${OVERLAY}/from-golden"
PIV3="${OVERLAY}/pi-v3"
install -d /boot/overlay-user /etc/modules-load.d
install -d /etc/systemd/system/multi-user.target.wants

if [[ $FLY_BOARD_FAMILY == pi-v3 ]]; then
  # Fly H618 DTB from FlyOS-FAST (M2WS USB pull).
  if [[ -f $PIV3/boot/fly-h618.dtb ]]; then
    install -d /boot/dtb /boot/dtb/allwinner /boot/dtb/sunxi
    install -m 0644 "$PIV3/boot/fly-h618.dtb" /boot/dtb/fly-h618.dtb
    install -m 0644 "$PIV3/boot/fly-h618.dtb" /boot/dtb/allwinner/fly-h618.dtb
    install -m 0644 "$PIV3/boot/fly-h618.dtb" /boot/dtb/sunxi/fly-h618.dtb
  fi
  if [[ -d $PIV3/overlays ]]; then
    for f in "$PIV3/overlays"/*; do
      [[ -f $f ]] || continue
      install -m 0644 "$f" "/boot/overlay-user/$(basename "$f")"
    done
  fi
  # HDMI / USB / TFT / board-IO overlays (source + prebuilt dtbo).
  for dir in hdmi usb tft io; do
    if [[ -d $OVERLAY/$dir ]]; then
      for f in "$OVERLAY/$dir"/fly-pi-v3-*; do
        [[ -f $f ]] || continue
        install -m 0644 "$f" "/boot/overlay-user/$(basename "$f")"
      done
    fi
  done
  if command -v dtc >/dev/null; then
    for dts in /boot/overlay-user/fly-pi-v3-*.dts; do
      [[ -f $dts ]] || continue
      dtbo="${dts%.dts}.dtbo"
      dtc -@ -I dts -O dtb -o "$dtbo" "$dts" || true
    done
  fi
  if [[ -d $PIV3/firmware ]]; then
    echo "customize-image: copying Pi V3 firmware"
    install -d /lib/firmware
    cp -a "$PIV3/firmware/." /lib/firmware/ || true
    # aic8800_fdrv opens /lib/firmware/aic8800_fw/SDIO/aic8800D80/.
    # The blobs are installed flat under /lib/firmware/aic8800/.
    if [[ -d /lib/firmware/aic8800 ]]; then
      install -d /lib/firmware/aic8800_fw/SDIO
      ln -sfn /lib/firmware/aic8800 /lib/firmware/aic8800_fw/SDIO/aic8800D80
    fi
    # Avoid a second full copy under qemu; Debian usually merges these paths.
    if [[ ! -e /usr/lib/firmware ]]; then
      ln -s /lib/firmware /usr/lib/firmware 2>/dev/null ||
        { install -d /usr/lib/firmware; cp -a "$PIV3/firmware/." /usr/lib/firmware/ || true; }
    elif [[ "$(readlink -f /usr/lib/firmware 2>/dev/null || true)" != "$(readlink -f /lib/firmware 2>/dev/null || true)" ]]; then
      cp -a "$PIV3/firmware/." /usr/lib/firmware/ || true
    fi
  fi
  # Same ST7796 panel firmware as Lite (panel-mipi-dbi) — keep blobs for later.
  if [[ -f $GOLDEN/firmware/ST7796S.bin ]]; then
    install -d /lib/firmware
    install -m 0644 "$GOLDEN/firmware/ST7796S.bin" /lib/firmware/ST7796S.bin
  fi
  # FPC-TFT: panel-mipi-dbi does not bind from the spi:ST7796S modalias.
  # This panel DIP is capacitive. goodix_ts will not autoload while
  # systemd-udev-trigger stays masked.
  printf '%s\n' panel-mipi-dbi goodix_ts >/etc/modules-load.d/fly-tft.conf

  # LEDs come from fly-h618.dtb (gpio-leds). Do NOT add a LEDs overlay
  # (Lite fly-lite-leds caused -EBUSY). Load netdev trigger for eth LEDs.
  if [[ -f $PIV3/config/modules-load.d/fly-gmac-leds.conf ]]; then
    install -d /etc/modules-load.d
    install -m 0644 "$PIV3/config/modules-load.d/fly-gmac-leds.conf" \
      /etc/modules-load.d/fly-gmac-leds.conf
  else
    printf '%s\n' ledtrig-netdev >/etc/modules-load.d/fly-gmac-leds.conf
  fi

  if [[ -f /boot/armbianEnv.txt ]]; then
    if grep -q '^fdtfile=' /boot/armbianEnv.txt; then
      sed -i 's/^fdtfile=.*/fdtfile=fly-h618.dtb/' /boot/armbianEnv.txt
    else
      echo 'fdtfile=fly-h618.dtb' >>/boot/armbianEnv.txt
    fi
    # Type-C UART only. console=both makes tty1 /dev/console while HDMI/DRM
    # is disabled, and the kernel's pinctrl rollback on serial@5000000 drops
    # PH0/PH1 mid-line. U-Boot already muxes the console pins.
    if grep -q '^console=' /boot/armbianEnv.txt; then
      sed -i 's/^console=.*/console=serial/' /boot/armbianEnv.txt
    else
      echo 'console=serial' >>/boot/armbianEnv.txt
    fi
    # Quiet console looks like a hang on Type-C (Lite lesson).
    # 7 prints KERN_INFO, including sunxi-mmc "initialized" and SDIO card lines.
    if grep -q '^verbosity=' /boot/armbianEnv.txt; then
      sed -i 's/^verbosity=.*/verbosity=7/' /boot/armbianEnv.txt
    else
      echo 'verbosity=7' >>/boot/armbianEnv.txt
    fi
    # tft-c must follow tft so it disables the ADS7846 node.
    # HDMI is already okay in fly-h618.dtb. RS232 headers are enabled
    # but not electrically tested (no adapter yet).
    if grep -q '^user_overlays=' /boot/armbianEnv.txt; then
      sed -i 's/^user_overlays=.*/user_overlays=fly-pi-v3-tft fly-pi-v3-tft-c fly-pi-v3-uart1 fly-pi-v3-usb1 fly-pi-v3-rs232/' /boot/armbianEnv.txt
    else
      echo 'user_overlays=fly-pi-v3-tft fly-pi-v3-tft-c fly-pi-v3-uart1 fly-pi-v3-usb1 fly-pi-v3-rs232' >>/boot/armbianEnv.txt
    fi
    # OEM isolcpus=3 pattern; Pi V3 has 1 GB — avoid Lite maxcpus=1 boot.
    # fsck.mode=skip: systemd-fsck on FLY-SETUP FAT hung first boot (fstab is
    # rewritten after customize, so cmdline is the reliable skip).
    if grep -q '^extraargs=' /boot/armbianEnv.txt; then
      if ! grep -q 'fsck.mode=skip' /boot/armbianEnv.txt; then
        sed -i 's/^extraargs=\(.*\)/extraargs=\1 fsck.mode=skip/' /boot/armbianEnv.txt
      fi
      if ! grep -q 'isolcpus=' /boot/armbianEnv.txt; then
        sed -i 's/^extraargs=\(.*\)/extraargs=\1 isolcpus=3 nohz_full=3 rcu_nocbs=3/' \
          /boot/armbianEnv.txt
      fi
      # debug log level flooded the Type-C console and hid the stall.
      sed -i 's/[[:space:]]*systemd\.log_level=debug//' /boot/armbianEnv.txt
      # fstrim.timer and e2scrub_all.timer both started on 6.12
      # (2026-10-18). Their jobs are calendar timers, not boot jobs.
      sed -i 's/[[:space:]]*systemd\.mask=e2scrub_all\.timer//' /boot/armbianEnv.txt
      sed -i 's/[[:space:]]*systemd\.mask=fstrim\.timer//' /boot/armbianEnv.txt
      # hardware-optimize finished immediately on 6.12 (2026-10-18).
      # hardware-monitor finished immediately the same day.
      # led-state found no saved state and left red:status on heartbeat.
      sed -i 's/[[:space:]]*systemd\.mask=armbian-hardware-optimize\.service//' /boot/armbianEnv.txt
      sed -i 's/[[:space:]]*systemd\.mask=armbian-hardware-monitor\.service//' /boot/armbianEnv.txt
      sed -i 's/[[:space:]]*systemd\.mask=armbian-led-state\.service//' /boot/armbianEnv.txt
      # e2scrub_reap finished in about a second on the 6.12 image
      # (2026-10-18) and serial-getty stayed up. Leave it unmasked.
      sed -i 's/[[:space:]]*systemd\.mask=e2scrub_reap\.service//' /boot/armbianEnv.txt
      sed -i 's/[[:space:]]*systemd\.mask=dbus\.service//' /boot/armbianEnv.txt
      # The second udev coldplug returns, then the console dies within 15s.
      # Initramfs already started udev. serial-getty does not need this pass.
      # Do not unmask this. Early /dev/fb0 and HID stay 0600; fly-grumpy-evdev.sh
      # chmod's those nodes so GrumpyScreen can open them.
      if ! grep -q 'systemd.mask=systemd-udev-trigger.service' /boot/armbianEnv.txt; then
        sed -i 's/^extraargs=\(.*\)/extraargs=\1 systemd.mask=systemd-udev-trigger.service/' \
          /boot/armbianEnv.txt
      fi
    else
      echo 'extraargs=consoleblank=0 isolcpus=3 nohz_full=3 rcu_nocbs=3 fsck.mode=skip systemd.mask=systemd-udev-trigger.service' \
        >>/boot/armbianEnv.txt
    fi
  fi
  # Type-C CH340 is ttyS0 (not C5's ttyS1); ensure serial getty.
  if command -v systemctl >/dev/null; then
    systemctl enable serial-getty@ttyS0.service 2>/dev/null || true
  fi
  # udev coldplug is masked, so dev-ttyS0.device never appears. A drop-in
  # that clears BindsTo= is still merged with the template and the device
  # wait remains. This full unit replaces the template for ttyS0.
  rm -rf /etc/systemd/system/serial-getty@ttyS0.service.d
  cat >/etc/systemd/system/serial-getty@ttyS0.service <<'EOF'
[Unit]
Description=Serial Getty on ttyS0
After=systemd-user-sessions.service plymouth-quit-wait.service getty-pre.target rc-local.service
Before=getty.target
IgnoreOnIsolate=yes

[Service]
ExecStart=-/sbin/agetty -L -o '-p -- \\u' --keep-baud 115200,57600,38400,9600 ttyS0 vt220
Type=idle
Restart=always
UtmpIdentifier=ttyS0
TTYPath=/dev/ttyS0
TTYRows=24
TTYColumns=80
TTYReset=yes
TTYVHangup=yes
IgnoreSIGPIPE=no
SendSIGHUP=yes
StandardInput=tty
StandardOutput=tty
StandardError=tty
Environment=TERM=vt220

[Install]
WantedBy=getty.target
EOF
  # First boot grows the root filesystem. Leave armbian-resize-filesystem
  # enabled and do not write /root/.no_rootfs_resize.
  # fly-swapfile stays enabled: 512 MiB (FLY_SWAP_MIB above). Create after
  # resize. The two units below still hang early on this board before their
  # start timeouts fire; ttyS0 already exists so serial login does not need
  # them. Mask via /etc so the vendor unit files stay unused.
  ln -sfn /dev/null /etc/systemd/system/systemd-binfmt.service
  ln -sfn /dev/null /etc/systemd/system/systemd-tmpfiles-setup.service
  # Community lesson (reemo3dp Gemini/Pi + mellowflyc5): mainline rtw88_8821cs
  # can fail/hang early on M2WE SDIO Wi-Fi and wedge MMC. Blacklist for first
  # boot; load later via fly-apply-fly-net / manual modprobe after login.
  install -d /etc/modprobe.d
  cat >/etc/modprobe.d/fly-pi-v3-wifi-defer.conf <<'EOF'
# Defer SDIO Wi-Fi until after serial login (bring-up). See
# docs/community-alternate-firmware.md (reemo3dp rtw88 note).
blacklist rtw88_8821cs
blacklist rtw88_core
blacklist rtw88_sdio
blacklist aic8800_fdrv
blacklist aic8800_bsp
# Jack MAC binds before AC200 enables the PHY, then the failed probe
# removes eth0. fly-apply modprobes this after ac200.
blacklist dwmac-sun8i
options rtw88_core disable_lps_deep=y
EOF
else
  # Lite: Fly DTB (HDMI disabled in DTB; fly-lite-hdmi overlay turns it on).
  if [[ -f $GOLDEN/boot/sun8i-h3-fly-lite.dtb ]]; then
    install -d /boot/dtb /boot/dtb/sunxi
    install -m 0644 "$GOLDEN/boot/sun8i-h3-fly-lite.dtb" /boot/dtb/sun8i-h3-fly-lite.dtb
    install -m 0644 "$GOLDEN/boot/sun8i-h3-fly-lite.dtb" /boot/dtb/sunxi/sun8i-h3-fly-lite.dtb
  fi

  # User overlays: mmc-broken-cd, IO, TFT, HDMI. Never load fly-lite-leds (-EBUSY).
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
  if [[ -d $OVERLAY/board ]]; then
    for f in "$OVERLAY/board"/*; do
      [[ -f $f ]] || continue
      install -m 0644 "$f" "/boot/overlay-user/$(basename "$f")"
    done
  fi
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

  # panel-mipi-dbi does not autoload from modalias spi:ST7796S.
  # goodix_ts binds from the GT911 node when fly-lite-tft-c is added.
  printf '%s\n' panel-mipi-dbi >/etc/modules-load.d/fly-tft.conf

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
      sed -i 's/^user_overlays=.*/user_overlays=mmc-broken-cd fly-lite-io fly-lite-hdmi fly-lite-board/' \
        /boot/armbianEnv.txt
    else
      echo 'user_overlays=mmc-broken-cd fly-lite-io fly-lite-hdmi fly-lite-board' >>/boot/armbianEnv.txt
    fi
    if grep -q '^disp_mode=' /boot/armbianEnv.txt; then
      sed -i 's/^disp_mode=.*/disp_mode=800x480p60/' /boot/armbianEnv.txt
    else
      echo 'disp_mode=800x480p60' >>/boot/armbianEnv.txt
    fi
  fi
fi

# Console login: multi-user + getty on tty1 until Simple-AF bind.
# greetd fought touch UIs, crashed on large MOTD, and left HDMI stuck
# on graphical.target. Prefer GrumpyScreen (fbdev, ARMv7) ove
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
  # Plymouth packages for optional splash (Simple-AF / fly-boot-display enable).
  # Do NOT auto-start: plymouth-start stole the console on Pi V3 and stalled
  # boot at FLY-SETUP FAT fsck (FlyOS has no Plymouth).
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
# Pi V3 text consoles include a 40-column TFT. The stock sysinfo script
# prints two stats per line with a tab, so the right-hand column wraps
# into the next label. One stat per line fits that width.
if [[ $FLY_BOARD_FAMILY == pi-v3 && -f /etc/update-motd.d/30-armbian-sysinfo ]]; then
  python3 - <<'PY'
from pathlib import Path
p = Path("/etc/update-motd.d/30-armbian-sysinfo")
t = p.read_text(encoding="utf-8")
label_old = 'printf "%-11s\\t" "$after"'
label_new = 'printf "%s\\n" "$after"'
uptime_old = '\\x1B[0m\\t" "${time:-unknown}"'
uptime_new = '\\x1B[0m\\n" "${time:-unknown}"'
if label_old not in t and label_new not in t:
    raise SystemExit("30-armbian-sysinfo: label printf not found")
if uptime_old not in t and uptime_new not in t:
    raise SystemExit("30-armbian-sysinfo: uptime printf not found")
t2 = t.replace(label_old, label_new).replace(uptime_old, uptime_new)
p.write_text(t2, encoding="utf-8")
PY
  chmod a+x /etc/update-motd.d/30-armbian-sysinfo
fi
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
  # Keep serial/text boot; splash is opt-in via fly-boot-display enable.
  for ply in plymouth-start.service plymouth-read-write.service \
    plymouth-quit.service plymouth-quit-wait.service \
    plymouth-reboot.service plymouth-poweroff.service \
    plymouth-halt.service plymouth-kexec.service; do
    systemctl disable "$ply" 2>/dev/null || true
    systemctl mask "$ply" 2>/dev/null || true
  done
  # Stock zram stalls sysinit after /boot mounts (Pi V3 0.60). Swap is the
  # 512 MiB fly-swapfile.service path instead (see docs/lite21-bringup.md).
  for z in armbian-zram-config.service armbian-ramlog.service; do
    systemctl disable "$z" 2>/dev/null || true
    systemctl mask "$z" 2>/dev/null || true
  done
  # console-setup hangs headless/serial after local-fs (Pi V3 0.65); keymap
  # already applied by keyboard-setup.service.
  systemctl disable console-setup.service 2>/dev/null || true
  systemctl mask console-setup.service 2>/dev/null || true
  # First-boot ldconfig.service blocks sysinit/getty (Pi V3 0.70 hung 5+ min
  # on "Rebuild Dynamic Linker Cache"). Build cache in-image and mask the unit.
  # Bound under qemu — bare ldconfig hung a 0.70 customize for 25+ minutes.
  echo "customize-image: ldconfig (bounded)"
  if command -v ldconfig >/dev/null; then
    if command -v timeout >/dev/null; then
      timeout 60 ldconfig -X 2>/dev/null || timeout 60 ldconfig 2>/dev/null || true
    else
      ldconfig -X 2>/dev/null || ldconfig 2>/dev/null || true
    fi
  fi
  systemctl disable ldconfig.service 2>/dev/null || true
  systemctl mask ldconfig.service 2>/dev/null || true
  # Satisfy ConditionNeedsUpdate=/etc and /var (paths are /etc/.updated and
  # /var/.updated — not /var/lib/.updated). Stamp late; post-image re-touches.
  mkdir -p /etc /va
  touch /etc/.updated /var/.updated 2>/dev/null || true
  # random-seed Load/Save stalled after update-done (Pi V3 0.70); blocks
  # sysinit/getty. Seed can be written later; do not wedge first boot.
  systemctl disable systemd-random-seed.service 2>/dev/null || true
  systemctl mask systemd-random-seed.service 2>/dev/null || true
  install -d /etc/systemd/system/systemd-random-seed.service.d
  cat >/etc/systemd/system/systemd-random-seed.service.d/fly-timeout.conf <<'EOF'
[Service]
TimeoutStartSec=10
EOF
  # machine-id-commit + tmpfiles-setup stalled after local-fs (Pi V3 0.70).
  # Prefer a direct uuid write under qemu; systemd-machine-id-setup can hang.
  echo "customize-image: machine-id"
  if [[ ! -s /etc/machine-id ]] || grep -qxE 'uninitialized|0+' /etc/machine-id 2>/dev/null; then
    if command -v uuidgen >/dev/null; then
      uuidgen | tr -d '-' >/etc/machine-id
    elif [[ -r /proc/sys/kernel/random/uuid ]]; then
      tr -d '-' </proc/sys/kernel/random/uuid >/etc/machine-id
    elif command -v systemd-machine-id-setup >/dev/null && command -v timeout >/dev/null; then
      timeout 20 systemd-machine-id-setup --commit 2>/dev/null ||
        timeout 20 systemd-machine-id-setup 2>/dev/null || true
    fi
  fi
  if [[ -s /etc/machine-id ]] && ! grep -qxE 'uninitialized|0+' /etc/machine-id 2>/dev/null; then
    # Already committed; skip first-boot rewrite that can hang on MMC.
    systemctl disable systemd-machine-id-commit.service 2>/dev/null || true
    systemctl mask systemd-machine-id-commit.service 2>/dev/null || true
  fi
  install -d /etc/systemd/system/systemd-tmpfiles-setup.service.d
  cat >/etc/systemd/system/systemd-tmpfiles-setup.service.d/fly-timeout.conf <<'EOF'
[Service]
TimeoutStartSec=30
EOF
  # update-done stalled after journal-catalog (Pi V3 0.70 mid). Markers above
  # should skip it; mask anyway so a later /etc|/var mtime bump cannot wedge.
  systemctl disable systemd-update-done.service 2>/dev/null || true
  systemctl mask systemd-update-done.service 2>/dev/null || true
  install -d /etc/systemd/system/systemd-update-done.service.d
  cat >/etc/systemd/system/systemd-update-done.service.d/fly-timeout.conf <<'EOF'
[Service]
TimeoutStartSec=10
EOF
  # networkd/resolved stuck in Starting after binfmt (Pi V3 0.70 upd) with no
  # sysinit/getty. SDIO Wi-Fi/MMC host likely D-states under early net bring-up;
  # reach serial login first. fly-apply-fly-net can restart networkd later.
  for n in systemd-networkd.service systemd-resolved.service \
    systemd-networkd-wait-online.service; do
    systemctl disable "$n" 2>/dev/null || true
    systemctl mask "$n" 2>/dev/null || true
  done
  install -d /etc/systemd/system/systemd-networkd.service.d
  cat >/etc/systemd/system/systemd-networkd.service.d/fly-timeout.conf <<'EOF'
[Service]
TimeoutStartSec=15
EOF
  install -d /etc/systemd/system/systemd-resolved.service.d
  cat >/etc/systemd/system/systemd-resolved.service.d/fly-timeout.conf <<'EOF'
[Service]
TimeoutStartSec=15
EOF
  # Pi V3: drop the 0.70b–0.70n emergency peel stack (masked dbus/getty path).
  # Strategy rethink: those D-state hangs tracked Armbian 6.18; bring-up now
  # uses BRANCH=legacy (6.12). Keep only known-good Lite lessons above plus
  # /boot vfat noauto below. Re-peel selectively if 6.12 still stalls.
fi
if [[ -f /boot/armbianEnv.txt ]]; then
  if grep -q '^bootlogo=' /boot/armbianEnv.txt; then
    sed -i 's/^bootlogo=.*/bootlogo=false/' /boot/armbianEnv.txt
  else
    echo 'bootlogo=false' >>/boot/armbianEnv.txt
  fi
fi
# FLY-SETUP FAT (/boot): skip systemd-fsck. Pi V3 hung forever on
# systemd-fsck@… then on mount(2) of the same vfat (0.65/0.70). Do not
# mount at boot (noauto only). Automount still wedged sysinit after tmp.mount
# on 0.70c — mount manually after login (mount /boot) when needed.
if [[ -f /etc/fstab ]]; then
  awk '
    BEGIN { OFS = "\t" }
    /^[[:space:]]*#/ || NF < 4 { print; next }
    $3 ~ /^(vfat|msdos|fat)$/ {
      opts = $4
      # Drop auto / automount so noauto wins cleanly.
      gsub(/(^|,)auto(,|$)/, ",", opts)
      gsub(/(^|,)x-systemd\.automount(,|$)/, ",", opts)
      gsub(/(^|,)x-systemd\.idle-timeout=[^,]+/, "", opts)
      gsub(/,,+/, ",", opts)
      gsub(/^,|,$/, "", opts)
      if (opts !~ /(^|,)noauto(,|$)/) opts = (opts == "" ? "noauto" : opts ",noauto")
      if (opts !~ /(^|,)nofail(,|$)/) opts = opts ",nofail"
      if (opts !~ /x-systemd\.device-timeout=/) opts = opts ",x-systemd.device-timeout=10s"
      if (opts !~ /x-systemd\.mount-timeout=/) opts = opts ",x-systemd.mount-timeout=10s"
      dump = (NF >= 5 ? $5 : 0)
      print $1, $2, $3, opts, dump, 0
      next
    }
    { print }
  ' /etc/fstab >/etc/fstab.fly.new && mv /etc/fstab.fly.new /etc/fstab
fi
if command -v systemctl >/dev/null; then
  install -d /etc/systemd/system/systemd-fsck@.service.d
  cat >/etc/systemd/system/systemd-fsck@.service.d/fly-timeout.conf <<'EOF'
[Service]
# Bound hang if a volume still requests fsck (e.g. root); boot FAT uses pass=0.
TimeoutStartSec=45
EOF
  # If something still pulls boot.mount, fail fast.
  install -d /etc/systemd/system/boot.mount.d
  cat >/etc/systemd/system/boot.mount.d/fly-timeout.conf <<'EOF'
[Mount]
TimeoutSec=10
EOF
fi
echo "customize-image: console -> getty@tty1, multi-user.target (plymouth+zram+console-setup+ldconfig+random-seed+machine-id-commit+update-done+networkd/resolved masked; pi-v3: no emergency peel masks, /boot vfat noauto, wifi defer, OEM fly-h618.dtb; kernel via BRANCH=legacy 6.12; tmpfiles timeout; no greetd)"

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
  # Splash teardown is via fly-boot-complete.sh `plymouth quit` only.
  # Do not install plymouth-quit After=fly-boot-complete drop-ins (getty cycle).
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
  if [[ $FLY_BOARD_FAMILY == pi-v3 ]]; then
    # Pi V3 ships BRANCH=legacy (6.12); hold legacy packages, not current.
    apt-mark hold linux-image-legacy-sunxi64 linux-dtb-legacy-sunxi64 \
      "linux-u-boot-${BOARD_ARG}-legacy" 2>/dev/null || true
  else
    apt-mark hold linux-image-current-sunxi linux-dtb-current-sunxi \
      linux-u-boot-fly-lite-21-current 2>/dev/null || true
    apt-mark hold linux-u-boot-fly-lite-21-simpleaf-current \
      linux-u-boot-fly-lite-21-kiauh-current 2>/dev/null || true
  fi
fi

# Flavor bake (Simple-AF or KIAUH). Base boards stay installer-agnostic.
FLAVOR=""
if [[ -f $OVERLAY/fly-flavor ]]; then
  FLAVOR=$(tr -d '\r\n' <"$OVERLAY/fly-flavor")
fi
if [[ -z $FLAVOR ]]; then
  case "$BOARD_ARG" in
    fly-lite-21-simpleaf|fly-pi-v3-simpleaf) FLAVOR=simpleaf ;;
    fly-lite-21-kiauh|fly-pi-v3-kiauh) FLAVOR=kiauh ;;
  esac
fi

# Pi V3 KIAUH ships the installer only. Do not bind a Klipper tree
# that this image does not contain.
if [[ $FLY_BOARD_FAMILY == pi-v3 && $FLAVOR == kiauh ]]; then
  FLAVOR_BIND=0
else
  FLAVOR_BIND=1
fi
if [[ $FLAVOR_BIND == 1 && -n $FLAVOR && -f $OVERLAY/klipper-stack/fly-bind-klipper-stack.sh ]]; then
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
    if [[ $FLY_BOARD_FAMILY == pi-v3 ]]; then
      source "$OVERLAY/kiauh/bake-pi-v3.sh"
    else
      source "$OVERLAY/kiauh/bake.sh"
    fi
    ;;
esac

# Pi V3 fly-start.txt is per flavor, same split as Lite (base / Simple-AF / KIAUH).
if [[ $FLY_BOARD_FAMILY == pi-v3 ]]; then
  case "${FLAVOR:-}" in
    simpleaf) fly_start_src=$OVERLAY/pi-v3/fly-start-simpleaf.txt ;;
    kiauh) fly_start_src=$OVERLAY/pi-v3/fly-start-kiauh.txt ;;
    *) fly_start_src=$OVERLAY/pi-v3/fly-start.txt ;;
  esac
  if [[ -f $fly_start_src ]]; then
    install -m 0644 "$fly_start_src" /usr/share/fly-debian/first-boot/fly-start.txt
    install -m 0644 "$fly_start_src" /boot/fly-start.txt
  fi
fi

# MOTD Commands after flavor so Simple-AF vs KIAUH labels are correct.
if [[ -x /usr/share/fly-debian/motd/patch-armbian-commands.py ]]; then
  python3 /usr/share/fly-debian/motd/patch-armbian-commands.py \
    /etc/update-motd.d/41-commands "${FLAVOR:-base}" || true
fi

# Wizard must remain. Never create user fly here.

# Lite only: split multi-package apt installs. apt itself cannot unpack one
# dependency at a time; /usr/local/bin/apt-get does, one named package per
# dpkg run. Image builds call /usr/bin/apt-get before this is installed.
if [[ $FLY_BOARD_FAMILY == lite && -f $OVERLAY/tools/fly-apt-lowmem ]]; then
  install -m 0755 "$OVERLAY/tools/fly-apt-lowmem" /usr/local/bin/fly-apt-lowmem
  ln -sfn fly-apt-lowmem /usr/local/bin/apt-get
  ln -sfn fly-apt-lowmem /usr/local/bin/apt
  cat >/etc/apt/apt.conf.d/99-fly-lowmem.conf <<'EOF'
// One download at a time. Does not split a dpkg transaction; fly-apt-lowmem does.
Acquire::Queue-Mode "access";
Acquire::Retries "3";
EOF
  echo "customize-image: apt installs on this Lite image run one package at a time"
fi
