# First-boot Wi-Fi and console

The Lite 2.1 has no Ethernet jack. Get a login with one of these before you chase TFT overlays.

## 1. Edit `fly-net.txt` on the card (headless)

1. Flash Armbian Debian 13 Trixie Minimal CLI for Orange Pi Lite to a **spare** MicroSD.
2. Re-plug the card so the FAT boot partition mounts (`armbi_boot`, `BOOT`, or similar).
3. Edit `first-boot/fly-net.txt` in this repo (SSID, password, country).
4. Run:

```bash
./scripts/prepare-sd.sh /media/$USER/armbi_boot
```

Or copy by hand: the script writes `armbian_first_run.txt` (Armbian’s official first-run file) plus `fly-net.txt` onto that partition.

5. Fit the IPEX antenna. Independent 5 V. First boot can take a few minutes while the card expands.
6. Find the DHCP lease and SSH in as the user you create at first login (`ssh <user>@<ip>`). Root is not the daily account on Armbian.

Wi-Fi still needs the radio to probe. If MMC1 never appears, the file cannot help — use serial or a USB Ethernet dongle, then extract the FlyOS DTB.

## 2. Serial

- Lite 2.1 Type-C to the PC, **115200 8N1**.
- Data-capable cable. On FlyOS this is COM4; on Debian it is the same hardware or a USB gadget (see `overlays/usb-otg-peripheral.dts`).
- Armbian first-login wizard runs on the console.

## 3. HDMI + USB keyboard

- FPC-HDMI (Lite 2.1) or Micro-HDMI (Pi V3) and a USB keyboard on a USB-A port.
- Leave the FPC-TFT unplugged for the first boot.
- If the HDMI connector stays disconnected in `/sys/class/drm`, the public DTB is not enough — loot FlyOS next.

Do not rely on onboard Wi-Fi alone for the first login.
