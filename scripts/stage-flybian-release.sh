#!/usr/bin/env bash
# Stage Armbian build outputs under the Fly-bian product name.
# Finds the newest matching Armbian-unofficial *.img.xz and copies it as:
#   Fly-bian-<ver>_<Device>_<Flavor>.img.xz
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
src=${FLY_ARMBIAN_IMAGES:-/home/rex/fly-build/armbian-build/output/images}
releases=${FLY_RELEASES:-/mnt/c/Users/udrdr/fly-lite-armbian-image/Releases}
device=${FLY_DEVICE:-Fly-Lite-2.1}
ver=$(tr -d '[:space:]' <"$root/FLYBIAN_VERSION")

flavor=${1:-}
if [[ -z $flavor ]]; then
	echo "usage: $0 base|simpleaf|kiauh|all" >&2
	exit 1
fi

# Every new publish must bump FLYBIAN_VERSION (docs/image-naming.md).
# Per-flavor: allow Base+Simple-AF+KIAUH under the same new version.
if [[ $flavor == all ]]; then
	bash "$root/scripts/flybian-require-new-version.sh"
else
	bash "$root/scripts/flybian-require-new-version.sh" "$flavor"
fi

armbian_glob_for() {
	case "$1" in
		base) printf '%s\n' 'Armbian-unofficial_*_Fly-lite-21_trixie_*_minimal.img.xz' ;;
		simpleaf) printf '%s\n' 'Armbian-unofficial_*_Fly-lite-21-simpleaf_trixie_*_minimal.img.xz' ;;
		kiauh) printf '%s\n' 'Armbian-unofficial_*_Fly-lite-21-kiauh_trixie_*_minimal.img.xz' ;;
		*) return 1 ;;
	esac
}

stage_flavor() {
	local fl=$1
	local glob xz base stem dest_rel dest
	glob=$(armbian_glob_for "$fl")
	# Newest match (by mtime)
	xz=$(ls -1t "$src"/$glob 2>/dev/null | head -n 1 || true)
	if [[ -z ${xz:-} || ! -f $xz ]]; then
		echo "ERROR: no Armbian image matching $glob in $src" >&2
		return 1
	fi
	base=$(basename "$xz" .img.xz)
	stem=$("$root/scripts/flybian-release-name.sh" stem "$fl" "$device")
	dest_rel=$("$root/scripts/flybian-release-name.sh" dir "$fl" "$device")
	dest="$releases/$dest_rel"
	mkdir -p "$dest"

	echo "=== Fly-bian $ver / $fl ==="
	echo "source: $xz"
	echo "dest:   $dest/${stem}.img.xz"

	cp -av "$src/${base}.img.xz" "$dest/${stem}.img.xz"
	if [[ -f $src/${base}.img.xz.sha ]]; then
		# Rewrite checksum file to the product filename
		sum=$(awk '{print $1}' "$src/${base}.img.xz.sha")
		printf '%s  %s\n' "$sum" "${stem}.img.xz" >"$dest/${stem}.img.xz.sha"
	else
		(cd "$dest" && sha256sum "${stem}.img.xz" >"${stem}.img.xz.sha")
	fi
	if [[ -f $src/${base}.img.txt ]]; then
		{
			echo "Fly-bian product: ${stem}"
			echo "Fly-bian version: ${ver}"
			echo "Device: ${device}"
			echo "Flavor: ${fl}"
			echo "Armbian artifact: ${base}"
			echo "----"
			cat "$src/${base}.img.txt"
		} >"$dest/${stem}.img.txt"
	fi
	(cd "$dest" && sha256sum -c "${stem}.img.xz.sha")
	cat "$dest/${stem}.img.xz.sha"
}

case "$flavor" in
	all)
		stage_flavor base
		stage_flavor simpleaf
		stage_flavor kiauh
		;;
	base|simpleaf|kiauh)
		stage_flavor "$flavor"
		;;
	*)
		echo "usage: $0 base|simpleaf|kiauh|all" >&2
		exit 1
		;;
esac

echo "staged under $releases/Fly-bian-${ver}/"
