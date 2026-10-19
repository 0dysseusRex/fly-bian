#!/usr/bin/env bash
set -euo pipefail
export PATH="/mnt/wsl/docker-desktop/cli-tools/usr/bin:/usr/bin:${PATH:-/usr/bin}"
hash -r || true
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build/armbian-build
flavor=${1:-base}

# Default kernel branch for Lite (H3). Pi V3 overrides to legacy (6.12).
branch=current
case "$flavor" in
	base|minimal)
		board=fly-lite-21
		flavor=base
		device=Fly-Lite-2.1
		;;
	simpleaf)
		board=fly-lite-21-simpleaf
		device=Fly-Lite-2.1
		;;
	kiauh)
		board=fly-lite-21-kiauh
		device=Fly-Lite-2.1
		;;
	pi-v3|fly-pi-v3|pi-v3-base|fly-pi-v3-base)
		board=fly-pi-v3
		flavor=base
		device=Fly-Pi-V3
		# FlyOS-aligned: sunxi64 legacy=6.12 (closest to OEM 6.6.75); not 6.18.
		branch=legacy
		;;
	*)
		echo "usage: $0 base|simpleaf|kiauh|pi-v3" >&2
		exit 1
		;;
esac
branch=${FLY_BRANCH:-$branch}

# Allow caller override (e.g. FLY_DEVICE already set).
export FLY_DEVICE="${FLY_DEVICE:-$device}"

log=/home/rex/fly-build/compile-${flavor}-${board}.log
# Keep a short alias for Base Lite compatibility with older monitors.
if [[ $board == fly-lite-21 && $flavor == base ]]; then
	log=/home/rex/fly-build/compile-base.log
fi

# Block reuse of an already-staged version for this flavor (docs/image-naming.md).
# Same version may still build the other two flavors in one release.
FLY_DEVICE="$FLY_DEVICE" bash "$root/scripts/flybian-require-new-version.sh" "$flavor"

mkdir -p "$build/userpatches" "$build/config/boards"
rsync -a "$root/armbian/userpatches/" "$build/userpatches/"
printf '%s\n' "$flavor" >"$build/userpatches/overlay/fly-flavor"
# Product version for /etc/fly-debian/flybian-version (see docs/image-naming.md).
# Pi V3 stays 0.70 until its own Base is the benchmark. The repo file is the Lite line.
if [[ $board == fly-pi-v3 ]]; then
	printf '0.70\n' >"$build/userpatches/overlay/FLYBIAN_VERSION"
else
	cp -a "$root/FLYBIAN_VERSION" "$build/userpatches/overlay/FLYBIAN_VERSION"
fi
cp -a "$root/armbian/userpatches/config/boards/"*.csc "$build/config/boards/"
# Windows checkout often has CRLF; a lone CR line makes bash Error 127.
find "$build/userpatches" "$build/config/boards" -type f \
	\( -name '*.sh' -o -name '*.csc' -o -name '*.config' -o -name '*.service' -o -name '*.patch' \) \
	-exec sed -i 's/\r$//' {} +

compile_overlay_dts() {
	local dts=$1
	local dtbo=${dts%.dts}.dtbo
	[[ -f $dts ]] || return 0
	if command -v dtc >/dev/null; then
		dtc -@ -I dts -O dtb -o "$dtbo" "$dts" || true
	fi
	local rel_dts=${dts#"$root/armbian/userpatches/overlay/"}
	local rel_dtbo=${rel_dts%.dts}.dtbo
	mkdir -p "$build/userpatches/overlay/$(dirname "$rel_dts")"
	cp -a "$dts" "$build/userpatches/overlay/$rel_dts" 2>/dev/null || true
	[[ -f $dtbo ]] && cp -a "$dtbo" "$build/userpatches/overlay/$rel_dtbo" 2>/dev/null || true
}

compile_overlay_dts "$root/armbian/userpatches/overlay/hdmi/fly-lite-hdmi.dts"
for dts in \
	"$root/armbian/userpatches/overlay/hdmi/fly-pi-v3-hdmi.dts" \
	"$root/armbian/userpatches/overlay/usb/fly-pi-v3-usb.dts" \
	"$root/armbian/userpatches/overlay/tft/fly-pi-v3-tft.dts" \
	"$root/armbian/userpatches/overlay/tft/fly-pi-v3-tft-c.dts" \
	"$root/armbian/userpatches/overlay/io/fly-pi-v3-io.dts"
do
	compile_overlay_dts "$dts"
done

cd "$build"

# Upstream Armbian sunxi series drifts vs linux-stable. Disable broken patches
# that do not affect Fly boards (leading "-" in series.conf).
mkdir -p "$build/userpatches/disabled-upstream-patches"
disable_series_patch() {
	local archive=$1
	local rel=$2
	local series=$build/patch/kernel/archive/$archive/series.conf
	local patch=$build/patch/kernel/archive/$archive/$rel
	local parked=$build/userpatches/disabled-upstream-patches/$(basename "$rel")
	if [[ -f $parked && ! -f $patch ]]; then
		mkdir -p "$(dirname "$patch")"
		cp -a "$parked" "$patch"
	fi
	if [[ -f $series ]] && grep -qE "^[[:space:]]*${rel//\//\\/}[[:space:]]*$" "$series"; then
		sed -i -E "s|^([[:space:]]*)${rel//\//\\/}[[:space:]]*$|\\1- ${rel}|" "$series"
		echo "fly-build: disabled $rel in $archive/series.conf"
	fi
}

if [[ $branch == current ]]; then
	# sun4i-a10 only — reversed/already applied on current 6.18.y
	disable_series_patch sunxi-6.18 patches.armbian/arm-dts-sun4i-a10-fix-pmu-interrupt.patch
	# PinePhone light-sensor megous stack — fails hunk apply; unused on Lite
	disable_series_patch sunxi-6.18 patches.megous/stk3310-6.18/0001-iio-light-stk3310-Implement-vdd-supply-and-power-it-.patch
	disable_series_patch sunxi-6.18 patches.megous/stk3310-6.18/0002-iio-light-stk3310-Add-support-for-I2C-regulator.patch
	disable_series_patch sunxi-6.18 patches.megous/stk3310-6.18/0003-iio-stk3310-Fix-regulator-disable-enable-order.patch
fi

if [[ $branch == legacy ]]; then
	# Pi V3 (H618): sunxi-6.12 vs linux-6.12.y tip — unused SoC patches fail apply.
	# Display series stays on: FPC-HDMI needs the H616 HDMI PHY and DE33 mixer.
	# The VI-scaler patch is rebased onto 6.12 (userpatches copy installed below).
	series_legacy=$build/patch/kernel/archive/sunxi-6.12/series.conf
	# Reset series so prior rebake "-" disables do not accumulate / hide entries.
	if [[ -d $build/.git ]]; then
		git -C "$build" checkout -- patch/kernel/archive/sunxi-6.12/series.conf 2>/dev/null || true
	fi
	disable_series_patch sunxi-6.12 patches.megous/arm64-dts-sun50i-a64-pinephone-Add-mount-matrix-for-acceleromet.patch
	disable_series_patch sunxi-6.12 patches.armbian/Correct-perf-interrupt-source-number-as-referenced-in-the-Allwi.patch
	disable_series_patch sunxi-6.12 patches.armbian/enable-TV-Output-on-OrangePi-Zero-LTE.patch
	yuv_rel=patches.drm/drm-sun4i-support-YUV-formats-in-VI-scaler.patch
	yuv_src=$root/armbian/userpatches/kernel/archive/sunxi-6.12/$yuv_rel
	yuv_dst=$build/patch/kernel/archive/sunxi-6.12/$yuv_rel
	if [[ -f $yuv_src ]]; then
		mkdir -p "$(dirname "$yuv_dst")"
		cp -a "$yuv_src" "$yuv_dst"
		sed -i 's/\r$//' "$yuv_dst"
		echo "fly-build: installed rebased $yuv_rel"
	fi
	# H616 EMAC1 (the Fly Pi V3 jack). Stock dwmac-sun8i only programs EMAC0.
	emac1_rel=patches.armbian/drv-net-stmmac-h616-emac1.patch
	emac1_src=$build/userpatches/kernel/archive/sunxi-6.12/$emac1_rel
	emac1_dst=$build/patch/kernel/archive/sunxi-6.12/$emac1_rel
	if [[ -f $emac1_src && -f $series_legacy ]]; then
		mkdir -p "$(dirname "$emac1_dst")"
		cp -a "$emac1_src" "$emac1_dst"
		if ! grep -qF "$emac1_rel" "$series_legacy"; then
			printf '%s\n' "$emac1_rel" >>"$series_legacy"
			echo "fly-build: enabled $emac1_rel"
		fi
	fi
	# AC200 on Fly Pi V3 uses the vendor compatible strings.
	for ac_rel in \
		patches.armbian/drv-mfd-ac200-fly-pi-v3.patch \
		patches.armbian/drv-phy-ac200-ephy-fly-pi-v3.patch \
		patches.armbian/drv-phy-ac200-phy-fly-pi-v3.patch \
		patches.armbian/drv-pwm-sunxi-enhance-fly-pi-v3.patch
	do
		ac_src=$build/userpatches/kernel/archive/sunxi-6.12/$ac_rel
		ac_dst=$build/patch/kernel/archive/sunxi-6.12/$ac_rel
		if [[ -f $ac_src && -f $series_legacy ]]; then
			mkdir -p "$(dirname "$ac_dst")"
			cp -a "$ac_src" "$ac_dst"
			if ! grep -qF "$ac_rel" "$series_legacy"; then
				printf '%s\n' "$ac_rel" >>"$series_legacy"
				echo "fly-build: enabled $ac_rel"
			fi
		fi
	done
fi

DOCKER_EXTRA_ARGS=(--dns 8.8.8.8 --dns 1.1.1.1 -e PESTER_TERMINAL=no)
# Pi V3 builds aic8800 against the kernel inside the compile container.
if [[ -d /home/rex/fly-build/aic8800 ]]; then
	DOCKER_EXTRA_ARGS+=(--mount type=bind,source=/home/rex/fly-build/aic8800,target=/fly-aic8800)
fi
export DOCKER_EXTRA_ARGS
# Skip Armbian's WSL2 "press ENTER in Windows Terminal" countdown (blocks tmux/nohup).
export PESTER_TERMINAL=no
# Also satisfy the WT_SESSION short-circuit if a TTY is present (tmux).
export WT_SESSION="${WT_SESSION:-fly-bian-build}"
echo "fly-build: BOARD=$board flavor=$flavor device=$FLY_DEVICE BRANCH=$branch log=$log PESTER_TERMINAL=$PESTER_TERMINAL"
# Source, do not exec. compile.sh reads the DOCKER_EXTRA_ARGS array from
# this shell; a child process would not inherit a bash array.
# Drop nounset so Armbian's own unset variables are unchanged.
set +u
# No stdin TTY → wsl2_pester returns immediately.
source ./compile.sh build \
	BOARD="$board" \
	BRANCH="$branch" \
	RELEASE=trixie \
	BUILD_MINIMAL=yes \
	BUILD_DESKTOP=no \
	KERNEL_CONFIGURE=no \
	COMPRESS_OUTPUTIMAGE=sha,xz \
	EXPERT=yes \
	</dev/null
