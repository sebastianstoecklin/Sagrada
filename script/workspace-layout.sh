#!/bin/bash
# Compatibility entry point for configs predating native workspace window modes.
set -euo pipefail
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
case "${1:-}" in
  toggle) exec sagrada layout --root floating tiling ;;
  detected) exit 0 ;; # New and restored windows now inherit the native workspace mode.
  *) printf 'Usage: %s toggle|detected\n' "$0" >&2; exit 2 ;;
esac
