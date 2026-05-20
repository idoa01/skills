#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"

usage() {
  echo "Usage: $0 [--target <project-path>]"
  echo
  echo "Installs skills from the plugins/ directory into a Cursor project."
  echo "  --target  Path to the target project (default: current directory)"
  exit 1
}

TARGET_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_DIR="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

declare -a PLUGIN_NAMES=()
declare -a PLUGIN_DIRS=()
declare -a PLUGIN_CMD_COUNTS=()

for plugin_dir in "$PLUGINS_DIR"/*/; do
  [[ -d "$plugin_dir" ]] || continue
  plugin_name="$(basename "$plugin_dir")"
  count=0
  for cmd_md in "$plugin_dir"commands/*.md; do
    [[ -f "$cmd_md" ]] && count=$((count + 1))
  done
  [[ $count -gt 0 ]] || continue
  PLUGIN_NAMES+=("$plugin_name")
  PLUGIN_DIRS+=("$plugin_dir")
  PLUGIN_CMD_COUNTS+=("$count")
done

if [[ ${#PLUGIN_NAMES[@]} -eq 0 ]]; then
  echo "No plugins found in $PLUGINS_DIR."
  exit 0
fi

echo "Available plugins:"
for i in "${!PLUGIN_NAMES[@]}"; do
  printf "  [%d] %s (%d command(s))\n" "$((i+1))" "${PLUGIN_NAMES[$i]}" "${PLUGIN_CMD_COUNTS[$i]}"
done

echo
echo "Install to: $TARGET_DIR/.cursor/skills/"
read -rp "Select plugins (comma-separated numbers, or 'all'): " selection

declare -a indices=()
if [[ "$selection" == "all" ]]; then
  for i in "${!PLUGIN_NAMES[@]}"; do
    indices+=("$((i+1))")
  done
elif [[ -n "$selection" ]]; then
  IFS=',' read -ra indices <<< "$selection"
fi

for idx in "${indices[@]+"${indices[@]}"}"; do
  idx="${idx// /}"
  i="$((idx-1))"
  if [[ $i -lt 0 || $i -ge ${#PLUGIN_NAMES[@]} ]]; then
    echo "  ✗ Invalid selection: $idx"
    continue
  fi
  plugin_name="${PLUGIN_NAMES[$i]}"
  plugin_dir="${PLUGIN_DIRS[$i]}"
  plugin_dest="$TARGET_DIR/.cursor/skills/$plugin_name"

  for cmd_md in "$plugin_dir"commands/*.md; do
    [[ -f "$cmd_md" ]] || continue
    cmd_name="$(basename "$cmd_md" .md)"
    cmd_dest="$plugin_dest/$cmd_name"
    mkdir -p "$cmd_dest"
    cp "$cmd_md" "$cmd_dest/SKILL.md"
  done

  if [[ -d "$plugin_dir/docs" ]]; then
    cp -r "$plugin_dir/docs" "$plugin_dest/"
  fi

  echo "  ✓ Installed $plugin_name → $plugin_dest"
done
