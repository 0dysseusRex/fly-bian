# Mellow Fly Pi V3 (Allwinner H618). Start from Orange Pi Zero3 U-Boot
# defconfig (+ board_fly-pi-v3 eMMC/mmc2 patch), then install Fly
# `fly-h618.dtb` in customize-image. HDMI/USB/TFT via user overlays.
# Peer: upstream Armbian mellowflyc5 (same SoC family) — see
# docs/community-alternate-firmware.md.
# Kernel: OEM FlyOS-FAST is 6.6.75; Armbian sunxi64 has no 6.6 — use
# BRANCH=legacy (6.12), not current (6.18) which D-state hung bring-up.
# sun50iw9.conf only wires ATF_PLAT for current|edge; set it here so legacy
# BL31 builds (PLAT=sun50i_h616) — required before sunxi64_common expands
# ATF_TARGET_MAP.
ATF_PLAT="sun50i_h616"
BOARD_NAME="Fly Pi V3"
BOARDFAMILY="sun50iw9"
BOARD_MAINTAINER=""
BOOTCONFIG="orangepi_zero3_defconfig"
OVERLAY_PREFIX="sun50i-h616"
KERNEL_TARGET="legacy,current,edge"
KERNEL_TEST_TARGET="legacy"
FULL_DESKTOP="no"
BOOT_LOGO="desktop"
FORCE_BOOTSCRIPT_UPDATE="yes"

# FAT volume Windows/macOS/Linux can mount (FLY-SETUP via fly-windows-bootfs).
BOOTFS_TYPE="fat"
BOOTSIZE="256"

# Do not enable Orange Pi uwe5622 — Fly M2 modules use rtl8821cs / aic8800.
# rfkill + mmc-utils: same as upstream mellowflyc5 (RTL8821CS / eMMC bring-up).
DEFAULT_OVERLAYS=""
PACKAGE_LIST_BOARD="rfkill mmc-utils"
ENABLE_EXTENSIONS="wsl-docker-dns fly-windows-bootfs"

# Belt-and-suspenders with board_fly-pi-v3 u-boot patch: SPL must init mmc2
# or eMMC boot fails with "MMC Device 1 not found" (C5 lesson).
function post_config_uboot_target__fly_pi_v3_emmc() {
	display_alert "Enabling eMMC slot" "CONFIG_MMC_SUNXI_SLOT_EXTRA=2" "info"
	run_host_command_logged scripts/config --set-val CONFIG_MMC_SUNXI_SLOT_EXTRA 2
	run_host_command_logged scripts/config --enable CONFIG_SUPPORT_EMMC_BOOT
}

# The H616 HDMI PHY / DE33 series is enabled again. Pi V3 still boots OEM
# fly-h618.dtb, so omit the other H616/H618 board DTBs from the build.
function custom_kernel_config__fly_pi_v3_drop_broken_legacy_dtbs() {
	[[ ${BRANCH:-} == legacy ]] || return 0
	[[ -f .config ]] || return 0
	local mk=arch/arm64/boot/dts/allwinner/Makefile
	[[ -f $mk ]] || return 0
	display_alert "Pi V3 legacy" "Drop H616/H618/H700 board DTBs (OEM fly-h618.dtb)" "info"
	# Drop board .dtb targets only (keep .dtbo overlays). Pi V3 installs OEM
	# fly-h618.dtb; the other H616/H618 boards are not this image.
	sed -i -E \
		-e '/sun50i-h616-.*\.dtb/d' \
		-e '/sun50i-h618-.*\.dtb/d' \
		-e '/sun50i-h700-.*\.dtb/d' \
		-e '/sun50i-h313-.*\.dtb/d' \
		"$mk"
	# Hash must change when the drop list changes (kernel artifact cache).
	kernel_config_modifying_hashes+=("fly-pi-v3-drop-broken-legacy-dtbs-v2")
}

# Build the M2 AIC8800 modules against this kernel and ship them in linux-image.
# fly-apply insmods them after boot; modprobe.d keeps udev from loading them early.
function pre_package_kernel_image__fly_pi_v3_aic8800() {
	[[ ${BOARD:-} == fly-pi-v3 ]] || return 0
	local src=/fly-aic8800/src/SDIO/driver_fw/driver/aic8800
	local dest cross
	if [[ ! -d $src ]]; then
		exit_with_error "aic8800 source missing" "$src"
	fi
	if [[ -z ${kernel_work_dir:-} || -z ${kernel_version_family:-} ]]; then
		exit_with_error "aic8800 build missing kernel vars" "work=${kernel_work_dir:-} ver=${kernel_version_family:-}"
	fi
	dest="${tmp_kernel_install_dirs[INSTALL_MOD_PATH]}/lib/modules/${kernel_version_family}/kernel/drivers/net/wireless/aic8800"
	cross="${CROSS_COMPILE:-aarch64-linux-gnu-}"
	display_alert "Pi V3" "Build aic8800 for ${kernel_version_family}" "info"
	if ! command -v pahole >/dev/null 2>&1; then
		mkdir -p /tmp/fly-pahole-bin
		cat >/tmp/fly-pahole-bin/pahole <<'EOF'
#!/bin/sh
if [ "$1" = "--version" ]; then echo v1.25; exit 0; fi
exit 0
EOF
		chmod 755 /tmp/fly-pahole-bin/pahole
		export PATH="/tmp/fly-pahole-bin:${PATH}"
	fi
	run_host_command_logged make -C "${kernel_work_dir}" M="${src}" ARCH=arm64 CROSS_COMPILE="${cross}" clean
	run_host_command_logged make -C "${kernel_work_dir}" M="${src}" ARCH=arm64 CROSS_COMPILE="${cross}" modules
	mkdir -p "${dest}"
	run_host_command_logged cp -a "${src}/aic8800_bsp/aic8800_bsp.ko" "${src}/aic8800_fdrv/aic8800_fdrv.ko" "${dest}/"
}
