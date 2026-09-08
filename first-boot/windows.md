# Windows: serial and the FLY-SETUP volume

This repo cannot open **COM4**. That port is on the bench PC.

## 1. After flashing the named image

Etcher / Raspberry Pi Imager **ejects** the card. Unplug and replug the reader.

Disk Management (`diskmgmt.msc`): the small FAT partition labelled **`FLY-SETUP`**. If it has no letter, right-click → Change Drive Letter. Open `README.txt` and edit `fly-net.txt` there.

Eject, card in the Lite, independent 5 V, IPEX antenna. First boot grows Debian and runs the first-run wizard.

## 2. Serial

Type-C, data-capable cable, **115200 8N1**, no flow control. Often **COM4**.

**Do not** pulse DTR/RTS. It does not reset this board and can stop autoboot.

PuTTY: Serial, `COM4`, 115200. Finish the wizard (root password, your user).

`reboot` may hang — use a 5 V power cycle.

## 3. Stock Orange Pi Lite card (no FLY-SETUP)

Older Trixie images are **one ext4 partition**. Windows will not show a FAT volume. Use serial or HDMI, or see [`lite21-bringup.md`](../docs/lite21-bringup.md) if U-Boot misses the SD (PF6).
