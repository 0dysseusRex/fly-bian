# Fly Lite v2.1 Armbian — notes so far

**Date:** 2026-09-07 through 2026-09-08  
**Board:** Mellow FLY Pi Lite v2.1 (Allwinner H3, 512 MB), treated as Orange Pi Lite  
**Goal:** Debian-class Armbian host that matches FlyOS hardware as far as practical, then Simple-AF (pellcorp) for Klipper — **not** FlyOS, and **not** a KIAUH-installed Klipper tree.

Simple-AF must be installed later as a normal sudo user (`fly`), not root. Do not put Klipper/Moonraker/Mainsail on via KIAUH.

Local worker run: [Fly lite debian functions](https://cursor.com/agents/bc-fc6e5f12-d6ec-459c-8f5c-9a5c913531b2). This cloud session cannot fetch that transcript; these notes were copied from it.

Full-card image dumps (bench PC, not in git): **`C:\Users\udrdr\fly-lite-armbian-image`**. See [`images.md`](images.md).

---

## Current live state

The **cpu-affinity** image is the current snapshot (MicroSD was imaged from the USB3 reader after a serial halt). Put that card back in the Lite to boot.

- Hostname `orangepilite`
- Armbian Trixie, kernel `6.18.49-current-sunxi`
- DTB `sun8i-h3-fly-lite.dtb`
- Wi-Fi `wlan0` (RTL8189FTV / `8189fs`) — last recorded lease **192.168.1.148/24** (DHCP; was also seen as `.147`)
- Users `root` and `fly` (sudo)
- Serial: Windows **COM4**, CH340, 115200 8-N-1. Do **not** pulse DTR/RTS (it does not reset this board).
- `reboot` often hangs; use a **5V power cycle**
- Klipper is **not** installed. systemd drop-ins + generator pin future Klipper-family units to CPUs **1–3**.

`/boot/armbianEnv.txt`:

```
verbosity=4
console=serial
fdtfile=sun8i-h3-fly-lite.dtb
overlays=uart1 usbhost0 usbhost2 usbhost3
user_overlays=mmc-broken-cd fly-lite-io fly-lite-tft
extraargs=nohz=off clocksource=timer cma=16M maxcpus=1 isolcpus=1-3 irqaffinity=0 cgroup_disable=cpu,cpuacct
```

CPU layout that holds Wi-Fi:

- Boot **one CPU** (`maxcpus=1`) so 8189fs can start.
- `isolcpus=1-3` and `irqaffinity=0` keep the scheduler and IRQs on CPU0.
- After 8189fs: `fly-online-isolated-cpus.service` onlines CPU1–3 as isolated cores.
- 8189fs / SDIO / `wpa_supplicant` stay on CPU0. Later Klipper units use systemd `CPUAffinity=1-3` (drop-ins + generator). Do **not** wrap `ExecStart` with `taskset` (KIAUH/Simple-AF rewrite the unit).
- **Do not** boot all four cores from t=0.

---

## Images

All are full-card images (≥32 GB SD). Write the whole card; do not copy files. Do not commit `.img` / `.img.gz` or passwords into git. SHA256s: [`images.md`](images.md).

| Snapshot | File | Notes |
| --- | --- | --- |
| pre-led | `fly-lite-v2.1-armbian-pre-led.img.gz` | Fly DTB + Wi-Fi + KIAUH + `maxcpus=1`. LED overlay still broken. No TFT. |
| led-tft | `fly-lite-v2.1-armbian-led-tft.img.gz` | LED fix + TFT software bind. Live `dd` of a running rootfs. Also `/mnt/imgbackup/` on FlyOS USB. |
| **cpu-affinity (current)** | `fly-lite-v2.1-armbian-cpu-affinity.img.gz` | led-tft plus affinity drop-ins. USB3 reader after `shutdown -h now`. |

---

## What works

### Boot and storage

- U-Boot PF6 card-detect patched; overlay `mmc-broken-cd`
- Root `mmcblk0p1` ~29 GB, UUID `27e26c5c-5893-46c7-9a6c-1c3e791790b1`
- Skipped apt kernel/DTB/U-Boot upgrades (would risk the PF6 patch and custom DTB)

### GPIO LEDs

Cause of empty `/sys/class/leds`: `fly-lite-leds.dtbo` duplicated Fly DTB nodes → `leds-gpio: -EBUSY`.

Fix: drop `fly-lite-leds` from `user_overlays`. The Fly DTB already has:

- status PG12 heartbeat
- pwr PG13 on
- wifi PG11
- backlight PA6

Heartbeat LED is confirmed running on the live board.

### TFT (software only)

Kernel 6.18 has no `FB_TFT_ST7796S`. Overlay `fly-lite-tft` uses `panel-mipi-dbi` + `ads7846`. Driver requires porches/sync = 0 (non-zero → `-EINVAL`). Firmware `/lib/firmware/ST7796S.bin`.

Bound live: DRM `panel-mipi-dbi`, `/dev/fb0` 320×480 RGB565, touch `ADS7846` `/dev/input/event0`. **Physical panel is still in the mail** — no visual test yet.

### Wi-Fi

`8189fs` v5.7.9 on SDIO **mmc2**, IRQ 152. SD card is mmc0, IRQ 151. Stable on CPU0 with the isolcpus layout above.

### Serial console

`verbosity=1` + `console=both` hid initramfs fsck and looked like a hang at `Starting kernel`. Now `verbosity=4` and `console=serial`. CH340 USB drops on 5V cycles; autoboot delay is 1 second, so UART is easy to miss.

---

## CPU / 8189fs (diagnosed)

8189fs is **not SMP-safe**. Failure is a **silent SDIO lockup**, not a kernel oops. Armbian ramlog often loses the last messages on a 5V cut.

| Test | Result |
| --- | --- |
| Boot `maxcpus=1` | Wi-Fi comes up |
| Hotplug CPU1–3 after Wi-Fi, no isolation | Wi-Fi dies in about a minute |
| Same, with MMC IRQ + RTW threads pinned to CPU0 | Still dies (~1 min). Pinning is not enough |
| Boot all 4 cores (`maxcpus=1` removed) | Never comes up on the LAN; reflash image 2 |
| Boot `maxcpus=1 isolcpus=1-3 irqaffinity=0`, then online CPU1–3 | Wi-Fi held: 105/105 pings over ~2 min with `dd` on CPU1–3 |

Persisted: `/usr/local/sbin/fly-online-isolated-cpus.sh` and `fly-online-isolated-cpus.service` (`After=load-8189fs.service`). Extraargs backup without isolcpus: `/boot/armbianEnv.txt.bak-isolcpus`.

---

## Operational gotchas

- Live-image first boot: `e2fsck -y /dev/mmcblk0p1` from initramfs if the journal is dirty, then `exit`.
- Two Windows `serial-mcp` processes can steal COM4 after USB re-enum.
- `gpio-regulator vdd-cpux-regulator` probe fails `-ENOMEM` (`-12`); board still runs.
- Do not enable 4 CPUs at boot.
- Do not stream a full-card `dd` of `mmcblk0` over `wlan0`.

---

## Klipper CPU affinity (on disk, Klipper not installed)

Already applied on the **cpu-affinity** image. On the board the tree was `/home/fly/fly-lite-debian`:

```
sudo ./scripts/install-klipper-cpu-affinity.sh
./scripts/check-klipper-cpu-affinity.sh
```

- `/etc/systemd/system-generators/fly-klipper-cpu-affinity` mode **0755**
- Drop-in `50-fly-cpu-affinity.conf` with `CPUAffinity=1-3` for:
  `klipper`, `moonraker`, `klipper-mcu`, `klipperscreen`, `KlipperScreen`, `grumpyscreen`, `crowsnest`, `webcamd`
- `systemctl daemon-reload` ran at install. Klipper was not started.

---

## Not done yet

- Simple-AF install (`~/pellcorp/installer.sh` as user `fly`, not on the KIAUH tree)
- Printer cfg / probe on this host
- Visual TFT test when the panel arrives
- Klipper/Moonraker/Mainsail (intentionally skipped — image stays installer-agnostic)

KIAUH is on the image for later use only if Simple-AF is abandoned. Simple-AF docs say not to install on a KIAUH Klipper environment. The CPU affinity drop-ins cover both.
