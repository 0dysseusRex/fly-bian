#!/usr/bin/env bash
# Deprecated wrapper — use stage-flybian-release.sh (Fly-bian product names).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
echo "note: stage-all-releases.sh now delegates to stage-flybian-release.sh" >&2
exec "$root/scripts/stage-flybian-release.sh" all
