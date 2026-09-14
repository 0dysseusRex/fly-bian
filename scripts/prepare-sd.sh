#!/usr/bin/env bash
# Copy fly-start.txt + README.txt onto a mounted FAT volume (FLY-SETUP).
# Also writes armbian_first_run.txt for stock Armbian images that still
# look for that name.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: prepare-sd.sh <mounted-FAT-volume> [fly-start.txt]

Example after flashing and re-plugging the reader:

  ./scripts/prepare-sd.sh /media/$USER/FLY-SETUP

Volume label is FLY-SETUP on the named Fly image (armbi_boot or BOOT on
some stock Armbian cards).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

boot=$1
if [[ ! -d $boot ]]; then
  echo "FAT volume not mounted: $boot" >&2
  exit 1
fi

root=$(cd "$(dirname "$0")/.." && pwd)
src=${2:-$root/first-boot/fly-start.txt}
readme=$root/first-boot/README.txt
if [[ ! -f $src ]]; then
  echo "fly-start.txt not found: $src" >&2
  exit 1
fi

get() {
  local key=$1 default=$2
  local line val
  line=$(grep -E "^${key}=" "$src" | tail -n 1 || true)
  if [[ -z $line ]]; then
    printf '%s' "$default"
    return
  fi
  val=${line#*=}
  val=${val%\"}
  val=${val#\"}
  val=${val%\'}
  val=${val#\'}
  printf '%s' "$val"
}

wifi_enabled=$(get WIFI_ENABLED 1)
ssid=$(get WIFI_SSID "")
psk=$(get WIFI_PSK "")
country=$(get WIFI_COUNTRY US)
use_static=$(get USE_STATIC 0)
static_ip=$(get STATIC_IP "")
static_mask=$(get STATIC_MASK "")
static_gateway=$(get STATIC_GATEWAY "")
static_dns=$(get STATIC_DNS "")

skip_first_run=0
if [[ $wifi_enabled == 1 && ( -z $ssid || $ssid == YourNetwork ) ]]; then
  echo "WIFI_SSID is still a placeholder — copying fly-start.txt only (no armbian_first_run Wi-Fi join)"
  skip_first_run=1
fi

cp "$src" "$boot/fly-start.txt"
# Drop legacy name so the volume is not confusing.
rm -f "$boot/fly-net.txt"
if [[ -f $readme ]]; then
  cp "$readme" "$boot/README.txt"
fi

if [[ $skip_first_run -eq 0 ]]; then
  cat >"$boot/armbian_first_run.txt" <<EOF
# Generated from fly-start.txt by prepare-sd.sh
FR_general_delete_this_file_after_completion=1
FR_net_change_defaults=1
FR_net_ethernet_enabled=0
FR_net_wifi_enabled=${wifi_enabled}
FR_net_wifi_ssid='${ssid}'
FR_net_wifi_key='${psk}'
FR_net_wifi_countrycode='${country}'
FR_net_use_static=${use_static}
FR_net_static_ip='${static_ip}'
FR_net_static_mask='${static_mask}'
FR_net_static_gateway='${static_gateway}'
FR_net_static_dns='${static_dns}'
EOF
  echo "wrote $boot/armbian_first_run.txt"
fi

echo "wrote $boot/fly-start.txt"
[[ -f $boot/README.txt ]] && echo "wrote $boot/README.txt"
echo "eject the volume, fit the IPEX antenna, boot with independent 5 V"
echo "first boot grows the Debian partition and runs the first-run wizard"
