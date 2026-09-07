# Fly Lite 2.1 — Klipper pins and macros

Future-reference sheet for a Klipper install on the Mellow **Fly-Pi-lite2.1** host.

The Lite 2.1 is a **Klipper host**, not a printer MCU. Stepper, heater, endstop, probe, and fan pins live on the board you plug into USB or CAN. This document lists every **host** pin, **FlyOS-FAST sys-config key**, and **macro contract** a working Klipper stack needs. It does **not** invent a printer-MCU pinout.

Sources are official Mellow Lite 2.1 pages unless marked otherwise. Live dumps from `192.168.1.147` were not reachable from this workspace; run `scripts/pull-live-flyos.sh` on the same LAN to fill remaining tokens.

---

## 1. What belongs on the Lite vs the printer MCU

| Item | Where it lives | Klipper name |
| --- | --- | --- |
| Motion, heaters, fans, endstops, probe | Printer MCU (USB or CAN) | `[mcu]` pins such as `PA8`, `PB3` |
| Host Linux process (KPPM, optional host GPIO) | Lite SoC | `[mcu host]` → `host:gpiochipN/gpioM` |
| USB accelerometer | Separate RP2040 on USB-A | `[mcu LIS]` / `[mcu adxl]` |
| Toolboard accelerometer | Toolboard MCU | pins on that MCU |
| TFT / HDMI / Wi-Fi | Linux, not Klipper | `sys-config.conf` / device tree |
| Fluidd / Mainsail buttons | Host config macros | `PAUSE`, `RESUME`, `CANCEL_PRINT` |

Do **not** copy a Fly-Pi 40-pin GPIO header map onto this board. The Lite is compact: two USB-A, Type-C, FPC-HDMI, FPC-TFT, IPEX1 Wi-Fi, 5 V terminal. There is no documented 40-pin header and **no host SPI/I2C ADXL** (official Lite 2.1 accelerometer page).

---

## 2. Required `[mcu]` sections

### Printer MCU (always required)

USB (recommended):

```cfg
[mcu]
serial: /dev/serial/by-id/usb-Klipper_<chip>_<unique>-if00
```

Find the path on the Lite:

```bash
ls -l /dev/serial/by-id/
```

Reject these IDs (official USB-ID notes):

| Path contains | Why |
| --- | --- |
| `usb-1a86_USB_Serial` | Generic CH340-class adapter, not a Klipper MCU |
| `katapult` | Bootloader mode; flash Klipper first |

CAN (only if that MCU is on CAN):

```cfg
[mcu]
canbus_uuid: <uuid from canbus_query.py>
```

Do not set both `serial:` and `canbus_uuid:` on the same `[mcu]`.

### Host MCU (required for KPPM; useful anyway)

```cfg
[mcu host]
serial: /tmp/klipper_host_mcu
```

On FlyOS-FAST this socket is already provided. On Debian you must build and run the Linux MCU (`klipper_mcu` / `linux_mcu`) so `/tmp/klipper_host_mcu` exists.

Host pin syntax:

```text
host:gpiochip<N>/gpio<M>
!host:gpiochip<N>/gpio<M>     # active-low
```

---

## 3. Official host pin: KPPM power-loss

This is the **only** Lite 2.1 host GPIO Mellow documents for Klipper.

| Function | Klipper pin | Linux line | SoC ball |
| --- | --- | --- | --- |
| KPPM power-detect / PLR | `host:gpiochip1/gpio8` | `gpiochip1` line 8 | H3 **PL8** (`r_pio`) |

Official page: [Lite 2.1 power-off / power-loss resume](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/advanced/kppm/).

Rules from that page:

- Use a **KPPM**. Do not invent another 5 V scheme.
- The pin **must** be a host GPIO. Never a printer-MCU or toolboard pin.
- Power-off shutdown and power-loss resume are **mutually exclusive**.
- If USB 5 V between host and MCU cannot be isolated, fully power-cycle the MCU after a host shutdown or it may fail to boot.
- Independent 5 V on the Lite. Do not power the Lite from a printer MCU.

Other Fly hosts use different lines. **Do not reuse them:**

| Board | Official `power_pin` | Not for Lite 2.1 |
| --- | --- | --- |
| Fly Lite 2.1 | `host:gpiochip1/gpio8` | — |
| Fly-Pi V2 | `host:gpiochip1/gpio21` | Wrong chip line |
| Fly-C5 (example MCU pin style) | `!host:gpiochip0/gpio260` | Different SoC |

---

## 4. H3 GPIO map (for any future `host:` pin)

Allwinner H3 exposes two chips to the Linux MCU:

| Chip | Controller | Banks | Typical use on Lite 2.1 |
| --- | --- | --- | --- |
| `gpiochip0` | `pio` | PA, PC, PD, PE, PF, PG | SD, USB, HDMI, SPI/TFT candidates |
| `gpiochip1` | `r_pio` | PL | KPPM **PL8**, power LED on similar H3 boards |

Line number on `gpiochip0`:

```text
line = bank_index * 32 + pin
```

| Bank | Index | Lines | Example |
| --- | --- | --- | --- |
| PA | 0 | 0–21 | PA13 → `gpiochip0/gpio13` |
| PC | 2 | 64–80 | PC7 → `gpiochip0/gpio71` |
| PD | 3 | 96–117 | PD0 → `gpiochip0/gpio96` |
| PE | 4 | 128–143 | PE0 → `gpiochip0/gpio128` |
| PF | 5 | 160–166 | PF0 → `gpiochip0/gpio160` |
| PG | 6 | 192–205 | PG6 → `gpiochip0/gpio198` |

`gpiochip1` is **only** PL:

| Ball | Line | Official Lite 2.1 use |
| --- | --- | --- |
| PL8 | `gpiochip1/gpio8` | KPPM `power_pin` |
| PL10 | `gpiochip1/gpio10` | Power LED on Orange Pi Lite DTB (not documented for Fly) |

Closest public DTB in this repo: `flyos-artifacts/reference/sun8i-h3-orangepi-lite.dts`. Treat LED/Wi-Fi regulator GPIOs there as **Orange Pi Lite**, not Fly, until a live FlyOS DTB dump says otherwise.

---

## 5. Pins the Lite does **not** provide to Klipper

| Wanted function | Lite 2.1 reality | What to use instead |
| --- | --- | --- |
| Host SPI/I2C ADXL345 | Officially unsupported on the LITE2 series | USB LIS2DW, or a toolboard accel |
| 40-pin GPIO header | Not documented | Do not copy Fly-Pi / Raspberry Pi pin aliases |
| Stepper / heater / endstop aliases | Not on the host | Printer MCU config for **that** board |
| Ethernet PHY | No jack | Onboard 2.4 GHz Wi-Fi or USB Ethernet |
| 5 GHz Wi-Fi | Onboard radio is 2.4 GHz only | USB module if you add one later |

Official accelerometer page: [Lite 2.1 ADXL](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/advanced/adxl/).

---

## 6. FlyOS-FAST `sys-config.conf` keys

Hidden folder `.flyos-config/sys-config.conf` (Fluidd: unhide files; Mainsail: show hidden files). It is a symlink to `config.txt` on the `FlyOS-Conf` FAT partition.

Format is strict: `key=value` with **no spaces** around `=`.

### Confirmed on Lite 2.1

| Key | Official / required values | What it does |
| --- | --- | --- |
| `board` | `fly-lite2.1` | Selects the FAST board profile |
| `screen` | `fly-tft-v2-r` (resistive TFT, official Lite 2.1 example) | Loads the matching display overlay |
| `klipper_screen` | `0` or `1` | `1` starts KlipperScreen |
| `fly_screen` | `0` or `1` | `1` starts FLY Screen |
| `shutdown_pin` | host GPIO for KPPM shutdown (comment out for PLR) | FAST power-off-on-loss |
| `shutdown_pin_state` | logic level for that pin (comment out for PLR) | FAST power-off-on-loss |

Official Lite 2.1 screen page: if **both** `klipper_screen=1` and `fly_screen=1`, **KlipperScreen wins**.

Official Lite 2.1 resistive TFT recipe:

```text
board=fly-lite2.1
screen=fly-tft-v2-r
klipper_screen=0
fly_screen=1
```

TFT cable (Lite 2.1 only): **FPC 16P reverse 0.5 mm 400 mm**. Fly-Pi V2 uses 14P — do not mix.

DIP on the panel: `Resi` = resistive, `Cap` = capacitive.

### Present as tabs on the Lite 2.1 screen page (confirm tokens from a live dump)

The official page has **TFT capacitive** and **HDMI** tabs. The English scrape only returned the resistive example. After you pull the board, copy the exact `screen=` values from `sys-config.conf` into `flyos-artifacts/live/`. Expected family (other FAST hosts):

| Display | Likely `screen=` token | Confirm live |
| --- | --- | --- |
| FLY-TFT V2 resistive | `fly-tft-v2-r` | Official Lite 2.1 |
| FLY-TFT V2 capacitive | `fly-tft-v2-c` or `fly-tft-v2` | Confirm |
| HDMI / FPC-HDMI | `hdmi` | Confirm |

Klipper itself does not consume these keys. They only matter so KlipperScreen or FLY Screen can start.

### Power-loss vs shutdown in `sys-config.conf`

To use Klipper `[power_loss_resume]`, official Lite 2.1 KPPM page: **comment out** both `shutdown_pin` and `shutdown_pin_state` with `#`, save, reboot. Then use `plr.cfg` (section 8).

---

## 7. Client macros every Fluidd / Mainsail install needs

Include **one** client file in `printer.cfg`:

```cfg
[include fluidd.cfg]
# or
[include mainsail.cfg]
```

Those files ship `[virtual_sdcard]`, `[pause_resume]`, `[display_status]`, `[respond]`, and the macros below. Do not define a second `[virtual_sdcard]`.

On Debian / MainsailOS-style layouts the path is:

```cfg
[virtual_sdcard]
path: ~/printer_data/gcodes
on_error_gcode: CANCEL_PRINT
```

On FlyOS-FAST, configs and gcodes live under the writable `/data` tree. Use whatever path the stock `fluidd.cfg` / `mainsail.cfg` already has after you pull the live board.

### Public macros (web UI buttons)

| Macro | Role |
| --- | --- |
| `PAUSE` | Renames stock pause to `PAUSE_BASE`, parks, retracts |
| `RESUME` | Restores park, unretracts, calls `RESUME_BASE` |
| `CANCEL_PRINT` | Retract, heaters off, fan off, `CANCEL_PRINT_BASE` |
| `SET_PAUSE_NEXT_LAYER` | Pause when the next layer is reached |
| `SET_PAUSE_AT_LAYER` | Pause at a given layer |
| `SET_PRINT_STATS_INFO` | Layer hook used by the two macros above |

### Internal helpers (do not call from slicer start G-code)

| Macro | Role |
| --- | --- |
| `_TOOLHEAD_PARK_PAUSE_CANCEL` | Park used by PAUSE / CANCEL |
| `_CLIENT_RETRACT` | Retract if hot enough |
| `_CLIENT_EXTRUDE` | Unretract / extrude if hot enough |
| `_CLIENT_LINEAR_MOVE` | Isolated linear move |

### `_CLIENT_VARIABLE` — every tunable

Copy this block into `printer.cfg` (not into the read-only client file) and uncomment what you change. Defaults below match Fluidd/Mainsail `client.cfg`.

| Variable | Default | Meaning |
| --- | --- | --- |
| `variable_use_custom_pos` | `False` | Use custom park X/Y |
| `variable_custom_park_x` | `0.0` | Park X (must be inside axis limits) |
| `variable_custom_park_y` | `0.0` | Park Y |
| `variable_custom_park_dz` | `2.0` | Z hop while parking (mm) |
| `variable_retract` | `1.0` | Retract on PAUSE (mm) |
| `variable_cancel_retract` | `5.0` | Retract on CANCEL_PRINT (mm) |
| `variable_speed_retract` | `35.0` | Retract speed (mm/s) |
| `variable_unretract` | `1.0` | Unretract on RESUME (mm) |
| `variable_speed_unretract` | `35.0` | Unretract speed (mm/s) |
| `variable_speed_hop` | `15.0` | Z hop speed (mm/s) |
| `variable_speed_move` | `100.0` | Park XY speed (mm/s) |
| `variable_park_at_cancel` | `False` | Park on cancel |
| `variable_park_at_cancel_x` | `None` | Optional cancel park X |
| `variable_park_at_cancel_y` | `None` | Optional cancel park Y |
| `variable_use_fw_retract` | `False` | Use `[firmware_retraction]` G10/G11 |
| `variable_idle_timeout` | `0` | Seconds; `0` leaves idle timeout alone |
| `variable_runout_sensor` | `""` | e.g. `"filament_switch_sensor runout"` |
| `variable_user_pause_macro` | `""` | Single-line hook after `PAUSE_BASE` |
| `variable_user_resume_macro` | `""` | Single-line hook before `RESUME_BASE` |
| `variable_user_cancel_macro` | `""` | Single-line hook before cancel |

`variable_use_fw_retract: True` requires a `[firmware_retraction]` section.

---

## 8. Power-loss macros and `[power_loss_resume]`

Put this at the **top** of `printer.cfg`:

```cfg
[include plr.cfg]
```

Checked-in template: `klipper/host-fragments/plr.cfg` (official Lite 2.1 text).

### `[power_loss_resume]` keys

| Key | Official Lite 2.1 | Meaning |
| --- | --- | --- |
| `power_pin` | `host:gpiochip1/gpio8` | KPPM detect on PL8 |
| `is_shutdown` | `True` | Shut the host down after save |
| `paused_recover_z` | `-2.0` | Extra Z move if the job was paused at loss |
| `start_gcode` | see template | Runs before travel back to the interrupt pose |
| `resume_gcode` | see template | Runs after arrival, before print motion |
| `layer_count` | `2` | Layers to print before `layer_change_gcode` |
| `layer_change_gcode` | see template | Restore fan / speed / flow |
| `shutdown_gcode` | see template | Runs just before host shutdown |

`{PLR}` placeholders used in the official template:

| Token | Use |
| --- | --- |
| `{PLR.print_stats.filename}` | Interrupted file |
| `{PLR.POS_X}` `{PLR.POS_Y}` `{PLR.POS_Z}` `{PLR.POS_E}` | Interrupt pose |
| `{PLR.heaters}` | Map of heater name → target |
| `{PLR.toolhead.extruder}` | Active extruder name |
| `{PLR.fan_speed}` | Part fan PWM |
| `{PLR.move_speed_percent}` | M220 |
| `{PLR.extrude_speed_percent}` | M221 |

Dump everything with `M118 {PLR}`.

### `paused_recover_z` vs `_CLIENT_VARIABLE` (mandatory if you customize park)

Official Lite 2.1 KPPM page: if `variable_use_custom_pos: True`, `paused_recover_z` must be the **opposite sign** of `variable_custom_park_dz`.

| `variable_custom_park_dz` | `paused_recover_z` |
| --- | --- |
| `5` | `-5` |
| `-3` | `3` |
| default `2.0` (client file) | official template uses `-2.0` |

Wrong signs give a bad Z on resume.

### `[homing_override]` contract (only if you already use one)

Official warning: do not arbitrarily set a homing pose inside `[homing_override]` or PLR fails.

Required extras:

```cfg
[force_move]
enable_force_move: true
```

Use `SET_KINEMATIC_POSITION` / `force_move` instead of `set_position_z` inside the override. Official Lite 2.1 snippet is in `klipper/host-fragments/homing-override-plr.cfg`.

---

## 9. USB LIS2DW / ADXL (input shaper)

Lite 2.1 cannot drive a bare SPI/I2C ADXL on host pins. Official options:

1. **FLY-USB-LIS2DW** in a USB-A port.
2. Toolboard with a built-in LIS2DW or ADXL345.

Official USB LIS2DW pins (RP2040 on the dongle, **not** the Lite):

```cfg
[mcu LIS]
serial: /dev/serial/by-id/usb-Klipper_rp2040_<id>

[lis2dw]
cs_pin: LIS:gpio9
spi_software_sclk_pin: LIS:gpio10
spi_software_mosi_pin: LIS:gpio11
spi_software_miso_pin: LIS:gpio12

[resonance_tester]
accel_chip: lis2dw
probe_points: 150, 150, 20
min_freq: 5
max_freq: 133
accel_per_hz: 75
hz_per_sec: 1
```

USB ADXL345 variant (same RP2040 GPIO set, different section name):

```cfg
[mcu adxl]
serial: /dev/serial/by-id/usb-Klipper_rp2040_<id>

[adxl345]
cs_pin: adxl:gpio9
spi_software_sclk_pin: adxl:gpio10
spi_software_mosi_pin: adxl:gpio11
spi_software_miso_pin: adxl:gpio12

[resonance_tester]
accel_chip: adxl345
probe_points: 100, 100, 20
```

### Console macros / commands

| Command | When |
| --- | --- |
| `ACCELEROMETER_QUERY` | Prove the chip talks |
| `ACCELEROMETER_QUERY CHIP=<name>` | Multi-chip |
| `SHAPER_CALIBRATE` | X and Y |
| `SHAPER_CALIBRATE AXIS=X` | One axis |
| `SAVE_CONFIG` | Persist `shaper_type` / `shaper_freq` |
| `TEST_RESONANCES AXIS=X` | Raw sweep |
| `M112` | Estop if the bed walks |

Debian extras (FlyOS-FAST already has them):

```bash
sudo apt install python3-numpy python3-matplotlib libatlas-base-dev
~/klippy-env/bin/pip install matplotlib numpy
```

512 MB RAM: expect this to be tight. Add zram/swap before `SHAPER_CALIBRATE`.

---

## 10. Minimum `printer.cfg` skeleton (host side)

Printer-MCU pins are omitted on purpose.

```cfg
[include plr.cfg]
[include fluidd.cfg]
# [include mainsail.cfg]

[mcu]
serial: /dev/serial/by-id/usb-Klipper_<fill-from-ls>

[mcu host]
serial: /tmp/klipper_host_mcu

# Optional USB accel — see section 9
# [include usb-lis2dw.cfg]

[gcode_macro _CLIENT_VARIABLE]
variable_use_custom_pos: False
variable_custom_park_dz: 2.0
gcode:

# [stepper_x] … [printer] … come from YOUR motion MCU datasheet
```

Host-only fragments in this repo:

| File | Contents |
| --- | --- |
| `klipper/host-fragments/mcu-host.cfg` | `[mcu host]` |
| `klipper/host-fragments/plr.cfg` | Official Lite 2.1 PLR |
| `klipper/host-fragments/client-variables.cfg` | Full `_CLIENT_VARIABLE` |
| `klipper/host-fragments/homing-override-plr.cfg` | Official PLR homing override |
| `klipper/host-fragments/usb-lis2dw.cfg` | Official USB LIS2DW |

---

## 11. Console, SSH, and power (not Klipper pins, but required)

| Link | Value |
| --- | --- |
| Wi-Fi (this board) | `192.168.1.147` (user-reported, DHCP — may change) |
| Serial | Type-C on the PC as **COM4**, **115200 8N1** |
| FlyOS user | `root` |
| FlyOS password | `mellow` |
| Type-C power | ≥ 5 V / 2 A, data-capable cable if you want serial |
| 5 V terminal | ZH-1.5-2P, independent of the MCU |
| Wi-Fi | Onboard 2.4 GHz only, IPEX1 antenna, no Chinese SSID |
| Wi-Fi tool on FAST | `nmtui` |
| Web UI | `http://192.168.1.147/` |

FAST is root-only and mostly read-only (`/etc` and `/data` writable). You cannot treat it as Debian. Pull artifacts from it, then install Klipper on a real Debian image.

---

## 12. After a live pull — fill these blanks

Run `scripts/pull-live-flyos.sh` from a machine that can reach `192.168.1.147`. Then paste into this section:

| Item | File in `flyos-artifacts/live/` | Why |
| --- | --- | --- |
| `sys-config.conf` | `sys-config.conf` | Exact `screen=`, `shutdown_pin=` |
| `/proc/device-tree` | `device-tree.tar` | TFT / MMC1 / USB OTG GPIOs |
| `*.dtb` | `dtb/` | Debian overlay source |
| `printer.cfg` + includes | `klipper-config/` | Stock macros on this image |
| `dmesg` | `dmesg.txt` | Wi-Fi chip, serial gadget |
| `gpioinfo` | `gpioinfo.txt` | Confirm `gpiochip1` line 8 |

Until that dump exists, treat TFT SPI reset/DC/backlight GPIOs as **unknown**. The candidate overlay `overlays/fly-tft-spi-candidate.dts` stays disabled.

---

## 13. Source list

- [Lite 2.1 product](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/)
- [Lite 2.1 SSH / serial](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/host/ssh)
- [Lite 2.1 Wi-Fi](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/host/wifi)
- [Lite 2.1 screen / sys-config](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/host/screen)
- [Lite 2.1 KPPM / PLR / macros](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/advanced/kppm/)
- [Lite 2.1 accelerometer limits](https://mellow.klipper.cn/en/docs/ProductDoc/SBC/fly-lite/lite2.1/advanced/adxl/)
- [USB LIS2DW reference config](https://mellow.klipper.cn/en/docs/ProductDoc/ToolBoard/fly-usb-adxl/fly-usb-lis2dw/cfg)
- [Fluidd/Mainsail client.cfg](https://github.com/fluidd-core/fluidd-config/blob/master/client.cfg) (same macros as Mainsail)
- [Orange Pi Lite DTS](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/arm/boot/dts/allwinner/sun8i-h3-orangepi-lite.dts)
