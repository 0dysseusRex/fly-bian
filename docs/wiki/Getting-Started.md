# Getting started - flash and set up Fly-bian

This guide assumes you have **not** flashed Linux SBC images before. Follow it top to bottom.

**Today this walkthrough is for Fly Lite 2.1** (images exist). For Fly Pi V3 status, see [Fly Pi V3](Fly-Pi-V3.md).

---

## What you need

| Item | Notes |
| --- | --- |
| Fly Lite 2.1 board | Antenna fitted on the IPEX Wi-Fi connector before first boot |
| MicroSD card | **8 GB or larger** (32 GB is fine). Class 10 / A1 recommended |
| USB MicroSD reader | So your PC can write the card |
| 5 V power supply | **Independent 5 V** for the board - **not** power from a printer MCU |
| Computer | Windows, macOS, or Linux |
| Optional | Type-C data cable (serial), or FPC-HDMI + USB keyboard |

---

## Step 1 - Choose an image

Download from [Releases](https://github.com/0dysseusRex/fly-bian/releases) (latest **Fly-bian 1.0** or newer). Pick **one**:

| File name contains | Choose this if... |
| --- | --- |
| `_Base` | You only want Debian/Armbian and will install Klipper yourself later |
| `_Simple-AF` | You want [pellcorp Simple-AF](https://github.com/pellcorp/creality) already on the card -> use `fly-start` after login |
| `_KIAUH` | You want [KIAUH](https://github.com/dw-0/kiauh) already on the card -> use `fly-kiauh` after login |

Also download the matching `.img.xz.sha` if you want to verify the file.

Do **not** mix Simple-AF and KIAUH on one card. Do **not** flash Raspberry Pi OS or Mainsail OS onto this board.

---

## Step 2 - (Optional) Check the download

On Windows (PowerShell), in the folder with the file:

```powershell
Get-FileHash .\Fly-bian-1.0_Fly-Lite-2.1_Simple-AF-0d21afe.img.xz -Algorithm SHA256
```

Compare the hash to the `.sha` file or the release notes. On macOS/Linux: `shasum -a 256 yourfile.img.xz`.

---

## Step 3 - Install a flasher

Easiest options (pick one):

1. **[Raspberry Pi Imager](https://www.raspberrypi.com/software/)** (free, Windows/macOS/Linux) - recommended for beginners
2. **[balenaEtcher](https://etcher.balena.io/)** - also simple; often accepts `.img.xz` directly

You do **not** need to manually unzip the `.xz` if the flasher supports compressed images (Pi Imager and Etcher usually do).

---

## Step 4 - Write the image to the MicroSD

### Raspberry Pi Imager

1. Insert the MicroSD (USB reader).
2. Open Raspberry Pi Imager.
3. **Device** - choose "No filtering" / any device if asked (this is not a Raspberry Pi board; filtering does not matter).
4. **Operating system** -> **Use custom** -> select your `Fly-bian-...img.xz`.
5. **Storage** -> select your MicroSD (double-check the drive letter/size so you do not wipe the wrong disk).
6. Click **Next**. If it offers OS customisation (Wi-Fi/user), you can **skip** - Fly-bian uses `FLY-SETUP` / `fly-start.txt` instead.
7. Confirm that you want to erase the card and wait until it finishes.
8. When done, **eject** the card in the OS, then unplug and plug the reader back in (important for the next step).

### balenaEtcher

1. Flash from file -> select the `.img.xz`.
2. Select the MicroSD target.
3. Flash -> wait -> eject safely -> unplug/replug the reader.

---

## Step 5 - Edit `FLY-SETUP` (recommended: headless Wi-Fi + SSH)

After flashing and replugging the card, your PC should show a small drive named **`FLY-SETUP`**.

Open it. You should see at least:

- `fly-start.txt`
- `README.txt`

Open **`fly-start.txt`** in Notepad (Windows), TextEdit (macOS), or any plain-text editor.

Replace the `Your...` placeholders you care about. For SSH with **no** serial cable, fill **all** of:

```text
WIFI_SSID=your 2.4 GHz network name
WIFI_PSK=your wifi password
WIFI_COUNTRY=US

LOCALE=en_US.UTF-8
TIMEZONE=America/Los_Angeles

ROOT_PASSWORD=choose-a-root-password
USER_NAME=fly
USER_PASSWORD=choose-a-user-password
USER_REALNAME=Your Name
```

Notes:

- Wi-Fi is **2.4 GHz only**.
- `USER_NAME` must be lowercase (this is your SSH login).
- Leave `USE_STATIC=0` unless you know you need a fixed IP.
- Passwords in this file are **plaintext** - do not share the card after editing.
- On **Simple-AF** you can also set `INSTALL_CMD`, `AUTO_CAMERAS`, `ENABLE_GRUMPYSCREEN`, `INSTALL_BOOT_DISPLAY` (see comments in the file).
- On **KIAUH**, Wi-Fi/accounts are enough; finish Klipper with `fly-kiauh` after login.

Save the file. **Eject `FLY-SETUP` safely.**

If you leave `YourUser` / `YourRootPassword`, the on-screen first-run wizard still runs (serial or HDMI).

---

## Step 6 - Hardware checklist before power

See also [Fly Lite 2.1](Fly-Lite-2.1.md).

1. Fit the **IPEX Wi-Fi antenna**.
2. Insert the MicroSD fully into the Lite.
3. Connect **independent 5 V** power (not the printer MCU 5 V rail).
4. Optional: Type-C to PC for serial, or FPC-HDMI + USB keyboard for the wizard.

---

## Step 7 - First boot (wait)

Power on. First boot can take **several minutes**:

- Debian partition grows to fill the card
- A **2 GB swapfile** is created
- Wi-Fi joins if you filled `fly-start.txt`

Do not yank power in the first few minutes unless it is clearly stuck for a very long time. Soft `reboot` on this board often hangs - if you must recover, use a **5 V power cycle**, and wait a few minutes between cycles.

---

## Step 8 - Find the board and SSH in

1. Look up the IP on your router's DHCP client list (hostname is often like `fly-lite-21`).
2. From your PC:

```bash
ssh USER_NAME@THE.PRINTER.IP
```

Example: `ssh fly@192.168.1.147`

3. Accept the host key; log in with the password you set.

Then:

```bash
fly-help
```

| Image | Next command |
| --- | --- |
| Simple-AF | `fly-start` |
| KIAUH | `fly-kiauh` |
| Base | Install Simple-AF or KIAUH yourself when ready |

### If you did not fill `fly-start.txt`

- **Serial:** Type-C data cable, **115200 8N1**, no flow control. Answer the wizard. Do **not** toggle DTR/RTS "to reset".
- **Screen:** FPC-HDMI + USB keyboard; leave FPC-TFT unplugged for first wizard.

---

## Step 9 - Finish Klipper (Simple-AF or KIAUH)

### Simple-AF image

```bash
fly-start
```

Or run the installer with your printer/probe/mount (see [pellcorp printer definitions](https://pellcorp.github.io/creality-wiki/rpi_printer_definitions/)):

```bash
~/pellcorp/installer.sh --install --printer YOUR_PRINTER --probe YOUR_PROBE --mount Default
```

More detail: [Simple-AF how-to](https://github.com/0dysseusRex/fly-bian/blob/main/docs/howto-simpleaf.md) / [RPi wiki](https://pellcorp.github.io/creality-wiki/rpi/).

On 512 MB prefer **GrumpyScreen**, not KlipperScreen.

### KIAUH image

```bash
fly-kiauh
```

Use the menu to enable what you need; set your MCU serial in `~/printer_data/config/printer.cfg`.
More detail: [KIAUH how-to](https://github.com/0dysseusRex/fly-bian/blob/main/docs/howto-kiauh.md).

### USB cameras (either stack)

```bash
fly-crowsnest-add-cams
```

---

## Common mistakes

| Mistake | What to do instead |
| --- | --- |
| Powering from printer MCU 5 V | Use a dedicated 5 V supply |
| No Wi-Fi antenna | Fit IPEX antenna before boot |
| Flashed wrong OS (Pi OS, etc.) | Only Fly-bian `Fly-Lite-2.1` images |
| Expected SSH with only Wi-Fi filled | Also set root + user in `fly-start.txt` |
| Rebooted during a long install | Wait; check SSH session - then power-cycle if truly stuck |
| Installed every Moonraker add-on on 512 MB | See [OOM guide](https://github.com/0dysseusRex/fly-bian/blob/main/docs/boards/fly-lite-2.1/oom.md) |

---

## Next pages

- [Fly Lite 2.1](Fly-Lite-2.1.md) - board-specific tips
- [Fly Pi V3](Fly-Pi-V3.md) - status and what not to flash
