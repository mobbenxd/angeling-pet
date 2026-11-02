#!/bin/bash
# Build Angeling.app (default: ~/Applications/Angeling.app).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-$HOME/Applications/Angeling.app}"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# macOS 13 matches LSMinimumSystemVersion below; left to itself, swiftc targets the SDK, which can be newer than this Mac.
swiftc -O -target "${ANGELING_TARGET:-$(uname -m)-apple-macos13}" -o "$APP/Contents/MacOS/Angeling" "$ROOT/src/main.swift" -framework AppKit -framework Carbon -framework EventKit -framework SwiftUI
# App icon from Angeling's artwork (© Gravity, never committed): the repo's assets/, else the installed copy.
for SHEET in "$ROOT/assets/spritesheet.webp" "$HOME/.claude/angeling-pet/spritesheet.webp"; do
  if [ -f "$SHEET" ]; then
    swift "$ROOT/scripts/make-icon.swift" "$SHEET" "$APP/Contents/Resources/AppIcon.icns" || echo "warning: app icon not made" >&2
    break
  fi
done
# Version: ANGELING_VERSION, else the latest git tag (so source builds get update notices), else "dev".
TAG=$(git -C "$ROOT" describe --tags --abbrev=0 2>/dev/null || true)
VERSION="${ANGELING_VERSION:-${TAG#v}}"
VERSION="${VERSION:-dev}"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>local.angeling.pet</string>
  <key>CFBundleName</key><string>Angeling</string>
  <key>CFBundleExecutable</key><string>Angeling</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>LSUIElement</key><true/>
  <key>NSCalendarsFullAccessUsageDescription</key><string>Angeling adds your reminders to Calendar and follows them if you move or delete the event.</string>
  <key>NSCalendarsUsageDescription</key><string>Angeling adds your reminders to Calendar and follows them if you move or delete the event.</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "Built $APP"
