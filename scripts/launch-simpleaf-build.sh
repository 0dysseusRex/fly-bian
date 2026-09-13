#!/usr/bin/env bash
# One-shot launcher for a simpleaf rebuild (agreety absolute-path fix).
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
log=/home/rex/fly-build/compile-simpleaf.log

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

	echo "=== $(date -Is) START flavor=simpleaf ==="
	bash "$root/scripts/run-armbian-compile.sh" simpleaf
	echo "=== $(date -Is) OK flavor=simpleaf ==="
	ls -lh /home/rex/fly-build/armbian-build/output/images/*simpleaf*.xz \
		| tail -n 5
} >"$log" 2>&1
