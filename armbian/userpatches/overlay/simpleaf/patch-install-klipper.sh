#!/bin/bash
# Patch pellcorp rpi/install-klipper.sh for Fly-bian prebake:
# keep baked trees/venvs, skip host MCU by default (FLY_SKIP_HOST_MCU=1).
set -euo pipefail

target=${1:-}
[[ -n $target && -f $target ]] || {
	echo "patch-install-klipper: missing target" >&2
	exit 1
}

python3 - "$target" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
orig = text

# 1) Keep prebaked klipper / klippy-env instead of wiping them.
pat_wipe = re.compile(
    r'(  if \[ "\$mode" != "update" \] && \[ -d \$BASEDIR/klipper \]; then\n'
    r'    sudo systemctl stop klipper-mcu 2> /dev/null\n'
    r'    sudo systemctl stop klipper 2> /dev/null\n'
    r'    # force rebuild of klipper-mcu\n'
    r'    \[ -f /usr/local/bin/klipper_mcu \] && sudo rm /usr/local/bin/klipper_mcu\n'
    r'    rm -rf \$BASEDIR/klipper\n'
    r'  fi\n'
    r'\n'
    r'  if \[ "\$mode" != "update" \] && \[ -d \$BASEDIR/klippy-env \]; then\n'
    r'    rm -rf \$BASEDIR/klippy-env\n'
    r'  fi)',
    re.M,
)
repl_wipe = r'''  # Fly-bian prebake: keep git trees and venvs already on the card.
  if [ -f /etc/fly-debian/prebaked-simpleaf ]; then
    FLY_PREBAKED=1
  else
    FLY_PREBAKED=0
  fi

  if [ "$mode" != "update" ] && [ -d $BASEDIR/klipper ] && [ "$FLY_PREBAKED" != "1" ]; then
    sudo systemctl stop klipper-mcu 2> /dev/null
    sudo systemctl stop klipper 2> /dev/null
    # force rebuild of klipper-mcu
    [ -f /usr/local/bin/klipper_mcu ] && sudo rm /usr/local/bin/klipper_mcu
    rm -rf $BASEDIR/klippe
  fi

  if [ "$mode" != "update" ] && [ -d $BASEDIR/klippy-env ] && [ "$FLY_PREBAKED" != "1" ]; then
    rm -rf $BASEDIR/klippy-env
  fi'''
text, n = pat_wipe.subn(repl_wipe, text, count=1)
if n != 1:
    raise SystemExit(f"patch-install-klipper: wipe block not found in {path}")

# 2) Keep prebaked Shake&Tune tree on non-update installs.
pat_shake = re.compile(
    r'(    if \[ "\$mode" != "update" \] && \[ -d \$BASEDIR/klippain_shaketune \]; then\n'
    r'      rm -rf \$BASEDIR/klippain_shaketune\n'
    r'    fi)',
    re.M,
)
repl_shake = (
    '    if [ "$mode" != "update" ] && [ -d $BASEDIR/klippain_shaketune ] '
    '&& [ "$FLY_PREBAKED" != "1" ]; then\n'
    '      rm -rf $BASEDIR/klippain_shaketune\n'
    '    fi'
)
text, n = pat_shake.subn(repl_shake, text, count=1)
if n != 1:
    raise SystemExit(f"patch-install-klipper: shaketune wipe not found in {path}")

# 3) Skip host MCU rebuild on update path.
pat_update = re.compile(
    r'function update_klipper_mcu\(\) \{\n'
    r'  echo\n'
    r'  echo "INFO: Rebuilding Klipper MCU \.\.\."\n',
    re.M,
)
repl_update = (
    'function update_klipper_mcu() {\n'
    '  if [ "${FLY_SKIP_HOST_MCU:-1}" = "1" ]; then\n'
    '    echo "INFO: Skipping Klipper host MCU rebuild (FLY_SKIP_HOST_MCU=1)"\n'
    '    return 0\n'
    '  fi\n'
    '  echo\n'
    '  echo "INFO: Rebuilding Klipper MCU ..."\n'
)
text, n = pat_update.subn(repl_update, text, count=1)
if n != 1:
    raise SystemExit(f"patch-install-klipper: update_klipper_mcu not found in {path}")

# 4) Skip initial host MCU build + [mcu rpi] (OOM on 512MB H3).
pat_build = re.compile(
    r'  if \[ ! -f /usr/local/bin/klipper_mcu \]; then\n'
    r'    echo\n'
    r'    echo "INFO: Building klipper mcu \.\.\."\n'
    r'\n'
    r'    # https://klipper\.discourse\.group/t/armbian-kernel-klipper-host-mcu-got-error-1-in-sched-setschedule/1193\n'
    r'    runtime_us=\$\(sudo sysctl -n kernel\.sched_rt_runtime_us\)\n'
    r'    if \[ "\$runtime_us" != "-1" \]; then\n'
    r'      sudo sysctl -w kernel\.sched_rt_runtime_us=-1 > /dev/null\n'
    r'      echo "kernel\.sched_rt_runtime_us = -1" \| sudo tee /etc/sysctl\.d/10-disable-rt-group-limit\.conf > /dev/null\n'
    r'    fi\n'
    r'\n'
    r'    cd \$BASEDIR/klipper\n'
    r'    cp \.config\.linux \.config\n'
    r'    make clean\n'
    r'    make \|\| exit \$\?\n'
    r'    rm \.config\n'
    r'    sudo cp out/klipper\.elf /usr/local/bin/klipper_mcu \|\| exit \$\?\n'
    r'    sudo cp \./scripts/klipper-mcu\.service /etc/systemd/system/ \|\| exit \$\?\n'
    r'    sudo systemctl enable klipper-mcu \|\| exit \$\?\n'
    r'    sudo systemctl start klipper-mcu \|\| exit \$\?\n'
    r'  fi\n'
    r'\n'
    r'  # add klipper mcu\n'
    r'  \$CONFIG_HELPER --add-section "mcu rpi" \|\| exit \$\?\n'
    r'  \$CONFIG_HELPER --replace-section-entry "mcu rpi" "serial" "/tmp/klipper_host_mcu" \|\| exit \$\?\n',
    re.M,
)
repl_build = '''  # Fly Lite: host MCU LTO often ICE/OOMs on 512MB; K1 uses printer MCU only.
  if [ "${FLY_SKIP_HOST_MCU:-1}" = "1" ]; then
    echo
    echo "INFO: Skipping klipper host MCU build and [mcu rpi] (FLY_SKIP_HOST_MCU=1)"
  else
    if [ ! -f /usr/local/bin/klipper_mcu ]; then
      echo
      echo "INFO: Building klipper mcu ..."

      # https://klipper.discourse.group/t/armbian-kernel-klipper-host-mcu-got-error-1-in-sched-setschedule/1193
      runtime_us=$(sudo sysctl -n kernel.sched_rt_runtime_us)
      if [ "$runtime_us" != "-1" ]; then
        sudo sysctl -w kernel.sched_rt_runtime_us=-1 > /dev/null
        echo "kernel.sched_rt_runtime_us = -1" | sudo tee /etc/sysctl.d/10-disable-rt-group-limit.conf > /dev/null
      fi

      cd $BASEDIR/klippe
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
    $CONFIG_HELPER --add-section "mcu rpi" || exit $?
    $CONFIG_HELPER --replace-section-entry "mcu rpi" "serial" "/tmp/klipper_host_mcu" || exit $?
  fi
'''
text, n = pat_build.subn(repl_build, text, count=1)
if n != 1:
    raise SystemExit(f"patch-install-klipper: host MCU build block not found in {path}")

if text == orig:
    raise SystemExit(f"patch-install-klipper: no changes applied to {path}")

path.write_text(text)
print(f"patch-install-klipper: patched {path}")
PY
