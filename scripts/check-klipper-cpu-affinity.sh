#!/usr/bin/env bash
# On the Lite: show whether Klipper-family units are pinned to CPUs 1-3.
set -u

echo "isolcpus: $(sed -n 's/.*isolcpus=\([^ ]*\).*/\1/p' /proc/cmdline 2>/dev/null || echo none)"
echo "maxcpus:  $(sed -n 's/.*maxcpus=\([^ ]*\).*/\1/p' /proc/cmdline 2>/dev/null || echo none)"
echo "generator: $(command -v /etc/systemd/system-generators/fly-klipper-cpu-affinity || echo missing)"

if [[ ! -d /etc/systemd/system ]]; then
  exit 0
fi

shopt -s nullglob
found=0
for dropin in /etc/systemd/system/*.service.d/50-fly-cpu-affinity.conf; do
  found=1
  echo "drop-in: $dropin"
done
if [[ $found -eq 0 ]]; then
  echo "drop-in: none under /etc/systemd/system"
fi

echo
echo "Running Klipper-family units:"
listed=0
while read -r unit; do
  [[ -z $unit ]] && continue
  listed=1
  pid=$(systemctl show -p MainPID --value "$unit" 2>/dev/null || echo 0)
  aff=$(systemctl show -p CPUAffinity --value "$unit" 2>/dev/null || echo "")
  allowed="n/a"
  if [[ ${pid:-0} -gt 1 && -r /proc/$pid/status ]]; then
    allowed=$(awk '/Cpus_allowed_list:/ {print $2}' /proc/"$pid"/status)
  fi
  echo "  $unit  CPUAffinity=${aff:-unset}  pid=$pid  Cpus_allowed_list=$allowed"
done < <(systemctl list-units --type=service --all --no-legend --plain 2>/dev/null | awk '{print $1}' | grep -E '^(klipper|moonraker|klipperscreen|grumpyscreen|crowsnest|webcamd)([@.-].*)?\.service$' || true)

if [[ $listed -eq 0 ]]; then
  echo "  (none running — affinity applies the first time the installer enables a matching unit)"
fi
