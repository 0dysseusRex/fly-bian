# Copied to /tmp/overlay during Armbian customize-image.sh.
# Stage files from this git repo before compile:

#   mkdir -p armbian/userpatches/overlay/cpu-affinity
#   mkdir -p armbian/userpatches/overlay/first-boot
#   cp klipper/cpu-affinity/* armbian/userpatches/overlay/cpu-affinity/
#   cp first-boot/fly-net.txt first-boot/README.txt armbian/userpatches/overlay/first-boot/
#
# customize-image.sh copies fly-net.txt + README.txt onto /boot (the FAT
# volume). fly-windows-bootfs labels that volume FLY-SETUP (not armbi_boot).

# swapfile/ is native to userpatches (not copied from repo root).
# customize-image.sh installs fly-swapfile.service; the 2 GiB file is
# created on first boot after the rootfs grows, not during the image build.
#
# simpleaf/ and kiauh/ are flavor bakes (git + venvs under /opt). The
# compile launcher writes overlay/fly-flavor. Base fly-lite-21 does not
# bake a Klipper stack. Do not mix Simple-AF and KIAUH on one card.
#
# motd/ is the Fly-bian SSH splash (replaces Armbian-unofficial figlet).
# customize-image.sh installs it and patches 10-armbian-header.
#
# hdmi/fly-lite-hdmi.dts enables &hdmi (Fly DTB ships it disabled).
# from-golden/ also has the compiled .dtbo plus DTB, TFT firmware, and
# 8189fs / isolcpus units — customize-image.sh installs those too.
