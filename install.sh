#!/bin/bash
# Install Angeling: the app, its artwork, start at login, and the Claude Code hook if Claude Code is here.
#   ./install.sh               full install
#   ./install.sh --no-login    skip the login item
# Runs from a release bundle (ships a prebuilt Angeling.app next to this script) or from a git
# clone (builds the app, which needs the Xcode Command Line Tools).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
RUNTIME="$HOME/.claude/angeling-pet"
APP="$HOME/Applications/Angeling.app"
SETTINGS="$HOME/.claude/settings.json"
PLIST="$HOME/Library/LaunchAgents/local.angeling.pet.plist"
HOOK_CMD="bash $RUNTIME/hook.sh"
EVENTS='["SessionStart","UserPromptSubmit","PreToolUse","PostToolUse","PostToolUseFailure","Notification","PermissionRequest","Stop","StopFailure","SubagentStop","SessionEnd"]'
LOGIN=1
for a in "$@"; do [ "$a" = "--no-login" ] && LOGIN=0; done

[ "$(uname)" = "Darwin" ] || { echo "Angeling runs on macOS only." >&2; exit 1; }
[ "$(sw_vers -productVersion | cut -d. -f1)" -ge 13 ] || { echo "Angeling needs macOS 13 or later." >&2; exit 1; }

echo "==> Artwork"
"$ROOT/scripts/fetch-assets.sh"

echo "==> App ($APP)"
# -a: when Angeling itself started this update it is our ancestor, which pkill skips by default.
pkill -a -x Angeling 2>/dev/null || true
if [ -d "$ROOT/Angeling.app" ]; then
  mkdir -p "$(dirname "$APP")"
  rm -rf "$APP"
  cp -R "$ROOT/Angeling.app" "$APP"
  # A bundle downloaded with a browser carries the quarantine flag, and Gatekeeper refuses
  # this unsigned app; the one-line installer (curl) never sets it.
  xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true
  echo "    installed the prebuilt app"
else
  command -v swiftc >/dev/null || {
    echo "swiftc not found. Install the Xcode Command Line Tools (xcode-select --install)," >&2
    echo "or use the one-line installer, which needs no compiler (see README)." >&2
    exit 1
  }
  "$ROOT/scripts/build.sh" "$APP"
fi

echo "==> Files ($RUNTIME)"
mkdir -p "$RUNTIME/state" "$RUNTIME/emotes" "$RUNTIME/sounds"
cp "$ROOT/hooks/angeling-hook.sh" "$RUNTIME/hook.sh"
cp "$ROOT/uninstall.sh" "$RUNTIME/uninstall.sh"
chmod +x "$RUNTIME/hook.sh" "$RUNTIME/uninstall.sh"
cp "$ROOT/assets/spritesheet.webp" "$RUNTIME/spritesheet.webp"
cp "$ROOT"/assets/emotes/*.gif "$RUNTIME/emotes/" 2>/dev/null || true
cp "$ROOT"/assets/sounds/*.mp3 "$RUNTIME/sounds/" 2>/dev/null || true
if [ -s "$ROOT/assets/characters/characters.json" ]; then
  rm -rf "$RUNTIME/characters"
  cp -R "$ROOT/assets/characters" "$RUNTIME/characters"
fi

echo "==> Claude Code"
CLAUDE=0
if [ -f "$SETTINGS" ] || command -v claude >/dev/null || [ -d "$HOME/.claude/projects" ]; then
  JQ=$(command -v jq || true)
  [ -z "$JQ" ] && [ -x /opt/homebrew/bin/jq ] && JQ=/opt/homebrew/bin/jq
  if [ -z "$JQ" ]; then
    echo "    jq not found, so the session hook was skipped. Install it (brew install jq) and run this again."
  else
    [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
    cp "$SETTINGS" "$SETTINGS.angeling-backup"
    "$JQ" --arg cmd "$HOOK_CMD" --argjson events "$EVENTS" '
      reduce $events[] as $e (.;
        if ((.hooks[$e] // []) | map(.hooks[]?.command) | index($cmd)) != null then .
        else .hooks[$e] = ((.hooks[$e] // []) + [{"matcher": "*", "hooks": [{"type": "command", "command": $cmd, "timeout": 5}]}])
        end)' "$SETTINGS.angeling-backup" > "$SETTINGS.tmp" && "$JQ" -e . "$SETTINGS.tmp" >/dev/null && mv "$SETTINGS.tmp" "$SETTINGS"
    echo "    hook added to $SETTINGS (backup: $SETTINGS.angeling-backup)"
    CLAUDE=1
  fi
else
  echo "    not installed, so the session hook was skipped. Reminders, LINE and Discord work without it."
  echo "    Installed Claude Code later? Run the installer again."
fi

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

if [ -z "${ANGELING_NO_LAUNCH:-}" ]; then
  echo "==> Launch"
  sleep 0.5
  open "$APP"
fi
echo
echo "Done! Angeling is in the bottom-right corner of your screen."
echo "  ⌥⌘R  set a reminder        ⌥⌘A  show / hide Angeling"
if [ "$CLAUDE" = 1 ]; then echo "  Give Claude Code a task and Angeling reports it."; fi
echo "  Uninstall: $RUNTIME/uninstall.sh"
