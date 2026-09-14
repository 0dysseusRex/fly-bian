Fly Lite 2.1 — first boot (Armbian / Debian)
============================================

This small FAT volume (FLY-SETUP) is meant to be opened on Windows, macOS, or
Linux after you flash the card and before you power the board.

You need: the MicroSD in a USB reader, the IPEX Wi-Fi antenna fitted, and a
5 V supply that is NOT the printer MCU. First boot can take several minutes
while Debian expands to fill the card and creates a 2 GB swap file.
Let it finish.

There are three ways to get a login. Pick one.


1) Text file (no cable) — recommended
-------------------------------------
Edit fly-start.txt in this folder with Notepad, TextEdit, or any editor.
Replace every Your… placeholder you want applied. For SSH with no serial
cable, fill all three of Wi-Fi, Root, and User:

  WIFI_SSID=your 2.4 GHz network name
  WIFI_PSK=the Wi-Fi password
  WIFI_COUNTRY=US

  LOCALE=en_US.UTF-8
  TIMEZONE=America/Los_Angeles

  ROOT_PASSWORD=a root password you choose
  USER_NAME=a lowercase login (this is who you SSH as)
  USER_PASSWORD=that user's password
  USER_REALNAME=Your Name

Optional Simple-AF helpers (used later by `fly-start` over SSH):

  INSTALL_CMD=~/pellcorp/installer.sh --install --printer … --probe …
  AUTO_CAMERAS=Yes
  INSTALL_BOOT_DISPLAY=Yes

Leave USE_STATIC=0 unless you know you need a fixed IP.

Save. Eject the card safely. Put it in the Fly Lite. Power on. Wait until
the card has grown, the 2 GB swap file is there, and the radio has joined
(often 3–8 minutes on first boot). Then find the board on your router
(DHCP list) and:

  ssh USER_NAME@THE.PRINTER.IP
  fly-help
  fly-start

There is no pre-made account in the image. The name and password are
whatever you put in fly-start.txt.

If you leave USER_NAME=YourUser or ROOT_PASSWORD=YourRootPassword, the
on-screen first-run wizard still runs (use path 2 or 3). Wi-Fi alone is
not enough for SSH — a user has to exist first.

The onboard radio is 2.4 GHz only. Only wlan0 is used (wlan1 is a second
virtual iface from the same chip and stays down). Secrets in fly-start.txt
are plain text.


2) Serial (Type-C)
------------------
Use a data-capable Type-C cable. Independent 5 V.

Windows: Device Manager -> Ports (COM & LPT). Speed 115200, 8 data bits,
no parity, 1 stop bit, no flow control. It is often COM4.

macOS / Linux: /dev/ttyUSB0 or similar, same 115200 8N1.

Do not toggle DTR/RTS "to reset" — that does not reset this board and can
stop autoboot.

If fly-start.txt still has Your… placeholders, answer the on-screen questions
(root password, your user, location, Wi-Fi). If you already filled those
fields, you can log in with that user; you do not need to repeat the wizard.


3) Keyboard and screen
----------------------
Plug a screen into the FPC-HDMI cable and a USB keyboard into a USB-A port.
Leave the small FPC-TFT unplugged for this first boot.

Power on. If the text file was left as placeholders, answer the first-run
questions here. Then set Wi-Fi in the menus if you skipped the text file.


If it looks stuck
-----------------
First boot is slow: resize, then swapfile, then Wi-Fi if you filled
fly-start.txt. A reboot that never finishes is normal to fix with a 5 V
power cycle (soft reboot can hang on this board).
