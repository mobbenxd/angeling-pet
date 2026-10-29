#!/bin/bash
# Remove Angeling: app, login item and Claude Code hooks. Keeps ~/.claude/angeling-pet
# unless --purge is given.
set -euo pipefail
RUNTIME="$HOME/.claude/angeling-pet"
SETTINGS="$HOME/.claude/settings.json"
PLIST="$HOME/Library/LaunchAgents/local.angeling.pet.plist"

pkill -x Angeling 2>/dev/null || true
launchctl bootout "gui/$(id -u)/local.angeling.pet" 2>/dev/null || true
rm -f "$PLIST"
rm -rf "$HOME/Applications/Angeling.app"

if [ -f "$SETTINGS" ] && command -v jq >/dev/null; then
  cp "$SETTINGS" "$SETTINGS.angeling-backup"
  jq '
    if .hooks then
      .hooks |= (with_entries(.value |= map(select(([.hooks[]?.command] | map(tostring | contains("angeling-pet/hook.sh")) | any) | not)))
                 | with_entries(select(.value | length > 0)))
    else . end' "$SETTINGS.angeling-backup" > "$SETTINGS.tmp" && jq -e . "$SETTINGS.tmp" >/dev/null && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "Removed hooks from $SETTINGS (backup: $SETTINGS.angeling-backup)"
fi

if [ "${1:-}" = "--purge" ]; then
  rm -rf "$RUNTIME"
  defaults delete local.angeling.pet 2>/dev/null || true
  echo "Removed $RUNTIME and preferences"
fi
echo "Angeling uninstalled."
