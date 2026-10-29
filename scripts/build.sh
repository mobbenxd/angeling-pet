#!/bin/bash
# Build Angeling.app (default: ~/Applications/Angeling.app).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-$HOME/Applications/Angeling.app}"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O ${ANGELING_TARGET:+-target "$ANGELING_TARGET"} -o "$APP/Contents/MacOS/Angeling" "$ROOT/src/main.swift" -framework AppKit -framework Carbon -framework EventKit -lsqlite3
VERSION="${ANGELING_VERSION:-dev}"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>local.angeling.pet</string>
  <key>CFBundleName</key><string>Angeling</string>
  <key>CFBundleExecutable</key><string>Angeling</string>
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
