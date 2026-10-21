#!/usr/bin/env bash
# Fly Pi V3 1.0: Base, then Simple-AF, then KIAUH. Stage locally, then GitHub.
# Does not change the Lite product version (repo FLYBIAN_VERSION).
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build
log=$build/compile-pi-v3-10.log
export PATH="/mnt/wsl/docker-desktop/cli-tools/usr/bin:/usr/bin:${PATH:-/usr/bin}"
hash -r || true
export FLY_DEVICE=Fly-Pi-V3
export PESTER_TERMINAL=no
export WT_SESSION="${WT_SESSION:-fly-bian-build}"

repo_ver_file=$root/FLYBIAN_VERSION
saved_repo=$(tr -d '[:space:]' <"$repo_ver_file")
restore_version() {
	printf '%s\n' "$saved_repo" >"$repo_ver_file"
}
trap restore_version EXIT
printf '1.0\n' >"$repo_ver_file"

if [[ -d $build/armbian-build/.tmp ]]; then
	docker run --rm --privileged -v "$build/armbian-build/.tmp:/t" alpine:3.20 \
		sh -c 'for d in /t/*; do mount | awk -v p="$d" "\$3 ~ p {print \$3}" | sort -r | while read m; do umount -l \"$m\"; done; done; rm -rf /t/*' \
		|| true
fi

{
	echo "=== $(date -Is) START Pi V3 1.0 set (repo was $saved_repo) ==="
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || true
	for pair in "pi-v3 base" "pi-v3-simpleaf simpleaf" "pi-v3-kiauh kiauh"; do
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
	echo "=== $(date -Is) DONE Pi V3 1.0 staged locally ==="
} >>"$log" 2>&1
