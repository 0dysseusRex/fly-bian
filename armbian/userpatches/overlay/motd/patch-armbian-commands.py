#!/usr/bin/env python3
"""Insert fly-help / fly-start into Armbian MOTD Commands list (41-commands)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

path = Path(sys.argv[1] if len(sys.argv) > 1 else "/etc/update-motd.d/41-commands")
if not path.is_file():
    print(f"patch-armbian-commands: {path} missing (rely on 42-fly-commands)", file=sys.stderr)
    raise SystemExit(0)

text = path.read_text()
if "fly-help" in text:
    print(f"patch-armbian-commands: already patched {path}")
    raise SystemExit(0)

# Armbian list entries can contain escaped quotes inside the condition field.
m = re.search(r"list=\(\n(?:[ \t]*\".*\"\n)+\)", text)
if not m:
    raise SystemExit(f"patch-armbian-commands: list=(...) not found in {path}")

block = m.group(0)
new_block = block[:-1] + (
    '    "Help","","fly-help","true"\n'
    '    "Install","","fly-start","true"\n'
    ")"
)
path.write_text(text[: m.start()] + new_block + text[m.end() :])
print(f"patch-armbian-commands: patched {path}")
