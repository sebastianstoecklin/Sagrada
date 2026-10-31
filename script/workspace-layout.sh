#!/bin/bash
# Remember floating workspaces locally; never store machine state in the repository.
set -euo pipefail
# Respect the selected fork CLI on PATH before falling back to Homebrew.
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
state_dir="${AEROSPACE_LAYOUT_STATE_DIR:-$HOME/.local/state/aerospace/workspace-layout}"

marker_for() {
  # Hex encoding supports arbitrary workspace names without path traversal/collisions.
  local key
  key="$(printf '%s' "$1" | od -An -tx1 | tr -d ' \n')"
  printf '%s/%s.floating' "$state_dir" "$key"
}

case "${1:-}" in
  toggle)
    workspace="$(sagradaspace list-workspaces --focused)"
    [[ -n "$workspace" ]] || exit 0
    windows="$(sagradaspace list-windows --workspace "$workspace" --format '%{window-id}')"
    marker="$(marker_for "$workspace")"
    mkdir -p "$state_dir"
    if [[ -f "$marker" ]]; then
      rm "$marker"
      target=tiling
    else
      touch "$marker"
      target=floating
    fi
    # Set workspace state first so windows detected during the loop inherit it.
    result=0
    while IFS= read -r id; do
      [[ "$id" =~ ^[0-9]+$ ]] || continue
      sagradaspace layout --window-id "$id" "$target" || result=1
    done <<< "$windows"
    exit "$result"
    ;;
  detected)
    id="${AEROSPACE_WINDOW_ID:-}"
    [[ "$id" =~ ^[0-9]+$ ]] || exit 0
    # Resolve the detected window, not the potentially changed focused workspace.
    windows="$(sagradaspace list-windows --all --format '%{window-id}|%{workspace}')"
    while IFS='|' read -r window_id workspace; do
      [[ "$window_id" == "$id" ]] || continue
      if [[ -f "$(marker_for "$workspace")" ]]; then
        sagradaspace layout --window-id "$id" floating
      fi
      break
    done <<< "$windows"
    ;;
  *) printf 'Usage: %s toggle|detected\n' "$0" >&2; exit 2 ;;
esac
