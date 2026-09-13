#!/usr/bin/env bash
set -euo pipefail
out=/home/rex/fly-build/armbian-build/output/images
rel='/mnt/c/Users/udrdr/fly-lite-armbian-image/Releases/26.11.0-trunk_trixie_6.18.51/Fly Lite 2.1'

echo '=== build output ==='
ls -lh "$out"/*.xz
echo
cat "$out"/*.sha 2>/dev/null || true

echo
echo '=== Releases tree ==='
if [[ ! -d $rel ]]; then
	echo "MISSING: $rel"
	ls -la /mnt/c/Users/udrdr/fly-lite-armbian-image/Releases/ || true
	exit 0
fi
for d in base simpleaf kiauh; do
	echo
	echo "== $d =="
	ls -lh "$rel/$d" || true
	echo 'SHA:'
	cat "$rel/$d"/*.sha 2>/dev/null || echo '(none)'
done

echo
echo '=== simpleaf staged? ==='
old=$(awk '{print $1}' "$rel/simpleaf"/*.sha)
new=$(awk '{print $1}' "$out"/*simpleaf*.img.xz.sha)
echo "Releases: $old"
echo "output:   $new"
if [[ $old == "$new" ]]; then echo MATCH; else echo NOT_STAGED; fi

echo
echo '=== agreety / build OK lines ==='
grep -aE 'agreety|greetd greeter|OK flavor|Done building image' \
	/home/rex/fly-build/compile-simpleaf.log \
	| sed 's/\x1b\[[0-9;]*m//g' | tail -n 40
