#!/usr/bin/env bash
# Install systemd drop-ins + generator so whatever Klipper installer the
# user picks (KIAUH, Simple-AF, install-debian.sh) lands on CPUs 1-3.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
src=$root/klipper/cpu-affinity
dest=${DESTDIR:-}

if [[ ${EUID:-$(id -u)} -ne 0 && -z ${DESTDIR:-} ]]; then
  echo "re-run as root (or set DESTDIR= for a staging tree)" >&2
  exit 1
fi

gen_dir=$dest/etc/systemd/system-generators
mkdir -p "$gen_dir"
install -m 0755 "$src/fly-klipper-cpu-affinity" "$gen_dir/fly-klipper-cpu-affinity"

while read -r unit; do
  [[ -z $unit || $unit == \#* ]] && continue
  ddir=$dest/etc/systemd/system/${unit}.d
  mkdir -p "$ddir"
  install -m 0644 "$src/50-fly-cpu-affinity.conf" "$ddir/50-fly-cpu-affinity.conf"
done <"$src/units"

user_dir=$dest/etc/systemd/user
while read -r unit; do
  [[ -z $unit || $unit == \#* ]] && continue
  ddir=$user_dir/${unit}.d
  mkdir -p "$ddir"
  install -m 0644 "$src/50-fly-cpu-affinity.conf" "$ddir/50-fly-cpu-affinity.conf"
done <"$src/units"

if [[ -z ${DESTDIR:-} ]]; then
  systemctl daemon-reload
  echo "Installed Klipper CPU affinity (CPUs 1-3)."
  echo "Wi-Fi / 8189fs stay on CPU0. Isolcpus already keeps unpinned work there."
  echo "After you install Klipper: systemctl show -p CPUAffinity klipper"
else
  echo "Staged under $DESTDIR"
fi
