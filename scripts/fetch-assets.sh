#!/bin/bash
# Fetch the artwork Angeling needs. These files are not in the repo: they belong to
# their owners (Gravity / the Codex pet author), so each user fetches their own copy.
#   assets/spritesheet.webp  - Codex pet sprite sheet (v2, 1536x2288), taken from ~/.codex/pets
#   assets/emotes/*.gif      - Ragnarok Online emotes, downloaded from irowiki.org
#   assets/sounds/levelup.mp3 - Ragnarok Online level-up sound (reminder chime), from myinstants.com
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/assets"
mkdir -p "$ASSETS/emotes" "$ASSETS/sounds"

# 1. Sprite sheet: any Codex pet works; default is "angeling".
PET="${ANGELING_CODEX_PET:-angeling}"
if [ ! -f "$ASSETS/spritesheet.webp" ]; then
  SRC="$HOME/.codex/pets/$PET/spritesheet.webp"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$ASSETS/spritesheet.webp"
    echo "Sprite sheet: copied from $SRC"
  else
    echo "Missing sprite sheet. Install the '$PET' pet in Codex, or put a Codex v2 sprite sheet at" >&2
    echo "  $ASSETS/spritesheet.webp  (1536x2288 WebP/PNG, 8 cols x 11 rows of 192x208)" >&2
    exit 1
  fi
fi

# 2. Emotes from https://irowiki.org/wiki/Emotes
WIKI="https://irowiki.org/w/images"
for pair in lv:b/b6/Lov.gif heh:5/57/Heh.gif swt:1/17/Swt.gif wah:5/5c/Wah.gif omg:8/80/Omg.gif slur:4/4c/Slur.gif; do
  name=${pair%%:*}; path=${pair#*:}
  out="$ASSETS/emotes/$name.gif"
  [ -s "$out" ] && continue
  tmp=$(mktemp)
  if curl -fsSL --retry 4 --retry-delay 3 --retry-all-errors -A "Mozilla/5.0" -o "$tmp" "$WIKI/$path" && head -c 6 "$tmp" | grep -q "GIF8"; then
    mv "$tmp" "$out"; echo "Emote: $name"
  else
    rm -f "$tmp"; echo "Could not download emote '$name' (Angeling works without it)" >&2
  fi
done

# 3. Reminder chime: the Ragnarok Online level-up sound.
out="$ASSETS/sounds/levelup.mp3"
if [ ! -s "$out" ]; then
  tmp=$(mktemp)
  if curl -fsSL --retry 4 --retry-delay 3 --retry-all-errors -A "Mozilla/5.0" -o "$tmp" \
       "https://www.myinstants.com/media/sounds/ragnarok-online-level-up-sound.mp3" \
     && file -b "$tmp" | grep -qi "audio"; then
    chmod 644 "$tmp"; mv "$tmp" "$out"; echo "Sound: levelup"
  else
    rm -f "$tmp"; echo "Could not download the level-up sound (reminders use a macOS sound instead)" >&2
  fi
fi
