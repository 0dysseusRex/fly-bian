#!/usr/bin/env python3
"""Insert fly-help / fly-start / fly-kiauh / cameras into Armbian MOTD Commands."""
from __future__ import annotations

import re
import sys
from pathlib import Path

path = Path(sys.argv[1] if len(sys.argv) > 1 else "/etc/update-motd.d/41-commands")
flavor = (sys.argv[2] if len(sys.argv) > 2 else "").strip().lower()
if not flavor:
    try:
        flavor = Path("/etc/fly-debian/stack-flavor").read_text().strip().lower()
    except OSError:
        flavor = "base"

if not path.is_file():
    print(f"patch-armbian-commands: {path} missing (rely on 42-fly-commands)", file=sys.stderr)
    raise SystemExit(0)

text = path.read_text()

# Drop any previous Fly-bian MOTD rows so re-bake / flavor switch is idempotent.
text2 = re.sub(
    r'\n[ \t]*"(?:Help|Install|Start|KIAUH|Cameras)","","(?:fly-help|fly-start|fly-kiauh|fly-crowsnest-add-cams)","true"',
    "",
    text,
)

m = re.search(r"list=\(\n(?:[ \t]*\".*\"\n)+\)", text2)
if not m:
    raise SystemExit(f"patch-armbian-commands: list=(...) not found in {path}")

if flavor == "kiauh":
    rows = (
        '    "Help","","fly-help","true"\n'
        '    "KIAUH","","fly-kiauh","true"\n'
        '    "Cameras","","fly-crowsnest-add-cams","true"\n'
    )
elif flavor == "simpleaf":
    rows = (
        '    "Help","","fly-help","true"\n'
        '    "Install","","fly-start","true"\n'
    )
else:
    rows = '    "Help","","fly-help","true"\n'

block = m.group(0)
new_block = block[:-1] + rows + ")"
path.write_text(text2[: m.start()] + new_block + text2[m.end() :])
print(f"patch-armbian-commands: patched {path} (flavor={flavor})")
