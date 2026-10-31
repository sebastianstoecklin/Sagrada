#!/bin/bash
# Build the pinned, bundled JankyBorders helper without Homebrew or network access.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
output="${1:-$root/.build/helpers/sagrada-borders}"
mkdir -p "$(dirname "$output")"
cd "$root/vendor/JankyBorders"
/usr/bin/xcrun clang -std=c99 -O3 -arch arm64 -arch x86_64 \
    -mmacosx-version-min=14.0 \
    src/main.c src/parse.c src/mach.c src/hashtable.c src/events.c \
    src/windows.c src/border.c src/animation.c \
    -framework AppKit -framework CoreVideo \
    -F/System/Library/PrivateFrameworks/ -framework SkyLight -o "$output"
/usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY:--}" "$output"
