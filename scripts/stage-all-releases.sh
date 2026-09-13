#!/usr/bin/env bash
set -euo pipefail
src=/home/rex/fly-build/armbian-build/output/images
rel='/mnt/c/Users/udrdr/fly-lite-armbian-image/Releases/26.11.0-trunk_trixie_6.18.51/Fly Lite 2.1'

stage_one() {
	local dest=$1
	local xz=$2
	local base
	base=$(basename "$xz" .img.xz)
	mkdir -p "$dest"
	echo "=== staging $(basename "$xz") -> $dest ==="
	cp -av "$src/${base}.img.xz" "$src/${base}.img.xz.sha" "$src/${base}.img.txt" "$dest/"
	(cd "$dest" && sha256sum -c "${base}.img.xz.sha")
	cat "$dest/${base}.img.xz.sha"
}

stage_one "$rel/base" \
	"$src/Armbian-unofficial_26.11.0-trunk_Fly-lite-21_trixie_current_6.18.51_minimal.img.xz"
stage_one "$rel/simpleaf" \
	"$src/Armbian-unofficial_26.11.0-trunk_Fly-lite-21-simpleaf_trixie_current_6.18.51_minimal.img.xz"
stage_one "$rel/kiauh" \
	"$src/Armbian-unofficial_26.11.0-trunk_Fly-lite-21-kiauh_trixie_current_6.18.51_minimal.img.xz"
