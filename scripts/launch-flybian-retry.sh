#!/usr/bin/env bash
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build

echo "cleanup: docker"
docker ps -aq | xargs -r docker rm -f || true
# Avoid sudo (may hang for password under nohup). Lazy umount as user if possible.
find /home/rex/fly-build/armbian-build/.tmp -maxdepth 3 -type d 2>/dev/null | head
if [[ -d /home/rex/fly-build/armbian-build/.tmp ]]; then
	find /home/rex/fly-build/armbian-build/.tmp -mindepth 1 -maxdepth 1 -type d -print0 \
		| xargs -0 -r -I{} bash -c 'umount -l "$1/dev" 2>/dev/null || true; umount -l "$1" 2>/dev/null || true' _ {}
	rm -rf /home/rex/fly-build/armbian-build/.tmp/* 2>/dev/null || true
fi

sed -i 's/\r$//' "$root/scripts/"*.sh \
	"$root/armbian/userpatches/overlay/simpleaf/patch-install-klipper.sh" || true
bash "$root/scripts/stage-armbian-overlay.sh"
cp -a "$root/FLYBIAN_VERSION" "$root/armbian/userpatches/overlay/FLYBIAN_VERSION"

tmpdir=$(mktemp -d)
git clone --depth 1 https://github.com/pellcorp/creality.git "$tmpdir/creality"
bash "$root/armbian/userpatches/overlay/simpleaf/patch-install-klipper.sh" \
	"$tmpdir/creality/rpi/install-klipper.sh"
rm -rf "$tmpdir"
echo "patch dry-run OK"

{
	echo "=== $(date -Is) RETRY2 simpleaf+kiauh ==="
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
	echo "=== $(date -Is) ALL DONE (retry2) ==="
	ls -lh /home/rex/fly-build/armbian-build/output/images/*.xz | tail -n 20
} >>"$build/compile-all.log" 2>&1
