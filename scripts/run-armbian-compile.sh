#!/usr/bin/env bash
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build/armbian-build
flavor=${1:-base}

case "$flavor" in
	base|minimal)
		board=fly-lite-21
		flavor=base
		;;
	simpleaf)
		board=fly-lite-21-simpleaf
		;;
	kiauh)
		board=fly-lite-21-kiauh
		;;
	*)
		echo "usage: $0 base|simpleaf|kiauh" >&2
		exit 1
		;;
esac

log=/home/rex/fly-build/compile-${flavor}.log

mkdir -p "$build/userpatches" "$build/config/boards"
rsync -a "$root/armbian/userpatches/" "$build/userpatches/"
printf '%s\n' "$flavor" >"$build/userpatches/overlay/fly-flavor"
cp -a "$root/armbian/userpatches/config/boards/"*.csc "$build/config/boards/"
# Windows checkout often has CRLF; a lone CR line makes bash Error 127.
find "$build/userpatches" "$build/config/boards" -type f \
	\( -name '*.sh' -o -name '*.csc' -o -name '*.config' -o -name '*.service' \) \
	-exec sed -i 's/\r$//' {} +

if command -v dtc >/dev/null && [[ -f $root/armbian/userpatches/overlay/hdmi/fly-lite-hdmi.dts ]]; then
	dtc -@ -I dts -O dtb \
		-o "$root/armbian/userpatches/overlay/hdmi/fly-lite-hdmi.dtbo" \
		"$root/armbian/userpatches/overlay/hdmi/fly-lite-hdmi.dts" || true
	cp -a "$root/armbian/userpatches/overlay/hdmi/fly-lite-hdmi.dtbo" \
		"$build/userpatches/overlay/hdmi/fly-lite-hdmi.dtbo" 2>/dev/null || true
fi

cd "$build"
DOCKER_EXTRA_ARGS=(--dns 8.8.8.8 --dns 1.1.1.1)
export DOCKER_EXTRA_ARGS
echo "fly-build: BOARD=$board flavor=$flavor log=$log"
exec ./compile.sh build \
	BOARD="$board" \
	BRANCH=current \
	RELEASE=trixie \
	BUILD_MINIMAL=yes \
	BUILD_DESKTOP=no \
	KERNEL_CONFIGURE=no \
	COMPRESS_OUTPUTIMAGE=sha,xz \
	EXPERT=yes
