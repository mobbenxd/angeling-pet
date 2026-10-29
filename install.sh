#!/bin/bash
# Install Angeling: build the app, install the Claude Code hook, start at login.
#   ./install.sh               full install
#   ./install.sh --no-login    skip the login item
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
RUNTIME="$HOME/.claude/angeling-pet"
APP="$HOME/Applications/Angeling.app"
SETTINGS="$HOME/.claude/settings.json"
PLIST="$HOME/Library/LaunchAgents/local.angeling.pet.plist"
HOOK_CMD="bash $RUNTIME/hook.sh"
EVENTS='["SessionStart","UserPromptSubmit","PreToolUse","PostToolUse","PostToolUseFailure","Notification","PermissionRequest","Stop","StopFailure","SubagentStop","SessionEnd"]'
LOGIN=1
[ "${1:-}" = "--no-login" ] && LOGIN=0

[ "$(uname)" = "Darwin" ] || { echo "Angeling runs on macOS only." >&2; exit 1; }
command -v swiftc >/dev/null || { echo "swiftc not found. Install Xcode Command Line Tools: xcode-select --install" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq not found. Install it: brew install jq" >&2; exit 1; }

echo "==> Assets"
"$ROOT/scripts/fetch-assets.sh"

echo "==> Build"
"$ROOT/scripts/build.sh" "$APP"

echo "==> Runtime files ($RUNTIME)"
mkdir -p "$RUNTIME/state" "$RUNTIME/emotes"
cp "$ROOT/hooks/angeling-hook.sh" "$RUNTIME/hook.sh"
chmod +x "$RUNTIME/hook.sh"
cp "$ROOT/assets/spritesheet.webp" "$RUNTIME/spritesheet.webp"
cp "$ROOT"/assets/emotes/*.gif "$RUNTIME/emotes/" 2>/dev/null || true

echo "==> Claude Code hooks ($SETTINGS)"
mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.angeling-backup"
jq --arg cmd "$HOOK_CMD" --argjson events "$EVENTS" '
  reduce $events[] as $e (.;
    if ((.hooks[$e] // []) | map(.hooks[]?.command) | index($cmd)) != null then .
    else .hooks[$e] = ((.hooks[$e] // []) + [{"matcher": "*", "hooks": [{"type": "command", "command": $cmd, "timeout": 5}]}])
    end)' "$SETTINGS.angeling-backup" > "$SETTINGS.tmp" && jq -e . "$SETTINGS.tmp" >/dev/null && mv "$SETTINGS.tmp" "$SETTINGS"
echo "    (backup: $SETTINGS.angeling-backup)"

if [ "$LOGIN" = 1 ]; then
  echo "==> Start at login ($PLIST)"
  mkdir -p "$(dirname "$PLIST")"
  cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>local.angeling.pet</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/open</string>
    <string>-a</string>
    <string>$APP</string>
  </array>
  <key>RunAtLoad</key><true/>
</dict>
</plist>
PLIST
  launchctl bootout "gui/$(id -u)/local.angeling.pet" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST" 2>/dev/null || true
fi

echo "==> Launch"
pkill -x Angeling 2>/dev/null || true
sleep 0.5
open "$APP"
echo "Done. Angeling is in the bottom-right corner; ⌥⌘A shows/hides it."
