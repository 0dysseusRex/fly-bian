#!/usr/bin/env bash
# Promote the just-built Fly-bian-0.1 staged images to Fly-bian-0.2 names.
set -euo pipefail
releases=/mnt/c/Users/udrdr/fly-lite-armbian-image/Releases
src=$releases/Fly-bian-0.1/Fly-Lite-2.1
dst=$releases/Fly-bian-0.2/Fly-Lite-2.1
device=Fly-Lite-2.1
oldver=0.1
newver=0.2

mkdir -p "$dst"
for flavor in Base Simple-AF KIAUH; do
	oldstem="Fly-bian-${oldver}_${device}_${flavor}"
	newstem="Fly-bian-${newver}_${device}_${flavor}"
	mkdir -p "$dst/$flavor"
	echo "=== $flavor ==="
	for ext in img.xz img.xz.sha img.txt; do
		old="$src/$flavor/${oldstem}.${ext}"
		new="$dst/$flavor/${newstem}.${ext}"
		[[ -f $old ]] || { echo "missing $old" >&2; exit 1; }
		cp -av "$old" "$new"
	done
	# Rewrite checksum filename line
	sum=$(awk '{print $1}' "$dst/$flavor/${newstem}.img.xz.sha")
	printf '%s  %s\n' "$sum" "${newstem}.img.xz" >"$dst/$flavor/${newstem}.img.xz.sha"
	# Prefix sidecar with product rename note
	{
		echo "Fly-bian product: ${newstem}"
		echo "Fly-bian version: ${newver} (release rename from bake-time ${oldver})"
		echo "Device: ${device}"
		echo "Flavor: ${flavor}"
		echo "----"
		# drop any prior Fly-bian product header lines from old txt
		awk '
			BEGIN{skip=0}
			/^Fly-bian product:/{skip=1; next}
			/^Fly-bian version:/{next}
			/^Device:/{next}
			/^Flavor:/{next}
			/^Armbian artifact:/{print; next}
			/^----$/{skip=0; next}
			skip==0{print}
		' "$src/$flavor/${oldstem}.img.txt"
	} >"$dst/$flavor/${newstem}.img.txt"
	(cd "$dst/$flavor" && sha256sum -c "${newstem}.img.xz.sha")
done

# Keep prior 6.18.50 under 0.2 as historical if present
if [[ -d $src/_prior-6.18.50 ]]; then
	mkdir -p "$dst/_prior-6.18.50"
	cp -a "$src/_prior-6.18.50/." "$dst/_prior-6.18.50/" || true
fi

echo "promoted to $dst"
ls -lh "$dst"/*/*.img.xz
