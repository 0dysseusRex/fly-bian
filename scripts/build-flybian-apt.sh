#!/usr/bin/env bash
# Build Fly-bian helper .debs (Architecture: all) and a local apt repo tree.
# Source files stay in armbian/userpatches/overlay. See docs/apt-repo.md.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
overlay=$root/armbian/userpatches/overlay
ver=$(tr -d '[:space:]' <"$root/FLYBIAN_VERSION")
[[ -n $ver ]] || { echo "empty FLYBIAN_VERSION" >&2; exit 1; }

# dpkg-deb refuses DEBIAN/ on 0777 (WSL /mnt/c). Stage on a Linux fs.
if [[ -z ${FLY_APT_OUT:-} ]]; then
	if [[ $root == /mnt/* ]]; then
		out=$HOME/fly-build/flybian-apt
	else
		out=$root/apt/out
	fi
else
	out=$FLY_APT_OUT
fi
stage=$out/stage
pool=$out/repo/pool/main/f
dists=$out/repo/dists/trixie/main/binary-all
rm -rf "$out"
mkdir -p "$stage" "$pool" "$dists"

export DEBIAN_FRONTEND=noninteractive

inst() {
	local mode=$1 src=$2 dest=$3
	[[ -f $src ]] || return 0
	install -d "$(dirname "$dest")"
	install -m "$mode" "$src" "$dest"
}

write_preinst_min() {
	local dest=$1
	cat >"$dest" <<'EOF'
#!/bin/bash
set -euo pipefail
if [[ -x /usr/lib/fly-debian/check-min-image ]]; then
	/usr/lib/fly-debian/check-min-image
fi
exit 0
EOF
	chmod 0755 "$dest"
}

write_preinst_device() {
	local dest=$1 want=$2
	{
		cat <<'EOF'
#!/bin/bash
set -euo pipefail
EOF
		cat "$overlay/apt/infer-identity"
		cat <<EOF
if [[ -x /usr/lib/fly-debian/check-min-image ]]; then
	/usr/lib/fly-debian/check-min-image
fi
want='$want'
if ! flybian_infer_device; then
	flybian_missing_device_msg
	exit 1
fi
if [[ \$flybian_device != "\$want" ]]; then
	echo "This package is for \$want (this card is '\$flybian_device')." >&2
	exit 1
fi
exit 0
EOF
	} >"$dest"
	chmod 0755 "$dest"
}

control() {
	local dir=$1 name=$2 desc=$3 depends=$4
	cat >"$dir/DEBIAN/control" <<EOF
Package: $name
Version: $ver
Section: misc
Priority: optional
Architecture: all
Maintainer: Fly-bian Project <https://github.com/0dysseusRex/fly-bian>
Homepage: https://github.com/0dysseusRex/fly-bian
Depends: $depends
Description: $desc
 Unofficial Armbian/Debian helpers for Mellow Fly SBCs. Not FlyOS.
EOF
}

build_deb() {
	local name=$1
	local pkg=$stage/$name
	chmod 0755 "$pkg/DEBIAN"
	find "$pkg/DEBIAN" -type f -exec chmod 0644 {} +
	chmod 0755 "$pkg/DEBIAN"/preinst "$pkg/DEBIAN"/postinst "$pkg/DEBIAN"/prerm \
		"$pkg/DEBIAN"/postrm 2>/dev/null || true
	dpkg-deb --root-owner-group --build "$pkg" "$pool/${name}_${ver}_all.deb"
}

# --- flybian-release ---
rel=$stage/flybian-release
install -d "$rel/DEBIAN" \
	"$rel/usr/lib/fly-debian" \
	"$rel/usr/share/fly-debian" \
	"$rel/usr/sbin" \
	"$rel/etc/apt/sources.list.d" \
	"$rel/etc/fly-debian"
inst 0755 "$overlay/apt/check-min-image" "$rel/usr/lib/fly-debian/check-min-image"
inst 0644 "$overlay/apt/infer-identity" "$rel/usr/lib/fly-debian/infer-identity"
inst 0755 "$overlay/apt/flybian-update" "$rel/usr/sbin/flybian-update"
inst 0644 "$overlay/apt/min-image" "$rel/usr/share/fly-debian/min-image"
inst 0644 "$overlay/apt/flybian.sources" "$rel/etc/apt/sources.list.d/flybian.sources"
# Release preinst inlines identity + min-image (preinst runs before unpack).
{
	cat <<'EOF'
#!/bin/bash
set -euo pipefail
EOF
	cat "$overlay/apt/infer-identity"
	cat <<'EOF'
rank() {
	local v maj min
	v=$(printf '%s' "$1" | tr -d '[:space:]')
	maj=${v%%.*}
	if [[ $v == *.* ]]; then
		min=${v#*.}
		min=${min%%.*}
	else
		min=0
	fi
	maj=$((10#$maj))
	min=$((10#$min))
	printf '%s\n' $((maj * 100 + min))
}
if ! flybian_infer_device; then
	if [[ -r /etc/fly-debian/flybian-version ]]; then
		echo "flybian-release: Fly-bian card, but board id is missing." >&2
	else
		echo "flybian-release: not a Fly-bian card (no flybian-version)." >&2
	fi
	flybian_missing_device_msg
	exit 1
fi
device=$flybian_device
if ! flybian_infer_baked; then
	echo "flybian-release: no baked version." >&2
	exit 1
fi
baked=$flybian_baked
min=""
case "$device" in
EOF
	awk '!/^#/ && NF>=2 { printf "\t%s) min=%s ;;\n", $1, $2 }' "$overlay/apt/min-image"
	cat <<'EOF'
esac
if [[ -z $min ]]; then
	echo "flybian-release: no min-image for $device — reflash a current image." >&2
	exit 1
fi
if (($(rank "$baked") < $(rank "$min"))); then
	cat >&2 <<EOM
flybian: baked image $baked is older than the required $min for $device.
This update cannot be applied over SSH. Copy ~/printer_data, flash a new
Fly-bian image, then copy it back. See docs/howto-update.md
EOM
	exit 1
fi
exit 0
EOF
} >"$rel/DEBIAN/preinst"
chmod 0755 "$rel/DEBIAN/preinst"
cat >"$rel/DEBIAN/postinst" <<EOF
#!/bin/bash
set -euo pipefail
if [[ -f /usr/lib/fly-debian/infer-identity ]]; then
	# shellcheck disable=SC1091
	. /usr/lib/fly-debian/infer-identity
	flybian_persist_identity
fi
install -d /etc/fly-debian
printf '%s\\n' '$ver' >/etc/fly-debian/flybian-apt-version
if [[ -r /etc/fly-debian/flybian-version ]] && [[ ! -e /etc/fly-debian/flybian-image-baked ]]; then
	cp -a /etc/fly-debian/flybian-version /etc/fly-debian/flybian-image-baked
fi
printf '%s\\n' '$ver' >/etc/fly-debian/flybian-version
exit 0
EOF
chmod 0755 "$rel/DEBIAN/postinst"
control "$rel" flybian-release \
	"Fly-bian release metadata and apt source" \
	"bash"
build_deb flybian-release

# --- flybian-common ---
com=$stage/flybian-common
install -d "$com/DEBIAN"
inst 0755 "$overlay/tools/fly-help" "$com/usr/local/bin/fly-help"
inst 0755 "$overlay/tools/fly-moonraker-polkit" "$com/usr/local/bin/fly-moonraker-polkit"
inst 0755 "$overlay/tools/fly-tft-check" "$com/usr/local/bin/fly-tft-check"
inst 0755 "$overlay/crowsnest/fly-crowsnest-add-cams" "$com/usr/local/bin/fly-crowsnest-add-cams"
inst 0755 "$overlay/crowsnest/fly-crowsnest-strip-placeholders" \
	"$com/usr/local/bin/fly-crowsnest-strip-placeholders"
inst 0755 "$overlay/fly-apply-fly-net.sh" "$com/usr/local/sbin/fly-apply-fly-net.sh"
inst 0644 "$overlay/fly-apply-fly-net.service" "$com/etc/systemd/system/fly-apply-fly-net.service"
inst 0755 "$overlay/swapfile/fly-swapfile.sh" "$com/usr/local/sbin/fly-swapfile.sh"
inst 0644 "$overlay/swapfile/fly-swapfile.service" "$com/etc/systemd/system/fly-swapfile.service"
inst 0755 "$overlay/network/fly-ip-announce.sh" "$com/usr/local/sbin/fly-ip-announce.sh"
inst 0644 "$overlay/network/fly-ip-announce.service" "$com/etc/systemd/system/fly-ip-announce.service"
inst 0755 "$overlay/boot/fly-boot-complete.sh" "$com/usr/local/sbin/fly-boot-complete.sh"
inst 0644 "$overlay/boot/fly-boot-complete.service" "$com/etc/systemd/system/fly-boot-complete.service"
inst 0755 "$overlay/motd/print-flybian.sh" "$com/usr/share/fly-debian/motd/print-flybian.sh"
inst 0644 "$overlay/motd/flybian.txt" "$com/usr/share/fly-debian/motd/flybian.txt"
inst 0644 "$overlay/motd/flybian.ansi" "$com/usr/share/fly-debian/motd/flybian.ansi"
inst 0755 "$overlay/motd/patch-armbian-header.py" \
	"$com/usr/share/fly-debian/motd/patch-armbian-header.py"
inst 0755 "$overlay/motd/patch-armbian-commands.py" \
	"$com/usr/share/fly-debian/motd/patch-armbian-commands.py"
write_preinst_min "$com/DEBIAN/preinst"
cat >"$com/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -euo pipefail
if command -v systemctl >/dev/null; then
	systemctl daemon-reload || true
	systemctl enable fly-apply-fly-net.service >/dev/null 2>&1 || true
fi
if command -v apt-mark >/dev/null; then
	apt-mark hold linux-image-legacy-sunxi64 linux-dtb-legacy-sunxi64 \
		linux-image-current-sunxi linux-dtb-current-sunxi \
		linux-u-boot-fly-lite-21-current \
		linux-u-boot-fly-lite-21-simpleaf-current \
		linux-u-boot-fly-lite-21-kiauh-current \
		linux-u-boot-fly-pi-v3-legacy \
		linux-u-boot-fly-pi-v3-simpleaf-legacy \
		linux-u-boot-fly-pi-v3-kiauh-legacy >/dev/null 2>&1 || true
fi
exit 0
EOF
chmod 0755 "$com/DEBIAN/postinst"
control "$com" flybian-common \
	"Fly-bian shared helpers (fly-help, fly-apply, cameras, MOTD)" \
	"flybian-release"
build_deb flybian-common

# --- board: Lite ---
lite=$stage/flybian-board-fly-lite-21
install -d "$lite/DEBIAN" "$lite/usr/share/fly-debian/overlays"
inst 0644 "$overlay/hdmi/fly-lite-hdmi.dts" "$lite/usr/share/fly-debian/overlays/fly-lite-hdmi.dts"
inst 0644 "$overlay/tft/fly-lite-tft.dts" "$lite/usr/share/fly-debian/overlays/fly-lite-tft.dts"
inst 0644 "$overlay/tft/fly-lite-tft-c.dts" "$lite/usr/share/fly-debian/overlays/fly-lite-tft-c.dts"
inst 0644 "$overlay/board/fly-lite-board.dts" "$lite/usr/share/fly-debian/overlays/fly-lite-board.dts"
inst 0755 "$overlay/from-golden/sbin/fly-online-isolated-cpus.sh" \
	"$lite/usr/local/sbin/fly-online-isolated-cpus.sh"
inst 0644 "$overlay/from-golden/systemd/fly-online-isolated-cpus.service" \
	"$lite/etc/systemd/system/fly-online-isolated-cpus.service"
write_preinst_device "$lite/DEBIAN/preinst" "Fly-Lite-2.1"
cat >"$lite/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -euo pipefail
if [[ ! -f /etc/default/fly-swapfile ]]; then
	printf 'FLY_SWAP_MIB=2048\n' >/etc/default/fly-swapfile
fi
if command -v systemctl >/dev/null; then
	systemctl daemon-reload || true
	systemctl enable fly-online-isolated-cpus.service >/dev/null 2>&1 || true
fi
exit 0
EOF
chmod 0755 "$lite/DEBIAN/postinst"
control "$lite" flybian-board-fly-lite-21 \
	"Fly-bian board helpers for Fly Lite 2.1" \
	"flybian-common"
echo "Conflicts: flybian-board-fly-pi-v3" >>"$lite/DEBIAN/control"
build_deb flybian-board-fly-lite-21

# --- board: Pi V3 ---
v3=$stage/flybian-board-fly-pi-v3
install -d "$v3/DEBIAN" "$v3/usr/share/fly-debian/overlays" \
	"$v3/usr/share/fly-debian/first-boot"
for dts in \
	"$overlay/io/fly-pi-v3-uart1.dts" \
	"$overlay/io/fly-pi-v3-rs232.dts" \
	"$overlay/io/fly-pi-v3-adxl.dts" \
	"$overlay/io/fly-pi-v3-sd.dts" \
	"$overlay/usb/fly-pi-v3-usb1.dts" \
	"$overlay/tft/fly-pi-v3-tft.dts" \
	"$overlay/tft/fly-pi-v3-tft-c.dts" \
	"$overlay/hdmi/fly-pi-v3-hdmi.dts"
do
	inst 0644 "$dts" "$v3/usr/share/fly-debian/overlays/$(basename "$dts")"
done
inst 0755 "$overlay/tools/fly-media-sd" "$v3/usr/local/bin/fly-media-sd"
inst 0644 "$overlay/pi-v3/fly-start.txt" \
	"$v3/usr/share/fly-debian/first-boot/fly-start-pi-v3-base.txt"
inst 0644 "$overlay/pi-v3/fly-start-simpleaf.txt" \
	"$v3/usr/share/fly-debian/first-boot/fly-start-pi-v3-simpleaf.txt"
inst 0644 "$overlay/pi-v3/fly-start-kiauh.txt" \
	"$v3/usr/share/fly-debian/first-boot/fly-start-pi-v3-kiauh.txt"
write_preinst_device "$v3/DEBIAN/preinst" "Fly-Pi-V3"
cat >"$v3/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -euo pipefail
if [[ ! -f /etc/default/fly-swapfile ]]; then
	printf 'FLY_SWAP_MIB=512\n' >/etc/default/fly-swapfile
fi
boot=/boot/overlay-user
if [[ -d /usr/share/fly-debian/overlays ]] && command -v dtc >/dev/null; then
	if [[ ! -d $boot ]]; then
		mountpoint -q /boot 2>/dev/null || mount /boot 2>/dev/null || true
	fi
	if [[ -d $boot ]]; then
		for dts in /usr/share/fly-debian/overlays/fly-pi-v3-*.dts; do
			[[ -f $dts ]] || continue
			base=$(basename "$dts" .dts)
			dtc -@ -I dts -O dtb -o "$boot/${base}.dtbo" "$dts" 2>/dev/null || true
		done
	fi
fi
if command -v systemctl >/dev/null; then
	systemctl daemon-reload || true
fi
exit 0
EOF
chmod 0755 "$v3/DEBIAN/postinst"
control "$v3" flybian-board-fly-pi-v3 \
	"Fly-bian board helpers for Fly Pi V3" \
	"flybian-common"
echo "Conflicts: flybian-board-fly-lite-21" >>"$v3/DEBIAN/control"
build_deb flybian-board-fly-pi-v3

# --- KIAUH installer helpers (not the Klipper stack) ---
kia=$stage/flybian-kiauh-installer
install -d "$kia/DEBIAN"
inst 0755 "$overlay/tools/fly-kiauh" "$kia/usr/local/bin/fly-kiauh"
inst 0755 "$overlay/kiauh/fly-bind-kiauh-installer.sh" \
	"$kia/usr/local/sbin/fly-bind-kiauh-installer"
inst 0644 "$overlay/kiauh/fly-bind-kiauh-installer.service" \
	"$kia/etc/systemd/system/fly-bind-kiauh-installer.service"
inst 0755 "$overlay/tools/fly-klipperscreen-prep" \
	"$kia/usr/local/bin/fly-klipperscreen-prep"
write_preinst_min "$kia/DEBIAN/preinst"
cat >"$kia/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -euo pipefail
if command -v systemctl >/dev/null; then
	systemctl daemon-reload || true
	systemctl enable fly-bind-kiauh-installer.service >/dev/null 2>&1 || true
	if [[ ! -f /var/lib/fly-kiauh-bound ]] && [[ -x /usr/local/sbin/fly-bind-kiauh-installer ]]; then
		/usr/local/sbin/fly-bind-kiauh-installer || true
	fi
fi
exit 0
EOF
chmod 0755 "$kia/DEBIAN/postinst"
control "$kia" flybian-kiauh-installer \
	"Fly-bian KIAUH launcher (no Klipper stack)" \
	"flybian-common"
echo "Conflicts: flybian-simpleaf-helpers" >>"$kia/DEBIAN/control"
build_deb flybian-kiauh-installer

# --- Simple-AF helpers (not pellcorp trees) ---
saf=$stage/flybian-simpleaf-helpers
install -d "$saf/DEBIAN"
inst 0755 "$overlay/tools/fly-start" "$saf/usr/local/bin/fly-start"
inst 0755 "$overlay/tools/fly-boot-display" "$saf/usr/local/bin/fly-boot-display"
inst 0755 "$overlay/tools/fly-grumpy-rotate" "$saf/usr/local/bin/fly-grumpy-rotate"
inst 0755 "$overlay/tools/fly-ensure-shaketune" "$saf/usr/local/bin/fly-ensure-shaketune"
inst 0755 "$overlay/simpleaf/fly-grumpy-evdev.sh" "$saf/usr/local/sbin/fly-grumpy-evdev.sh"
write_preinst_min "$saf/DEBIAN/preinst"
cat >"$saf/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -euo pipefail
if command -v systemctl >/dev/null; then
	systemctl daemon-reload || true
fi
exit 0
EOF
chmod 0755 "$saf/DEBIAN/postinst"
control "$saf" flybian-simpleaf-helpers \
	"Fly-bian Simple-AF launcher helpers (not the pellcorp stack)" \
	"flybian-common"
echo "Conflicts: flybian-kiauh-installer" >>"$saf/DEBIAN/control"
build_deb flybian-simpleaf-helpers

# --- Packages index (arch all) ---
if command -v dpkg-scanpackages >/dev/null; then
	(cd "$out/repo" && dpkg-scanpackages -m pool /dev/null >"$dists/Packages")
else
	python3 - "$pool" "$dists/Packages" <<'PY'
import hashlib, os, sys
from pathlib import Path
pool, dest = Path(sys.argv[1]), Path(sys.argv[2])
blocks = []
for deb in sorted(pool.glob("*.deb")):
    raw = deb.read_bytes()
    sha = hashlib.sha256(raw).hexdigest()
    # Parse the embedded control via dpkg-deb if present
    import subprocess
    ctrl = subprocess.check_output(["dpkg-deb", "-I", str(deb), "control"], text=True)
    rel = f"pool/main/f/{deb.name}"
    extra = f"Filename: {rel}\nSize: {len(raw)}\nSHA256: {sha}\n"
    blocks.append(ctrl.rstrip() + "\n" + extra)
dest.write_text("\n".join(blocks) + ("\n" if blocks else ""))
PY
fi
gzip -9c "$dists/Packages" >"$dists/Packages.gz"
cat >"$out/repo/dists/trixie/Release" <<EOF
Origin: Fly-bian
Label: Fly-bian
Suite: trixie
Codename: trixie
Architectures: all
Components: main
Description: Fly-bian helper packages
EOF

tarball=$out/flybian-debs-${ver}.tar.gz
tar -C "$pool" -czf "$tarball" .
echo "built Fly-bian apt $ver"
echo "  debs: $pool"
echo "  repo: $out/repo"
echo "  tarball: $tarball"
ls -l "$pool"
