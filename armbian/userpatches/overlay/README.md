# Copied to /tmp/overlay during Armbian customize-image.sh.
# Stage files from this git repo before compile:

#   mkdir -p armbian/userpatches/overlay/cpu-affinity
#   mkdir -p armbian/userpatches/overlay/first-boot
#   cp klipper/cpu-affinity/* armbian/userpatches/overlay/cpu-affinity/
#   cp first-boot/fly-net.txt first-boot/README.txt armbian/userpatches/overlay/first-boot/

# swapfile/ is native to userpatches (not copied from repo root).
# customize-image.sh installs fly-swapfile.service; the 2 GiB file is
# created on first boot after the rootfs grows, not during the image build.
