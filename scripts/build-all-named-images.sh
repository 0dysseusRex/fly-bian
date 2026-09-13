#!/bin/bash
# Sequential named-image builds: base, simpleaf, kiauh.
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build/armbian-build
master_log=/home/rex/fly-build/compile-all.log

sed -i 's/\r$//' "$root/scripts/run-armbian-compile.sh" \
	"$root/scripts/stage-armbian-overlay.sh" || true

{
	echo "=== $(date -Is) stage overlay ==="
	bash "$root/scripts/stage-armbian-overlay.sh"

	echo "=== $(date -Is) reset qemu-user-static / binfmt ==="
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker run --rm --privileged --pid=host alpine:3.20 sh -c '
	  for name in arm aarch64 mips64 mips64le ppc64le riscv64; do
	    f=/proc/sys/fs/binfmt_misc/$name
	    if [ -e "$f" ]; then echo -1 > "$f" && echo disabled $name; fi
	  done
	'
	cat /proc/sys/fs/binfmt_misc/qemu-arm 2>/dev/null | head -n 5 || echo 'qemu-arm missing'

	for flavor in base simpleaf kiauh; do
		echo "=== $(date -Is) START flavor=$flavor ==="
		# run-armbian-compile.sh exec's compile.sh; call via bash so we continue the loop
		if bash "$root/scripts/run-armbian-compile.sh" "$flavor"; then
			echo "=== $(date -Is) OK flavor=$flavor ==="
		else
			rc=$?
			echo "=== $(date -Is) FAIL flavor=$flavor rc=$rc ==="
			exit "$rc"
		fi
	done

	echo "=== $(date -Is) ALL DONE ==="
	ls -lh "$build/output/images/"*.xz 2>/dev/null | tail -n 20
} >"$master_log" 2>&1
