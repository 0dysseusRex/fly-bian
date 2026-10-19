#!/usr/bin/env bash
# Parser check for the Lite apt wrapper. Does not call real apt.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
wrap=$root/armbian/userpatches/overlay/tools/fly-apt-lowmem
log=$(mktemp)
fake=$(mktemp)
trap 'rm -f "$log" "$fake"' EXIT
cat >"$fake" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FLY_APT_LOG"
exit 0
EOF
chmod +x "$fake"

run() {
	: >"$log"
	FLY_APT_BATCH=0 FLY_APT_NO_SYNC=1 FLY_APT_LOG=$log FLY_APT_GET=$fake \
		bash "$wrap" "$@"
}

run -y install pkg-a pkg-b pkg-c
mapfile -t lines <"$log"
[[ ${#lines[@]} -eq 3 ]] || { printf 'expected 3 calls, got %s\n' "${lines[*]}" >&2; exit 1; }
[[ ${lines[0]} == "-y install pkg-a" ]]
[[ ${lines[1]} == "-y install pkg-b" ]]
[[ ${lines[2]} == "-y install pkg-c" ]]

run install --no-install-recommends -o Dpkg::Options::=--force-confdef foo bar
mapfile -t lines <"$log"
[[ ${#lines[@]} -eq 2 ]]
[[ ${lines[0]} == "install --no-install-recommends -o Dpkg::Options::=--force-confdef foo" ]]
[[ ${lines[1]} == "install --no-install-recommends -o Dpkg::Options::=--force-confdef bar" ]]

run update
mapfile -t lines <"$log"
[[ ${#lines[@]} -eq 1 && ${lines[0]} == update ]]

run -f install foo bar
mapfile -t lines <"$log"
[[ ${#lines[@]} -eq 1 && ${lines[0]} == "-f install foo bar" ]]

run install -f foo bar
mapfile -t lines <"$log"
[[ ${#lines[@]} -eq 1 && ${lines[0]} == "install -f foo bar" ]]

run install 'pkg*'
mapfile -t lines <"$log"
[[ ${#lines[@]} -eq 1 ]]

: >"$log"
FLY_APT_BATCH=1 FLY_APT_NO_SYNC=1 FLY_APT_LOG=$log FLY_APT_GET=$fake \
	bash "$wrap" install a b
mapfile -t lines <"$log"
[[ ${#lines[@]} -eq 1 && ${lines[0]} == "install a b" ]]

base=$root/first-boot/fly-start.txt
simple=$root/armbian/userpatches/overlay/simpleaf/fly-start.txt
kiauh=$root/armbian/userpatches/overlay/kiauh/fly-start.txt
grep -q '^SERIAL_CONSOLE=Yes$' "$base" "$simple" "$kiauh"
grep -q '^INSTALL_CMD=' "$simple"
if grep -q '^INSTALL_CMD=' "$base" || grep -q '^INSTALL_CMD=' "$kiauh"; then
	echo "INSTALL_CMD leaked onto base or KIAUH fly-start" >&2
	exit 1
fi
if grep -q '^ENABLE_GRUMPYSCREEN=' "$base" || grep -q '^AUTO_CAMERAS=' "$kiauh"; then
	echo "Simple-AF keys leaked" >&2
	exit 1
fi

echo "fly-apt-lowmem tests passed"
