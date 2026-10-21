# Fly Pi V3 — not yet tested

Hold this list for later notes. Fly-bian **1.0** shipped; this is leftover from the lab board (M2WE eMMC). Items already checked on that board are not listed.

- **RS232 headers.** Both ports are enabled and not electrically tested. There is no RS232 adapter yet. `ttyS3` is PI9/PI10 and `ttyS4` is PI13/PI14. RTS/CTS is left off because the extra UART4 pins include PI16, the power LED. The TTL UART header (`ttyS1`) and the Type-C console (`ttyS0`) were tested separately.
- **Micro HDMI jack.** The picture path is the same transmitter already proven with the Fly HDMI cable at 800×480. The micro-HDMI connector itself has not been plugged into a monitor.
- **ADXL345 / RRF header** (ZH1.5-7P). Turned on for a later test, with the TFT unplugged. `/dev/spidev1.2` is up: clock, data, and chip-select (PI7, held idle). No sensor was attached, so nothing was read from the header. A fresh image boots the panel. `SPI_DEVICE=adxl` in `fly-start.txt` switches to this header on the following boot. The panel must be unplugged first.
- **Type-C USB gadget.** The four USB-A host ports were tested with a full-speed keyboard dongle. The Type-C port was not tested as a USB device, and no high-speed USB device was tried on the USB-A ports.
- **TFT touch alignment.** The GT911 reports finger events. Whether those coordinates line up with the 320×480 glass was not checked. One drag reported X values past 320.
- **SPI TFT as GrumpyScreen.** GrumpyScreen paints `/dev/fb0` (Fly-LCD HDMI, 800×480). The SPI panel is `/dev/fb1` and stays blank unless a picker is added later.
- **`systemd-udev-trigger`.** Still masked. On earlier kernels the console died after the second udev pass. Do not unmask it. Early DRM/HID nodes stay `0600`; `fly-grumpy-evdev.sh` chmods those nodes so GrumpyScreen can open them.
- **Weekly fstrim and Sunday e2scrub.** The timers start. Neither job has been seen running.
- **Other storage layouts.** This board booted from its eMMC. SD-only and the 2.4 GHz-only M2 module were not run on this image.
- **HDMI audio.** Not tested.
- **Soft reboot.** `reboot` often hangs after `[ OK ]`. Use a 5 V (or 12–24 V) power cycle.
