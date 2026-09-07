# Fly Lite 2.1 — U-Boot bring-up (live)

This is the paste that boots Armbian Debian on the Lite 2.1 **today**. Autoboot still fails until U-Boot’s own DTB drops Orange Pi Lite’s PF6 card-detect. Linux overlays do not fix that.

Serial: Type-C, **115200 8N1**, no flow control. Prefer PuTTY or a listen-only session so you do not interrupt the next autoboot countdown by accident. This workspace cannot open COM4.

## What the last log already proved

| Observation | Meaning |
| --- | --- |
| `gpio clear PF6` then `mmc dev 0` | SD works. PF6 is high on this PCB, so U-Boot thinks the slot is empty. |
| Kernel + uInitrd `ext4load` succeeded | Files and load addresses are correct (`0x42000000` / `0x43300000`). |
| `…/allwinner/sun8i-h3-orangepi-lite.dtb` failed | This Armbian layout stores DTBs **flat** in the versioned folder. There is no `allwinner/` directory. |
| `sun8i-h3-orangepi-lite.dtb` is **34541** bytes in `/boot/dtb-6.18.49-current-sunxi/` | Load that path. |
| Bare `bootz` after a failed FDT load | `Working FDT set to 0` → board reset. Do not `bootz` until all three loads print a byte count. |
| One DOS partition, type 83, ~1.34 GiB used | This image is **single ext4**. No FAT `armbi_boot`. `fatls` / `saveenv` / Windows Wi-Fi file will not work until Linux is up (or we bake a different layout). |
| `/boot/zImage`, `/boot/uInitrd`, `/boot/dtb` | Symlinks. **U-Boot `ext4load` does not follow them.** Do not `source /boot/boot.scr`. |

## Paste at `=>` (do not reset first)

You are already at the prompt after PXE failed. Paste this **whole block**. If a line garbles, paste one command at a time.

```
gpio clear PF6
mmc dev 0
setenv kernel_addr_r 0x42000000
setenv fdt_addr_r 0x43000000
setenv ramdisk_addr_r 0x43300000
ext4load mmc 0:1 ${kernel_addr_r} /boot/vmlinuz-6.18.49-current-sunxi
ext4load mmc 0:1 ${ramdisk_addr_r} /boot/uInitrd-6.18.49-current-sunxi
ext4load mmc 0:1 ${fdt_addr_r} /boot/dtb-6.18.49-current-sunxi/sun8i-h3-orangepi-lite.dtb
setenv bootargs console=ttyS0,115200 earlyprintk root=/dev/mmcblk0p1 rootwait rootfstype=ext4
bootz ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
```

Each `ext4load` must print bytes read:

| File | Typical size |
| --- | --- |
| `vmlinuz-6.18.49-current-sunxi` | ~10.5 MiB (`10535808` seen) |
| `uInitrd-6.18.49-current-sunxi` | ~14.1 MiB (`14830693` seen) |
| `sun8i-h3-orangepi-lite.dtb` | ~34 KiB (`34541` listed) |

Then wait. First boot resizes the rootfs and can sit quiet for several minutes. Console is `ttyS0,115200`.

If the board resets back to SPL, wait for `Hit any key to stop autoboot` — **do not press a key unless you want the prompt**. After `MMC: no card present` and PXE, you get `=>` again. Repeat the paste (PF6 is high after every reset).

## After Linux

1. Finish Armbian’s first-run user. Do not live as root.
2. 512 MB: keep zram; add a 1 GB swap file before compiling.
3. Wi-Fi: `nmtui` or `nmcli` (no pre-boot file on this card — there is no FAT partition).
4. `scripts/first-boot-checks.sh` (or the commands in the web guide).

Autoboot will keep dying on PF6 until we patch **U-Boot’s** DTB (`broken-cd`, delete `cd-gpios` on `mmc@1c0f000`). `overlays/sd-broken-cd.dts` is for Linux only. `saveenv` expects FAT and will not persist a `bootcmd` on this image.
