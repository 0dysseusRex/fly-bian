# Pin the Klipper stack to CPUs 1–3

The Lite image does **not** ship a Klipper tree. Users install KIAUH, Simple-AF, or `klipper/scripts/install-debian.sh` later. Those installers all land a systemd unit (`klipper.service`, sometimes `klipper-<name>.service`). We never edit their `ExecStart`.

8189fs must stay on **CPU0**. `isolcpus=1-3` already keeps unpinned processes there. A Klipper that is *not* pinned would share CPU0 with the Wi-Fi driver and can lock the SDIO bus.

## What the image should contain

1. Seeded drop-ins under `/etc/systemd/system/<unit>.d/50-fly-cpu-affinity.conf` for the common names (`klipper`, `moonraker`, `klipper-mcu`, screens, crowsnest, webcamd). systemd merges these the moment that unit exists.
2. Generator `/etc/systemd/system-generators/fly-klipper-cpu-affinity`, so a later `klipper-2.service` or `klipper@.service` gets the same `CPUAffinity=1-3` on `daemon-reload` (every installer does that).

`CPUAffinity=` is `sched_setaffinity`. It still works with `cgroup_disable=cpu,cpuacct` in `armbianEnv.txt`.

Leave nginx, ssh, NetworkManager, and `wpa_supplicant` on CPU0.

## Install on a live card

```bash
sudo ./scripts/install-klipper-cpu-affinity.sh
```

Then install Klipper however you want. After the installer enables the unit:

```bash
systemctl show -p CPUAffinity --value klipper
# 1 2 3

pid=$(systemctl show -p MainPID --value klipper)
awk '/Cpus_allowed_list:/ {print $2}' /proc/$pid/status
# 1-3

./scripts/check-klipper-cpu-affinity.sh
```

Re-dump the card after this install if you want the next `.img.gz` to include it. The current led-tft dump does not, until that step is done.

## Do not

- Remove `maxcpus=1` / `isolcpus=1-3` / `irqaffinity=0`.
- Wrap the installer with `taskset` in a custom `ExecStart=` (the next KIAUH/Simple-AF write will replace the unit file; a `.d/` drop-in survives).
- Pin `load-8189fs` or `wpa_supplicant` onto 1–3.
