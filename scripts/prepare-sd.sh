#!/usr/bin/env bash
# Copy first-boot/fly-net.txt onto a mounted Armbian boot partition and
# emit armbian_first_run.txt so stock Armbian applies Wi-Fi on first boot.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: prepare-sd.sh <mounted-boot-partition> [fly-net.txt]

Example after flashing Armbian and re-plugging the card:

  ./scripts/prepare-sd.sh /media/$USER/armbi_boot

The boot partition is usually labeled armbi_boot or BOOT.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

boot=$1
if [[ ! -d $boot ]]; then
  echo "boot partition not mounted: $boot" >&2
  exit 1
fi

root=$(cd "$(dirname "$0")/.." && pwd)
src=${2:-$root/first-boot/fly-net.txt}
if [[ ! -f $src ]]; then
  echo "fly-net.txt not found: $src" >&2
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

if [[ $wifi_enabled == 1 && ( -z $ssid || $ssid == YourNetwork ) ]]; then
  echo "edit WIFI_SSID and WIFI_PSK in $src before copying" >&2
  exit 1
fi

cat >"$boot/armbian_first_run.txt" <<EOF
# Generated from fly-net.txt by prepare-sd.sh
# See first-boot/README.md

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

cp "$src" "$boot/fly-net.txt"

echo "wrote $boot/armbian_first_run.txt"
echo "wrote $boot/fly-net.txt"
echo "unmount the card, fit the IPEX antenna, boot with independent 5 V"
