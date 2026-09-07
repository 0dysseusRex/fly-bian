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
fdt addr ${fdt_addr_r}
fdt resize 4096
fdt rm /soc/mmc@1c0f000 cd-gpios
fdt set /soc/mmc@1c0f000 broken-cd
fdt set /soc/mmc@1c0f000 non-removable
setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p1 rootwait rootfstype=ext4 module_blacklist=8189fs,rtl8189fs,r8188eu cma=16M bpf_jit_enable=0 systemd.mask=armbian-zram-config.service
bootz ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
```

Each `ext4load` must print bytes read:

| File | Typical size |
| --- | --- |
| `vmlinuz-6.18.49-current-sunxi` | ~10.5 MiB (`10535808` seen) |
| `uInitrd-6.18.49-current-sunxi` | ~14.1 MiB (`14830693` seen) |
| `sun8i-h3-orangepi-lite.dtb` | ~34 KiB (`34541` listed) |

`fdt rm` / `fdt set` must run **after** the DTB `ext4load` and **before** `bootz`. That is what stops Linux from repeating U-Boot’s PF6 mistake (`Got CD GPIO`, then no `mmcblk0`). If `fdt rm` says the path is missing, `fdt list /soc` and use the `mmc@1c0f000` node it prints.

Then wait. First boot resizes the rootfs and can sit quiet for several minutes. Console is `ttyS0,115200`.

## Quiet after `cfg80211: Loading compiled-in X.509 certificates`

That line is the Wi-Fi stack, not a panic. On this board `mmc1` already probed as SDIO, so `cfg80211` often prints around 10–15 s and then the console goes idle while:

- initramfs finishes and systemd starts
- Armbian expands `/` from ~1.3 GiB to the rest of the card (minutes on a slow SD)

Press **Enter** once. A login or first-run wizard can be sitting there without a reprint.

Give it **10–15 minutes** if you already saw `EXT4-fs` mount or `systemd` before that line. Do not reset during resize.

If there was **no** `EXT4-fs` / `systemd` / `Debian GNU/Linux` banner after ~15 minutes, the 8189fs SDIO driver may be blocking. Power-cycle, get `=>`, and use the same paste but this `bootargs` line instead:

```
setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p1 rootwait rootfstype=ext4 module_blacklist=8189fs,rtl8189fs,r8188eu
```

That skips onboard Wi-Fi for this boot so you can finish the user wizard. Bring the radio back after login.

If the board resets back to SPL, wait for `Hit any key to stop autoboot` — **do not press a key unless you want the prompt**. After `MMC: no card present` and PXE, you get `=>` again. Repeat the paste (PF6 is high after every reset).

## Kernel started, `(initramfs)` has no `/dev/mmcblk0p1`

That is the same CD pin. Linux reclaimed PF6 (`sunxi-mmc 1c0f000.mmc: Got CD GPIO`) and never created `mmcblk0`. `mmc1` **did** come up as SDIO (`mmc1: new high speed SDIO card`) — onboard Wi-Fi hardware is there.

**Prefer a reset + the `fdt` lines above.** That is the reliable fix.

If you want to try this initramfs session first (optional):

```
ls /proc/device-tree/soc/mmc@1c0f000
ls /dev/mmc* /sys/class/mmc_host
echo 1c0f000.mmc > /sys/bus/platform/drivers/sunxi-mmc/unbind
pul=$(devmem 0x01C208D0 32)
echo PUL0=$pul
devmem 0x01C208D0 32 $(( (pul & ~0x3000) | 0x2000 ))
echo 1c0f000.mmc > /sys/bus/platform/drivers/sunxi-mmc/bind
sleep 2
ls -l /dev/mmcblk*
dmesg | grep mmc | tail
```

If `devmem` is missing, use `busybox devmem` in those two lines. If `/dev/mmcblk0p1` appears: `exit` (initramfs retries the mount). If it does not: `reboot -f` and use the U-Boot paste with `fdt rm`.

## Kernel panic after `Welcome to Armbian`

The FDT edit worked: `mmc0: new high speed SDHC card`, `mmcblk0: 29.1 GiB`, `EXT4-fs mounted`, systemd 257, hostname `orangepilite`.

Then Armbian’s zram service sized **248 MB** of compressed swap on a 512 MB SoC (102 MB already reserved as CMA). Seconds later udev-worker oopsed in `__seccomp_filter` / BPF (`PC` landed in slab, not executable filter code) and the kernel panicked (`stack-protector: Kernel stack is corrupted`).

That is a 32-bit sunxi 6.18 + tight RAM bug, not a dead card. The paste above now:

- `cma=16M` — free ~86 MB of CMA
- `bpf_jit_enable=0` — skip the ARM Thumb2 BPF JIT that udev’s seccomp walked into
- `systemd.mask=armbian-zram-config.service` — do not allocate 248 MB zram on first boot
- keeps the 8189fs blacklist so SDIO Wi-Fi does not pile on

If it still panics, same paste but this `bootargs` (root shell, no systemd):

```
setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p1 rootwait rootfstype=ext4 rw init=/bin/bash
```

Then: `mount -o remount,rw /` if needed, `passwd`, add a user, and write a 1 GB swap **file** before turning zram back on.

## After Linux

1. Finish Armbian’s first-run user. Do not live as root.
2. 512 MB: **do not** re-enable stock zram until a 1 GB swap file exists. The default 248 MB zram panicked 6.18.49 on this board.
3. Wi-Fi: `nmtui` or `nmcli` after you drop `module_blacklist` on a later boot (or `modprobe 8189fs` once you have a shell).
4. `scripts/first-boot-checks.sh` (or the commands in the web guide).

Autoboot will keep dying on PF6 until we patch **U-Boot’s** DTB (`broken-cd`, delete `cd-gpios` on `mmc@1c0f000`). `overlays/sd-broken-cd.dts` is for Linux only. `saveenv` expects FAT and will not persist a `bootcmd` on this image.
