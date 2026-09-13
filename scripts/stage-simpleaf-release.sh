#!/usr/bin/env bash
set -euo pipefail
src=/home/rex/fly-build/armbian-build/output/images
dst='/mnt/c/Users/udrdr/fly-lite-armbian-image/Releases/26.11.0-trunk_trixie_6.18.51/Fly Lite 2.1/simpleaf'
base=Armbian-unofficial_26.11.0-trunk_Fly-lite-21-simpleaf_trixie_current_6.18.51_minimal

echo "Copying to $dst"
cp -av "$src/${base}.img.xz" "$src/${base}.img.xz.sha" "$src/${base}.img.txt" "$dst/"
echo 'Verify SHA:'
(cd "$dst" && sha256sum -c "${base}.img.xz.sha")
ls -lh "$dst"
cat "$dst/${base}.img.xz.sha"
