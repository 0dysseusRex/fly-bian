#!/usr/bin/env bash
# Detached Fly Pi V3 Base bake. Survives SSH/WSL hangup.
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build
log=$build/compile-base-fly-pi-v3.log

export PATH="/mnt/wsl/docker-desktop/cli-tools/usr/bin:/usr/bin:${PATH:-/usr/bin}"
hash -r || true
export FLY_DEVICE=Fly-Pi-V3
export PESTER_TERMINAL=no
export WT_SESSION="${WT_SESSION:-fly-bian-build}"

sed -i 's/\r$//' "$root/scripts/"*.sh 2>/dev/null || true
bash "$root/scripts/stage-armbian-overlay.sh"
cp -a "$root/FLYBIAN_VERSION" "$root/armbian/userpatches/overlay/FLYBIAN_VERSION"
FLY_DEVICE=Fly-Pi-V3 bash "$root/scripts/flybian-require-new-version.sh" base

docker ps -aq | xargs -r docker rm -f || true
if [[ -d $build/armbian-build/.tmp ]]; then
	docker run --rm --privileged -v "$build/armbian-build/.tmp:/t" alpine:3.20 \
		sh -c 'for d in /t/*; do mount | awk -v p="$d" "\$3 ~ p {print \$3}" | sort -r | while read m; do umount -l \"$m\"; done; done; rm -rf /t/*' \
		|| true
fi

: >"$log"
worker=$build/run-pi-v3-base.sh
cat >"$worker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
log=/home/rex/fly-build/compile-base-fly-pi-v3.log
export PATH="/mnt/wsl/docker-desktop/cli-tools/usr/bin:/usr/bin:${PATH:-/usr/bin}"
hash -r || true
export PESTER_TERMINAL=no
export WT_SESSION="${WT_SESSION:-fly-bian-build}"
export FLY_DEVICE=Fly-Pi-V3
# Inherit FLY_FORCE from launcher (tmux worker is a fresh shell).
export FLY_FORCE=__FLY_FORCE__
# Pi V3 stays 0.70 until its own Base is the benchmark. The repo file is
# the Lite line. Stamp this image 0.70, then put the repo file back.
repo_ver_file=$root/FLYBIAN_VERSION
overlay_ver_file=$root/armbian/userpatches/overlay/FLYBIAN_VERSION
saved_repo=$(tr -d '[:space:]' <"$repo_ver_file")
saved_overlay=$(tr -d '[:space:]' <"$overlay_ver_file")
restore_versions() {
  printf '%s\n' "$saved_repo" >"$repo_ver_file"
  printf '%s\n' "$saved_overlay" >"$overlay_ver_file"
}
trap restore_versions EXIT
printf '0.70\n' >"$overlay_ver_file"
# stage-armbian-overlay.sh already copied the Lite version into the build tree.
build_ver=/home/rex/fly-build/armbian-build/userpatches/overlay/FLYBIAN_VERSION
if [[ -f $build_ver ]]; then
  printf '0.70\n' >"$build_ver"
fi
{
  echo "=== $(date -Is) START Fly-Pi-V3 Base ver=0.70 (repo $saved_repo left unchanged) ==="
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || true
  if bash "$root/scripts/run-armbian-compile.sh" pi-v3; then
    echo "=== $(date -Is) OK Fly-Pi-V3 Base ==="
    # Local stage only. Pre-1.0 is not a GitHub Release candidate.
    printf '0.70\n' >"$repo_ver_file"
    FLY_DEVICE=Fly-Pi-V3 bash "$root/scripts/stage-flybian-release.sh" base || true
    echo "=== $(date -Is) staged locally; NOT uploading to GitHub Releases (<1.0) ==="
  else
    rc=$?
    echo "=== $(date -Is) FAIL Fly-Pi-V3 Base rc=$rc ==="
    exit "$rc"
  fi
  echo "=== $(date -Is) DONE ==="
  ls -lh /home/rex/fly-build/armbian-build/output/images/*[Pp]i*[Vv]3* 2>/dev/null | tail -n 20 || \
    ls -lh /home/rex/fly-build/armbian-build/output/images/*.xz | tail -n 10
} >>"$log" 2>&1
EOF
chmod +x "$worker"
sed -i 's/\r$//' "$worker"
# Substitute FLY_FORCE into the quoted heredoc worker.
sed -i "s/__FLY_FORCE__/${FLY_FORCE:-0}/" "$worker"

if command -v tmux >/dev/null; then
	tmux kill-session -t flybuild-piv3 2>/dev/null || true
	tmux new-session -d -s flybuild-piv3 "$worker"
	echo "started tmux session flybuild-piv3"
	tmux ls
else
	setsid "$worker" </dev/null >/dev/null 2>&1 &
	echo "started setsid PID=$!"
fi
sleep 15
tail -n 30 "$log" || true
pgrep -af 'compile.sh build|run-pi-v3-base|fly-pi-v3' || true
