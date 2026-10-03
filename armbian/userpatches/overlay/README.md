# Copied to /tmp/overlay during Armbian customize-image.sh.
# Stage files from this git repo before compile:

#   ./scripts/stage-armbian-overlay.sh
#   # or manually:
#   mkdir -p armbian/userpatches/overlay/cpu-affinity
#   mkdir -p armbian/userpatches/overlay/first-boot
#   cp klipper/cpu-affinity/* armbian/userpatches/overlay/cpu-affinity/
#   cp first-boot/fly-start.txt first-boot/README.txt armbian/userpatches/overlay/first-boot/
#
# customize-image.sh copies fly-start.txt + README.txt onto /boot (the FAT
# volume). fly-windows-bootfs labels that volume FLY-SETUP (not armbi_boot).
# tools/fly-help and tools/fly-start install to /usr/local/bin.

# swapfile/ is native to userpatches (not copied from repo root).
# customize-image.sh installs fly-swapfile.service; the 2 GiB file is
# created on first boot after the rootfs grows, not during the image build.
#
# simpleaf/ and kiauh/ are flavor bakes (git + venvs under /opt). The
# compile launcher writes overlay/fly-flavor. Base fly-lite-21 does not
# bake a Klipper stack. Do not mix Simple-AF and KIAUH on one card.
# simpleaf/pellcorp.done.software must NOT list "klipper" — that marker
# skips install-klipper.sh config staging (homing.cfg) and breaks
# --probe bltouch. bake.sh patches install-klipper to keep prebaked trees.
# Do not mark "crowsnest" either — first install must run `make install`.
#
# fly-bind-klipper-stack (first real user) also:
#   - applies pellcorp nginx sites (Mainsail :4409, Fluidd :80)
#   - runs Moonraker set-policykit-rules.sh (needs polkitd from customize)
#   - installs ARMv7 GrumpyScreen under ~/grumpyscreen (unit not enabled;
#     fly-start ENABLE_GRUMPYSCREEN controls enable + getty@tty1)
#   - INSTALL_BOOT_DISPLAY / fly-boot-display = Plymouth splash, not Grumpy
#     (fly-start menu 3 enable / 4 disable for diagnostic text boot)
#   - Simple-AF bake installs plymouth + simpleaf theme (bootlogo=false
#     until enabled); assets under overlay/simpleaf/plymouth/
#
# motd/ is the Fly-bian SSH splash (replaces Armbian-unofficial figlet).
# customize-image.sh installs it and patches 10-armbian-header, and adds
# Help→fly-help / Install→fly-start under Armbian MOTD Commands (41 + 42).
#
# boot/fly-boot-complete prints "Boot Complete" after multi-user.target
# (WantedBy=default.target) on ttyS0 / console / tty1 and /etc/issue.d.
#
# Console is multi-user + getty@tty1 (no greetd). network/fly-ip-announce
# prints wlan0 IPv4 on serial/HDMI and /etc/issue.d after network-online.
#
# simpleaf bake also hardens pellcorp config-helper (armhf SIGSEGV on
# remove-section-entry) and softens installer cleanup_probe || true.
#
# crowsnest/fly-crowsnest-add-cams → /usr/local/bin: SSH helper to discover
# USB V4L2 cams and append [cam] sections to ~/printer_data/config/crowsnest.conf.
# bake + strip-placeholders remove pellcorp [cam web] / /dev/video0 examples.
#
# hdmi/fly-lite-hdmi.dts enables &hdmi (Fly DTB ships it disabled).
# tft/fly-lite-tft.dts + fly-lite-tft-c.dts: ST7796 panel-mipi-dbi + Cap GT911.
# from-golden/firmware/ST7796S.bin + overlay-user copies; modules-load.d/fly-tft.conf.
# tools/fly-tft-check → /usr/local/bin. Cap DIP default (fly-lite-tft-c in user_overlays);
# Resi DIP: drop fly-lite-tft-c from armbianEnv.txt.
# from-golden/ also has DTB / 8189fs / isolcpus units — customize-image.sh installs those.
