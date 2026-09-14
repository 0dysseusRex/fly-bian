#!/usr/bin/env bash
set -euo pipefail
root=/mnt/c/Users/udrdr/fly-debian
build=/home/rex/fly-build/armbian-build

echo "=== staging already-built Base as Fly-bian-0.1 ==="
bash "$root/scripts/stage-flybian-release.sh" base || true

echo "=== hard cleanup ==="
docker ps -aq | xargs -r docker rm -f || true
# stop any leftover build containers
docker ps -a --format '{{.ID}} {{.Image}}' | grep -i armbian | awk '{print $1}' | xargs -r docker rm -f || true
# remove tmp dirs aggressively from inside a privileged container if needed
if [[ -d $build/.tmp ]]; then
	docker run --rm --privileged -v "$build/.tmp:/tmp/armbtmp" alpine:3.20 sh -c '
	  set +e
	  for d in /tmp/armbtmp/*; do
	    [ -d "$d" ] || continue
	    mount | grep "$d" | awk "{print \$3}" | sort -r | while read -r m; do
	      umount -l "$m" 2>/dev/null
	    done
	  done
	  rm -rf /tmp/armbtmp/*
	'
fi
rm -rf "$build/.tmp" || true
mkdir -p "$build/.tmp"
echo "tmp cleaned"

bash "$root/scripts/stage-armbian-overlay.sh"
cp -a "$root/FLYBIAN_VERSION" "$root/armbian/userpatches/overlay/FLYBIAN_VERSION"
sed -i 's/\r$//' "$root/armbian/userpatches/overlay/simpleaf/patch-install-klipper.sh"

echo "=== start simpleaf only ==="
nohup bash -c "
  set -euo pipefail
  echo \"=== \$(date -Is) START flavor=simpleaf (solo) ===\" >> /home/rex/fly-build/compile-all.log
  if bash /mnt/c/Users/udrdr/fly-debian/scripts/run-armbian-compile.sh simpleaf >> /home/rex/fly-build/compile-all.log 2>&1; then
    echo \"=== \$(date -Is) OK flavor=simpleaf ===\" >> /home/rex/fly-build/compile-all.log
  else
    rc=\$?
    echo \"=== \$(date -Is) FAIL flavor=simpleaf rc=\$rc ===\" >> /home/rex/fly-build/compile-all.log
    exit \$rc
  fi
" >/home/rex/fly-build/compile-simpleaf-solo.nohup.out 2>&1 &
echo "PID=$!"
sleep 30
tail -n 15 /home/rex/fly-build/compile-all.log
pgrep -af 'compile.sh build' || true
