#!/usr/bin/env bash
# Fly Pi V3 1.05 Simple-AF then KIAUH. Base already staged locally.
# Does not change the Lite product version (repo FLYBIAN_VERSION).
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build
log=$build/compile-pi-v3-105.log
export PATH="/mnt/wsl/docker-desktop/cli-tools/usr/bin:/usr/bin:${PATH:-/usr/bin}"
hash -r || true
export FLY_DEVICE=Fly-Pi-V3
export PESTER_TERMINAL=no
export WT_SESSION="${WT_SESSION:-fly-bian-build}"

ver=$(tr -d '[:space:]' <"$root/FLY_PI_V3_VERSION")
[[ $ver == 1.05 ]] || {
	echo "FLY_PI_V3_VERSION is $ver (want 1.05)" >&2
	exit 1
}

if [[ -d $build/armbian-build/.tmp ]]; then
	docker run --rm --privileged -v "$build/armbian-build/.tmp:/t" alpine:3.20 \
		sh -c 'for d in /t/*; do mount | awk -v p="$d" "\$3 ~ p {print \$3}" | sort -r | while read m; do umount -l \"$m\"; done; done; rm -rf /t/*' \
		|| true
fi

{
	echo "=== $(date -Is) START Pi V3 1.05 Simple-AF + KIAUH (Lite repo ver stays $(tr -d '[:space:]' <"$root/FLYBIAN_VERSION")) ==="
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || true
	for pair in "pi-v3-simpleaf simpleaf" "pi-v3-kiauh kiauh"; do
		set -- $pair
		comp=$1
		stage_fl=$2
		echo "=== $(date -Is) COMPILE $comp ==="
		# Only leftover Pi V3 compile containers — do not docker-rm unrelated builds.
		docker ps --format '{{.ID}} {{.Names}} {{.Command}}' | \
			awk 'BEGIN{IGNORECASE=1} /fly-pi-v3|BOARD=fly-pi-v3/ {print $1}' | \
			xargs -r docker rm -f || true
		if ! bash "$root/scripts/run-armbian-compile.sh" "$comp"; then
			echo "=== $(date -Is) FAIL $comp ==="
			exit 1
		fi
		echo "=== $(date -Is) STAGE $stage_fl ==="
		FLY_DEVICE=Fly-Pi-V3 bash "$root/scripts/stage-flybian-release.sh" "$stage_fl"
	done
	echo "=== $(date -Is) DONE Pi V3 1.05 Simple-AF + KIAUH staged locally ==="
} >>"$log" 2>&1
