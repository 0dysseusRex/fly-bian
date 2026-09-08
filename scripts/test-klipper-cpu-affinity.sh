#!/usr/bin/env bash
# Matcher + generator tests. Runs on any Linux; does not need the Lite.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
gen=$root/klipper/cpu-affinity/fly-klipper-cpu-affinity
fail=0

FLY_KLIPPER_CPU_AFFINITY_LIB=1
# shellcheck disable=SC1090
. "$gen"
unset FLY_KLIPPER_CPU_AFFINITY_LIB

expect_pin() {
  local unit=$1 want=$2 rc
  set +e
  fly_klipper_cpu_affinity_pin_unit "$unit"
  rc=$?
  set -e
  if [[ $want == yes && $rc -ne 0 ]]; then
    echo "FAIL expected pin: $unit" >&2
    fail=1
  elif [[ $want == no && $rc -eq 0 ]]; then
    echo "FAIL expected skip: $unit" >&2
    fail=1
  fi
}

expect_pin klipper.service yes
expect_pin klipper-2.service yes
expect_pin klipper-voron.service yes
expect_pin 'klipper@.service' yes
expect_pin 'klipper@printer.service' yes
expect_pin klipper-mcu.service yes
expect_pin moonraker.service yes
expect_pin moonraker-telegram-bot.service yes
expect_pin klipperscreen.service yes
expect_pin KlipperScreen.service yes
expect_pin grumpyscreen.service yes
expect_pin crowsnest.service yes
expect_pin webcamd.service yes
expect_pin nginx.service no
expect_pin ssh.service no
expect_pin NetworkManager.service no
expect_pin wpa_supplicant.service no
expect_pin load-8189fs.service no
expect_pin fly-online-isolated-cpus.service no

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/units" "$work/out"
touch "$work/units/klipper-ender3.service" "$work/units/nginx.service"

FLY_AFFINITY_UNIT_PATHS=$work/units "$gen" "$work/out"

for unit in klipper.service moonraker.service klipper-ender3.service; do
  conf=$work/out/${unit}.d/50-fly-cpu-affinity.conf
  if [[ ! -f $conf ]]; then
    echo "FAIL missing generated drop-in for $unit" >&2
    fail=1
  elif ! grep -q 'CPUAffinity=1-3' "$conf"; then
    echo "FAIL $unit drop-in missing CPUAffinity=1-3" >&2
    fail=1
  fi
done

if [[ -e $work/out/nginx.service.d/50-fly-cpu-affinity.conf ]]; then
  echo "FAIL nginx must not be pinned" >&2
  fail=1
fi

stage=$(mktemp -d)
DESTDIR=$stage "$root/scripts/install-klipper-cpu-affinity.sh"
if [[ ! -x $stage/etc/systemd/system-generators/fly-klipper-cpu-affinity ]]; then
  echo "FAIL generator not installed" >&2
  fail=1
fi
if [[ ! -f $stage/etc/systemd/system/klipper.service.d/50-fly-cpu-affinity.conf ]]; then
  echo "FAIL seeded klipper drop-in missing" >&2
  fail=1
fi
if [[ ! -f $stage/etc/systemd/system/KlipperScreen.service.d/50-fly-cpu-affinity.conf ]]; then
  echo "FAIL seeded KlipperScreen drop-in missing" >&2
  fail=1
fi

if [[ $fail -ne 0 ]]; then
  echo "cpu-affinity tests failed" >&2
  exit 1
fi
echo "cpu-affinity tests passed"
