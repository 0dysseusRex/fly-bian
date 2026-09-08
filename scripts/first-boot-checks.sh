#!/usr/bin/env bash
# Run on the Fly Lite 2.1 after a Debian / Armbian first boot.
# Prints the evidence needed before changing pinmux or flashing another image.
set -u

section() {
  printf '\n======== %s ========\n' "$1"
}

section "identity"
uname -a
echo "model: $(tr -d '\0' </proc/device-tree/model 2>/dev/null || echo unknown)"
echo "compatible: $(tr '\0' ' ' </proc/device-tree/compatible 2>/dev/null || echo unknown)"

section "memory and swap"
free -h
swapon --show || true

section "block and mmc"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
echo
echo "mmc devices:"
ls /sys/bus/mmc/devices 2>/dev/null || echo "(none)"
for d in /sys/bus/mmc/devices/*; do
  [[ -e $d ]] || continue
  echo "-- $d"
  cat "$d/type" 2>/dev/null || true
  cat "$d/uevent" 2>/dev/null || true
done

section "usb"
lsusb || echo "install usbutils"
echo
echo "usb controllers:"
ls /sys/bus/usb/devices 2>/dev/null | head

section "network"
ip -br link
echo
command -v nmcli >/dev/null && nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status || true
iwconfig 2>/dev/null || true

section "display"
ls /dev/fb* /dev/dri/card* 2>/dev/null || echo "(no framebuffer / drm yet)"
command -v kmsprint >/dev/null && kmsprint || true

section "serial and gadget"
dmesg | egrep -i 'tty|uart|gadget|g_serial|musb|dwc2' | tail -n 40 || true
ls /dev/ttyS* /dev/ttyGS* /dev/ttyUSB* 2>/dev/null || true

section "kernel clues"
dmesg | egrep -i 'mmc|sdio|wlan|rtl|8189|8723|usb|hdmi|spi|uart|musb|gadget|brcm' | tail -n 80 || true

section "cpu isolation"
echo "cmdline: $(tr ' ' '\n' </proc/cmdline | egrep 'isolcpus|maxcpus|irqaffinity' | xargs echo)"
if [[ -x /etc/systemd/system-generators/fly-klipper-cpu-affinity ]]; then
  echo "klipper cpu-affinity generator: present"
else
  echo "klipper cpu-affinity generator: missing — sudo ./scripts/install-klipper-cpu-affinity.sh"
fi
ls /etc/systemd/system/klipper.service.d/50-fly-cpu-affinity.conf 2>/dev/null || echo "klipper drop-in: not installed yet"

section "next"
cat <<'EOF'
Lite 2.1 live: MMC1 already probed as SDIO. If wlan0 is missing, copy rtl8189 firmware from the official H3 FlyOS extract.
If MMC1 is missing on another board, extract that DTB.
If Type-C serial never appeared on the PC, try overlays/usb-otg-peripheral.dts
after you have another login path (USB Ethernet).
Do not apply overlays/fly-tft-spi-candidate.dts until the FlyOS DTB confirms pins.
EOF
