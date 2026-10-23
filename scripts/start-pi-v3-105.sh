#!/bin/bash
# Start the Pi V3 1.05 Simple-AF + KIAUH bake in tmux. Base already staged.
set -eu
export PATH="/mnt/wsl/docker-desktop/cli-tools/usr/bin:/usr/bin:${PATH:-/usr/bin}"
hash -r
root=/mnt/c/Users/udrdr/fly-debian
log=/home/rex/fly-build/compile-pi-v3-105.log

sed -i 's/\r$//' \
	"$root/scripts/flybian-product-version.sh" \
	"$root/scripts/launch-pi-v3-105.sh" \
	"$root/scripts/start-pi-v3-105.sh" \
	"$root/scripts/run-armbian-compile.sh" \
	"$root/scripts/flybian-require-new-version.sh" \
	"$root/scripts/stage-flybian-release.sh" \
	"$root/scripts/flybian-release-name.sh" \
	"$root/armbian/userpatches/overlay/tools/fly-media-sd"
chmod +x "$root/scripts/flybian-product-version.sh" "$root/scripts/launch-pi-v3-105.sh" \
	"$root/scripts/start-pi-v3-105.sh"

bash -n "$root/scripts/flybian-product-version.sh"
bash -n "$root/scripts/launch-pi-v3-105.sh"
bash -n "$root/armbian/userpatches/overlay/tools/fly-media-sd"

echo "FLY_PI_V3_VERSION=$(tr -d '[:space:]' <"$root/FLY_PI_V3_VERSION")"
echo "FLYBIAN_VERSION=$(tr -d '[:space:]' <"$root/FLYBIAN_VERSION")"
FLY_DEVICE=Fly-Pi-V3 bash "$root/scripts/flybian-product-version.sh"
FLY_DEVICE=Fly-Lite-2.1 bash "$root/scripts/flybian-product-version.sh"
FLY_DEVICE=Fly-Pi-V3 bash "$root/scripts/flybian-require-new-version.sh" simpleaf
FLY_DEVICE=Fly-Pi-V3 bash "$root/scripts/flybian-require-new-version.sh" kiauh

command -v docker
docker ps --format '{{.ID}} {{.Image}} {{.Names}}' || true
pgrep -af 'compile.sh build|run-armbian-compile|launch-pi-v3' || echo 'no compile procs'
tmux ls 2>/dev/null || echo 'no tmux sessions'

mkdir -p /home/rex/fly-build
: >"$log"
tmux kill-session -t flybuild-piv3-105 2>/dev/null || true
tmux new-session -d -s flybuild-piv3-105 "bash $root/scripts/launch-pi-v3-105.sh"
echo STARTED
tmux ls
sleep 8
tail -n 30 "$log" || true
