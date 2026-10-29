#!/bin/bash
# Publish docs/wiki/*.md to the GitHub Wiki (https://github.com/mobbenxd/angeling-pet/wiki).
# The wiki repo only exists after its first page is created on github.com.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE="${WIKI_REMOTE:-https://github.com/mobbenxd/angeling-pet.wiki.git}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

git clone -q "$REMOTE" "$TMP/wiki" || {
  echo "Cannot clone $REMOTE. Create the first wiki page on GitHub once, then run this again." >&2
  exit 1
}
# Mirror: pages removed from docs/wiki disappear from the wiki too.
find "$TMP/wiki" -maxdepth 1 -name '*.md' -delete
cp "$ROOT"/docs/wiki/*.md "$TMP/wiki/"
cd "$TMP/wiki"
git add -A
if git diff --cached --quiet; then echo "Wiki is already up to date."; exit 0; fi
git -c user.name="$(git -C "$ROOT" config user.name)" -c user.email="$(git -C "$ROOT" config user.email)" \
  commit -q -m "Sync wiki from docs/wiki ($(git -C "$ROOT" rev-parse --short HEAD))"
git push -q origin HEAD
echo "Published $(ls "$ROOT"/docs/wiki/*.md | wc -l | tr -d ' ') pages to the wiki."
