#!/bin/bash
# Patch pellcorp rpi/install-klipper.sh so a Fly-bian prebake can re-run the
# printer config staging (homing.cfg, macros, …) without deleting the baked
# git trees / venvs / Shake&Tune. Sourced or executed from bake.sh.
set -euo pipefail

target=${1:-}
[[ -n $target && -f $target ]] || {
	echo "patch-install-klipper: missing target" >&2
	exit 1
}

python3 - "$target" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
old1 = """  if [ \"$mode\" != \"update\" ] && [ -d $BASEDIR/klipper ]; then
    sudo systemctl stop klipper-mcu 2> /dev/null
    sudo systemctl stop klipper 2> /dev/null
    # force rebuild of klipper-mcu
    [ -f /usr/local/bin/klipper_mcu ] && sudo rm /usr/local/bin/klipper_mcu
    rm -rf $BASEDIR/klipper
  fi

  if [ \"$mode\" != \"update\" ] && [ -d $BASEDIR/klippy-env ]; then
    rm -rf $BASEDIR/klippy-env
  fi"""
new1 = """  # Fly-bian prebake: keep git trees and venvs already on the card.
  if [ -f /etc/fly-debian/prebaked-simpleaf ]; then
    FLY_PREBAKED=1
  else
    FLY_PREBAKED=0
  fi

  if [ \"$mode\" != \"update\" ] && [ -d $BASEDIR/klipper ] && [ \"$FLY_PREBAKED\" != \"1\" ]; then
    sudo systemctl stop klipper-mcu 2> /dev/null
    sudo systemctl stop klipper 2> /dev/null
    # force rebuild of klipper-mcu
    [ -f /usr/local/bin/klipper_mcu ] && sudo rm /usr/local/bin/klipper_mcu
    rm -rf $BASEDIR/klipper
  fi

  if [ \"$mode\" != \"update\" ] && [ -d $BASEDIR/klippy-env ] && [ \"$FLY_PREBAKED\" != \"1\" ]; then
    rm -rf $BASEDIR/klippy-env
  fi"""
old2 = """    if [ \"$mode\" != \"update\" ] && [ -d $BASEDIR/klippain_shaketune ]; then
      rm -rf $BASEDIR/klippain_shaketune
    fi"""
new2 = """    if [ \"$mode\" != \"update\" ] && [ -d $BASEDIR/klippain_shaketune ] && [ \"$FLY_PREBAKED\" != \"1\" ]; then
      rm -rf $BASEDIR/klippain_shaketune
    fi"""
old3 = """function update_klipper_mcu() {
  echo
  echo \"INFO: Rebuilding Klipper MCU ...\"
  cd $BASEDIR/klipper
  cp .config.linux .config
  make clean
  make || exit $?
  rm .config
  sudo systemctl stop klipper-mcu
  sudo cp out/klipper.elf /usr/local/bin/klipper_mcu || exit $?
  sudo systemctl restart klipper-mcu || exit $?
  cd - > /dev/null
}
"""
new3 = """function update_klipper_mcu() {
  if [ \"${FLY_SKIP_HOST_MCU:-1}\" = \"1\" ]; then
    echo \"INFO: Skipping Klipper host MCU rebuild (FLY_SKIP_HOST_MCU=1)\"
    return 0
  fi
  echo
  echo \"INFO: Rebuilding Klipper MCU ...\"
  cd $BASEDIR/klipper
  cp .config.linux .config
  make clean
  make || exit $?
  rm .config
  sudo systemctl stop klipper-mcu
  sudo cp out/klipper.elf /usr/local/bin/klipper_mcu || exit $?
  sudo systemctl restart klipper-mcu || exit $?
  cd - > /dev/null
}
"""
old4 = """  if [ ! -f /usr/local/bin/klipper_mcu ]; then
    echo
    echo \"INFO: Building klipper mcu ...\"

    # https://klipper.discourse.group/t/armbian-kernel-klipper-host-mcu-got-error-1-in-sched-setschedule/1193
    runtime_us=$(sudo sysctl -n kernel.sched_rt_runtime_us)
    if [ \"$runtime_us\" != \"-1\" ]; then
      sudo sysctl -w kernel.sched_rt_runtime_us=-1 > /dev/null
      echo \"kernel.sched_rt_runtime_us = -1\" | sudo tee /etc/sysctl.d/10-disable-rt-group-limit.conf > /dev/null
    fi

    cd $BASEDIR/klipper
    cp .config.linux .config
    make clean
    make || exit $?
    rm .config
    sudo cp out/klipper.elf /usr/local/bin/klipper_mcu || exit $?
    sudo cp ./scripts/klipper-mcu.service /etc/systemd/system/ || exit $?
    sudo systemctl enable klipper-mcu || exit $?
    sudo systemctl start klipper-mcu || exit $?
  fi

  # add klipper mcu
  $CONFIG_HELPER --add-section \"mcu rpi\" || exit $?
  $CONFIG_HELPER --replace-section-entry \"mcu rpi\" \"serial\" \"/tmp/klipper_host_mcu\" || exit $?
"""
new4 = """  # Fly Lite: host MCU LTO often ICE/OOMs on 512MB; K1 uses printer MCU only.
  if [ \"${FLY_SKIP_HOST_MCU:-1}\" = \"1\" ]; then
    echo
    echo \"INFO: Skipping klipper host MCU build and [mcu rpi] (FLY_SKIP_HOST_MCU=1)\"
  else
    if [ ! -f /usr/local/bin/klipper_mcu ]; then
      echo
      echo \"INFO: Building klipper mcu ...\"

      # https://klipper.discourse.group/t/armbian-kernel-klipper-host-mcu-got-error-1-in-sched-setschedule/1193
      runtime_us=$(sudo sysctl -n kernel.sched_rt_runtime_us)
      if [ \"$runtime_us\" != \"-1\" ]; then
        sudo sysctl -w kernel.sched_rt_runtime_us=-1 > /dev/null
        echo \"kernel.sched_rt_runtime_us = -1\" | sudo tee /etc/sysctl.d/10-disable-rt-group-limit.conf > /dev/null
      fi

      cd $BASEDIR/klipper
      cp .config.linux .config
      make clean
      make || exit $?
      rm .config
      sudo cp out/klipper.elf /usr/local/bin/klipper_mcu || exit $?
      sudo cp ./scripts/klipper-mcu.service /etc/systemd/system/ || exit $?
      sudo systemctl enable klipper-mcu || exit $?
      sudo systemctl start klipper-mcu || exit $?
    fi

    # add klipper mcu
    $CONFIG_HELPER --add-section \"mcu rpi\" || exit $?
    $CONFIG_HELPER --replace-section-entry \"mcu rpi\" \"serial\" \"/tmp/klipper_host_mcu\" || exit $?
  fi
"""
missing = [n for n, s in (("prebake", old1), ("shaketune", old2), ("update_mcu", old3), ("build_mcu", old4)) if s not in text]
if missing:
    raise SystemExit(f"patch-install-klipper: targets missing ({', '.join(missing)}) in {path}")
path.write_text(
    text.replace(old1, new1, 1)
    .replace(old2, new2, 1)
    .replace(old3, new3, 1)
    .replace(old4, new4, 1)
)
print(f"patch-install-klipper: patched {path}")
PY
