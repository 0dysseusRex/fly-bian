#!/usr/bin/env bash
# Fully detached Base + Simple-AF + KIAUH rebuild (survives SSH/WSL hangup).
# Stages each flavor into Releases/Fly-bian-<ver>/ after a successful compile.
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build
log=$build/compile-detached.log

# Docker Desktop WSL CLI (docker may not be on default PATH).
export PATH="/mnt/wsl/docker-desktop/cli-tools/usr/bin:/usr/bin:${PATH:-/usr/bin}"
hash -r

sed -i 's/\r$//' "$root/scripts/"*.sh \
	"$root/armbian/userpatches/overlay/simpleaf/"*.sh \
	"$root/armbian/userpatches/overlay/boot/"* \
	"$root/armbian/userpatches/overlay/motd/"* 2>/dev/null || true
bash "$root/scripts/stage-armbian-overlay.sh"
cp -a "$root/FLYBIAN_VERSION" "$root/armbian/userpatches/overlay/FLYBIAN_VERSION"
bash "$root/scripts/flybian-require-new-version.sh"

# Clean leftover tmp without sudo
docker ps -aq | xargs -r docker rm -f || true
if [[ -d $build/armbian-build/.tmp ]]; then
	docker run --rm --privileged -v "$build/armbian-build/.tmp:/t" alpine:3.20 \
		sh -c 'for d in /t/*; do mount | awk -v p="$d" "\$3 ~ p {print \$3}" | sort -r | while read m; do umount -l \"$m\"; done; done; rm -rf /t/*' \
		|| true
fi

tmpdir=$(mktemp -d)
git clone --depth 1 https://github.com/pellcorp/creality.git "$tmpdir/creality"
bash "$root/armbian/userpatches/overlay/simpleaf/patch-install-klipper.sh" \
	"$tmpdir/creality/rpi/install-klipper.sh"
rm -rf "$tmpdir"

: >"$log"
worker=$build/run-detached-flavors.sh
cat >"$worker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
log=/home/rex/fly-build/compile-detached.log
export PATH="/mnt/wsl/docker-desktop/cli-tools/usr/bin:/usr/bin:${PATH:-/usr/bin}"
hash -r
export PESTER_TERMINAL=no
export WT_SESSION="${WT_SESSION:-fly-bian-build}"
{
  echo "=== $(date -Is) DETACHED start base+simpleaf+kiauh ver=$(tr -d '[:space:]' <"$root/FLYBIAN_VERSION") ==="
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || true
  for flavor in base simpleaf kiauh; do
    echo "=== $(date -Is) START flavor=$flavor ==="
    if bash "$root/scripts/run-armbian-compile.sh" "$flavor"; then
      echo "=== $(date -Is) OK flavor=$flavor ==="
      bash "$root/scripts/stage-flybian-release.sh" "$flavor" || true
    else
      rc=$?
      echo "=== $(date -Is) FAIL flavor=$flavor rc=$rc ==="
      exit "$rc"
    fi
  done
  echo "=== $(date -Is) ALL DONE detached ==="
  ls -lh /home/rex/fly-build/armbian-build/output/images/*.xz | tail -n 20
} >>"$log" 2>&1
EOF
chmod +x "$worker"
sed -i 's/\r$//' "$worker"

# Prefer tmux; fall back to setsid
if command -v tmux >/dev/null; then
	tmux kill-session -t flybuild 2>/dev/null || true
	tmux new-session -d -s flybuild "$worker"
	echo "started tmux session flybuild"
	tmux ls
else
	setsid "$worker" </dev/null >/dev/null 2>&1 &
	echo "started setsid PID=$!"
fi
sleep 20
tail -n 25 "$log" || true
pgrep -af 'compile.sh build|run-detached-flavors' || true
