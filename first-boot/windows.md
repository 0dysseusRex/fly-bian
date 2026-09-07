# Windows: serial login and the boot-partition Wi-Fi file

This cloud workspace cannot open **COM4**. That port is on your PC. Use this page at the bench.

## 1. Serial (do this first if the card is already in the Lite)

1. Type-C from the Lite to the PC. Data-capable cable. Independent 5 V (≥2 A).
2. Device Manager → **Ports (COM & LPT)**. Note the COM number. It may still be COM4, or it may have changed after you left FlyOS.
3. Open a terminal at **115200 8N1**, no flow control.

**Windows Terminal** (Settings → add a serial profile), or PowerShell:

```powershell
# List ports
Get-CimInstance Win32_SerialPort | Select-Object DeviceID, Name, Description

# Open COM4 (change the number if Device Manager disagrees)
mode COM4: BAUD=115200 PARITY=N DATA=8 STOP=1
python -c "import serial,sys; s=serial.Serial('COM4',115200,timeout=1); print('opened', s.port); 
import time
s.write(b'\r\n\r\n'); time.sleep(0.3)
print(s.read(4000).decode('utf-8','replace'))"
```

**PuTTY:** Connection type Serial, Serial line `COM4`, Speed `115200`. Category → Connection → Serial: Data bits 8, Stop 1, Parity None, Flow control None.

Press Enter twice. You should see one of:

| What you see | Meaning | Next |
| --- | --- | --- |
| FlyOS / `root@` / password `mellow` | Still the FlyOS card | You did not boot the Armbian card |
| `orangepi` / Armbian first-run wizard / `New root password` | Debian is up | Finish the user, then `nmtui` or `nmcli` for Wi-Fi |
| U-Boot, then kernel, then a login | Debian is up, wizard already done | Log in as the user you created |
| Nothing, and COM4 is **gone** | Type-C is likely USB gadget, not a UART bridge. Stock Armbian may not load `g_serial` | HDMI + USB keyboard, or pull the card and write `fly-net.txt` (below) |

Paste that banner back here if you want a read on which OS booted.

**Listen-only is safer until Linux is up.** Opening the port with DTR asserted, or sending Enter during `Hit any key to stop autoboot`, drops you into U-Boot. That is useful when you *want* the `=>` prompt. After a reset, wait for the countdown to hit 0 if you are not pasting yet.

The Trixie image on this Lite is **one ext4 partition**. Windows will not show an `armbi_boot` FAT volume. Skip section 2 until Debian is running, then use `nmtui`.

On Armbian, after you have a shell:

```bash
cat /proc/device-tree/model
ip -br addr
nmcli dev status
```

Copy `scripts/first-boot-checks.sh` over later, or run those three lines now.

## 2. Why Windows did not show a file to edit after flashing

Armbian’s Wi-Fi file lives on the **small FAT boot volume**, not the big ext4 root. Windows often hides it.

- After Etcher / Raspberry Pi Imager / Rufus finishes, it **ejects** the card. Unplug and replug the reader.
- Disk Management (`diskmgmt.msc`): find the ~256–512 MB FAT partition (label `armbi_boot` or `BOOT`). If it has no letter, right-click → **Change Drive Letter and Paths** → assign one.
- Do **not** look for `fly-net.txt` on the ext4 partition. Windows will not mount that.
- If the card is already in the Lite, Windows cannot see it. Pull power, move the card back to the PC, then:

```powershell
# From this repo, after the FAT volume has a letter (example E:)
copy first-boot\fly-net.txt E:\fly-net.txt
# Then from WSL or Git Bash:
./scripts/prepare-sd.sh /mnt/e
```

Or edit `E:\armbian_first_run.txt` by hand: set `FR_net_change_defaults=1`, `FR_net_wifi_enabled=1`, `FR_net_wifi_ssid`, `FR_net_wifi_key`, `FR_net_wifi_countrycode`. Rename is not enough — the file must be named **`armbian_first_run.txt`** (no `.template`).

Eject, return the card to the Lite, boot again. First boot can take several minutes while the rootfs expands.

## 3. If there is no COM port at all

Use FPC-HDMI plus a USB keyboard, or a USB Ethernet dongle on a USB-A port, then SSH. Do not wait on onboard Wi-Fi with no file and no console.

## 4. U-Boot paste (you are here)

You already loaded the kernel and ramdisk. The DTB failed because this image has **no** `/boot/dtb-…/allwinner/` folder. The file is:

```
/boot/dtb-6.18.49-current-sunxi/sun8i-h3-orangepi-lite.dtb
```

At `=>` paste the whole block (or one line at a time if paste garbles). Do **not** reset first. Do **not** run `bootz` until every `ext4load` prints a byte count.

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

Expect ~10.5 MiB, ~14.1 MiB, then ~34541 bytes. Then wait for the kernel and the first-boot resize. Same block lives in `docs/lite21-bringup.md`.
