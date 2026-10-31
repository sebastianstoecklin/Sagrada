#!/bin/bash
# Keep notices with the installed app, not just alongside it in the release ZIP.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
destination="${1:?Usage: bundle-legal.sh DESTINATION}"
mkdir -p "$destination/JankyBorders"
# legal/LICENSE.txt is a repository symlink; ship its contents, not a dangling link.
COPYFILE_DISABLE=1 cp -RL "$root/legal/." "$destination/"
COPYFILE_DISABLE=1 cp "$root/vendor/JankyBorders/LICENSE" \
    "$root/vendor/JankyBorders/README.sagrada.md" "$destination/JankyBorders/"
