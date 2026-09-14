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

# Block reuse of an already-staged version for this flavor (docs/image-naming.md).
# Same version may still build the other two flavors in one release.
bash "$root/scripts/flybian-require-new-version.sh" "$flavor"

mkdir -p "$build/userpatches" "$build/config/boards"
rsync -a "$root/armbian/userpatches/" "$build/userpatches/"
printf '%s\n' "$flavor" >"$build/userpatches/overlay/fly-flavor"
# Product version for /etc/fly-debian/flybian-version (see docs/image-naming.md)
cp -a "$root/FLYBIAN_VERSION" "$build/userpatches/overlay/FLYBIAN_VERSION"
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
DOCKER_EXTRA_ARGS=(--dns 8.8.8.8 --dns 1.1.1.1 -e PESTER_TERMINAL=no)
export DOCKER_EXTRA_ARGS
# Skip Armbian's WSL2 "press ENTER in Windows Terminal" countdown (blocks tmux/nohup).
export PESTER_TERMINAL=no
# Also satisfy the WT_SESSION short-circuit if a TTY is present (tmux).
export WT_SESSION="${WT_SESSION:-fly-bian-build}"
echo "fly-build: BOARD=$board flavor=$flavor log=$log PESTER_TERMINAL=$PESTER_TERMINAL"
# No stdin TTY → wsl2_pester returns immediately.
exec ./compile.sh build \
	BOARD="$board" \
	BRANCH=current \
	RELEASE=trixie \
	BUILD_MINIMAL=yes \
	BUILD_DESKTOP=no \
	KERNEL_CONFIGURE=no \
	COMPRESS_OUTPUTIMAGE=sha,xz \
	EXPERT=yes \
	</dev/null
