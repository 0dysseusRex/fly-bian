#!/bin/bash
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build/armbian-build
log=/home/rex/fly-build/compile.log

sed -i 's/\r$//' "$root/scripts/run-armbian-compile.sh" || true

echo "=== reset qemu-user-static ==="
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

echo "=== disable bare-arch binfmt handlers ==="
docker run --rm --privileged --pid=host alpine:3.20 sh -c '
  for name in arm aarch64 mips64 mips64le ppc64le riscv64; do
    f=/proc/sys/fs/binfmt_misc/$name
    if [ -e "$f" ]; then echo -1 > "$f" && echo disabled $name; fi
  done
  ls /proc/sys/fs/binfmt_misc
'

echo "=== qemu-arm handler ==="
cat /proc/sys/fs/binfmt_misc/qemu-arm 2>/dev/null || echo missing

: > "$log"
nohup bash "$root/scripts/run-armbian-compile.sh" > "$log" 2>&1 &
echo STARTED_PID=$!
