#!/usr/bin/env bash
# Launch Fly-bian rebuild of base + simpleaf + kiauh in WSL.
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build

find "$root/scripts" -maxdepth 1 -type f -name '*.sh' -exec sed -i 's/\r$//' {} +
find "$root/armbian/userpatches" -type f \
	\( -name '*.sh' -o -name '*.csc' -o -name '*.service' -o -name 'fly-help' -o -name 'fly-start' \) \
	-exec sed -i 's/\r$//' {} +

bash "$root/scripts/stage-armbian-overlay.sh"
cp -a "$root/FLYBIAN_VERSION" "$root/armbian/userpatches/overlay/FLYBIAN_VERSION"
test -f "$root/armbian/userpatches/overlay/first-boot/fly-start.txt"
test -f "$root/armbian/userpatches/overlay/tools/fly-help"
test -f "$root/armbian/userpatches/overlay/tools/fly-start"

# Truncate master log so a new run is obvious
: >"$build/compile-all.log"
: >"$build/compile-all.nohup.out"

nohup bash "$root/scripts/build-all-named-images.sh" \
	>"$build/compile-all.nohup.out" 2>&1 &
echo "started PID=$! ver=$(tr -d '[:space:]' <"$root/FLYBIAN_VERSION")"
sleep 3
tail -n 25 "$build/compile-all.log" || true
pgrep -af 'build-all-named|run-armbian-compile|compile.sh' || true
