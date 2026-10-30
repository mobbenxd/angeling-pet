#!/bin/bash
# Build the release files into dist/:
#   Angeling.zip                ready-to-install bundle: prebuilt universal app + artwork + scripts
#   spritesheet.webp, emote-*.gif, levelup.mp3, characters.zip
#                               the artwork alone, for installs from a git clone
# Publish with:  gh release create vX.Y.Z dist/* --title ... --notes ...
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?usage: scripts/package.sh <version, e.g. 1.0.0>}"
DIST="$ROOT/dist"
STAGE="$DIST/stage/angeling-pet"
rm -rf "$DIST"
mkdir -p "$STAGE"

"$ROOT/scripts/fetch-assets.sh"

# Universal app (Apple silicon + Intel), macOS 13+.
for arch in arm64 x86_64; do
  ANGELING_TARGET="$arch-apple-macos13" ANGELING_VERSION="$VERSION" "$ROOT/scripts/build.sh" "$DIST/stage/$arch/Angeling.app" >/dev/null
done
cp -R "$DIST/stage/arm64/Angeling.app" "$STAGE/Angeling.app"
lipo -create "$DIST/stage/arm64/Angeling.app/Contents/MacOS/Angeling" "$DIST/stage/x86_64/Angeling.app/Contents/MacOS/Angeling" \
     -output "$STAGE/Angeling.app/Contents/MacOS/Angeling"
codesign --force --sign - "$STAGE/Angeling.app" >/dev/null 2>&1

mkdir -p "$STAGE/scripts" "$STAGE/hooks"
cp -R "$ROOT/assets" "$STAGE/assets"
cp "$ROOT/hooks/angeling-hook.sh" "$STAGE/hooks/"
cp "$ROOT/scripts/fetch-assets.sh" "$STAGE/scripts/"
cp "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT/LICENSE" "$ROOT/README.md" "$STAGE/"
(cd "$DIST/stage" && ditto -c -k --keepParent angeling-pet "$DIST/Angeling.zip")

cp "$ROOT/assets/spritesheet.webp" "$ROOT/assets/sounds/levelup.mp3" "$DIST/"
[ -s "$ROOT/assets/characters/characters.json" ] || { echo "assets/characters is missing; run scripts/import-characters.py" >&2; exit 1; }
(cd "$ROOT/assets/characters" && zip -qX "$DIST/characters.zip" characters.json *.png)
for f in "$ROOT"/assets/emotes/*.gif; do cp "$f" "$DIST/emote-$(basename "$f")"; done
echo "App architectures: $(lipo -archs "$STAGE/Angeling.app/Contents/MacOS/Angeling")"
rm -rf "$DIST/stage"
ls -lh "$DIST"
