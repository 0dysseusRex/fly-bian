#!/usr/bin/env bash
# Continue Fly-bian rebuild: simpleaf then kiauh (base already OK this run).
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build

find "$root/scripts" -maxdepth 1 -type f -name '*.sh' -exec sed -i 's/\r$//' {} +
find "$root/armbian/userpatches" -type f \
	\( -name '*.sh' -o -name '*.csc' -o -name '*.service' -o -name 'fly-help' -o -name 'fly-start' \) \
	-exec sed -i 's/\r$//' {} +
bash "$root/scripts/stage-armbian-overlay.sh"
cp -a "$root/FLYBIAN_VERSION" "$root/armbian/userpatches/overlay/FLYBIAN_VERSION"

# Dry-run patch against fresh pellcorp
tmpdir=$(mktemp -d)
git clone --depth 1 https://github.com/pellcorp/creality.git "$tmpdir/creality"
bash "$root/armbian/userpatches/overlay/simpleaf/patch-install-klipper.sh" \
	"$tmpdir/creality/rpi/install-klipper.sh"
rm -rf "$tmpdir"
echo "patch dry-run OK"

{
	echo "=== $(date -Is) CONTINUE simpleaf+kiauh after patch fix ==="
	for flavor in simpleaf kiauh; do
		echo "=== $(date -Is) START flavor=$flavor ==="
		if bash "$root/scripts/run-armbian-compile.sh" "$flavor"; then
			echo "=== $(date -Is) OK flavor=$flavor ==="
		else
			rc=$?
			echo "=== $(date -Is) FAIL flavor=$flavor rc=$rc ==="
			exit "$rc"
		fi
	done
	echo "=== $(date -Is) ALL DONE (continue) ==="
	ls -lh /home/rex/fly-build/armbian-build/output/images/*.xz | tail -n 20
} >>"$build/compile-all.log" 2>&1
