Fly Lite 2.1 — first boot (Armbian / Debian)
============================================

This small FAT volume (FLY-SETUP) is meant to be opened on Windows, macOS, or
Linux after you flash the card and before you power the board.

You need: the MicroSD in a USB reader, the IPEX Wi-Fi antenna fitted, and a
5 V supply that is NOT the printer MCU. First boot can take several minutes
while Debian expands to fill the card. Let it finish.

There are three ways to get a login. Pick one.


1) Wi-Fi file (no cable)
------------------------
Edit fly-net.txt in this folder with Notepad, TextEdit, or any editor.

  WIFI_ENABLED=1
  WIFI_SSID=the name of your 2.4 GHz network
  WIFI_PSK=the Wi-Fi password
  WIFI_COUNTRY=US     (change to your country code)

Leave USE_STATIC=0 unless you know you need a fixed IP.

Save. Eject the card safely. Put it in the Fly Lite. Power on.

When setup finishes, SSH in as the user YOU created on first boot
(not a pre-made account):

  ssh YOURUSER@THE.PRINTER.IP

The onboard radio is 2.4 GHz only. The password is stored in this file in
plain text. If you leave WIFI_SSID=YourNetwork, Wi-Fi will not join by itself.


2) Serial (Type-C)
------------------
Use a data-capable Type-C cable. Independent 5 V.

Windows: Device Manager -> Ports (COM & LPT). Speed 115200, 8 data bits,
no parity, 1 stop bit, no flow control. It is often COM4.

macOS / Linux: /dev/ttyUSB0 or similar, same 115200 8N1.

Do not toggle DTR/RTS "to reset" — that does not reset this board and can
stop autoboot.

Complete the on-screen first-run questions (password, your user). Then you
can use nmtui or nmcli to join Wi-Fi if you skipped the text file.


3) Keyboard and screen
----------------------
Plug a screen into the FPC-HDMI cable and a USB keyboard into a USB-A port.
Leave the small FPC-TFT unplugged for this first boot.

Power on, answer the first-run questions, then set Wi-Fi in the menus if
needed.


If it looks stuck
-----------------
Wait for the partition to grow. Then finish the first-run wizard — this
image is supposed to ask you for a user. A reboot that never comes back
usually needs a 5 V power cycle, not another software reboot.

More detail is in the Fly Debian git repository (README.md, first-boot/).
