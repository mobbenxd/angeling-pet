#!/bin/bash
# Fetch the artwork and sound Angeling needs into assets/. They are not in git: they belong to
# Gravity (Ragnarok Online), so they are published as GitHub Release assets instead.
#   assets/spritesheet.webp   Codex pet sprite sheet (v2, 1536x2288)
#   assets/emotes/*.gif       Ragnarok Online emotes (/lv /heh /swt /wah /omg /slur)
#   assets/sounds/levelup.mp3 Ragnarok Online level-up sound (reminder chime)
#   assets/characters/        Bomber characters to pick from (scripts/import-characters.py)
#   assets/pets/<id>/         extra Codex v2 pets to pick from, e.g. Bee Husky (scripts/import-pet.swift)
# Sources, first that works: a local Codex pet (sprite sheet only), the latest GitHub Release,
# then the original sites (irowiki.org, myinstants.com).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/assets"
RELEASE="${ANGELING_RELEASE_URL:-https://github.com/mobbenxd/angeling-pet/releases/latest/download}"
mkdir -p "$ASSETS/emotes" "$ASSETS/sounds"

# download URL OUT CHECK: fetch to a temp file, keep it only if `file` says it is CHECK.
download() {
  local tmp
  tmp=$(mktemp)
  if curl -fsSL --retry 3 --retry-delay 2 --retry-all-errors -A "Mozilla/5.0" -o "$tmp" "$1" 2>/dev/null \
     && file -b "$tmp" | grep -qi "$3"; then
    chmod 644 "$tmp"; mv "$tmp" "$2"; return 0
  fi
  rm -f "$tmp"; return 1
}

# 1. Sprite sheet: ANGELING_CODEX_PET=<name> picks one of your Codex pets; default is Angeling.
out="$ASSETS/spritesheet.webp"
if [ ! -s "$out" ]; then
  SRC="$HOME/.codex/pets/${ANGELING_CODEX_PET:-angeling}/spritesheet.webp"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$out"; echo "Sprite sheet: copied from $SRC"
  elif [ -n "${ANGELING_CODEX_PET:-}" ]; then
    echo "No Codex pet '$ANGELING_CODEX_PET' at $SRC" >&2; exit 1
  elif download "$RELEASE/spritesheet.webp" "$out" "image"; then
    echo "Sprite sheet: Angeling (downloaded)"
  else
    echo "Could not download the Angeling sprite sheet. Check your internet connection, or put a" >&2
    echo "Codex v2 sprite sheet at $out (1536x2288, 8 cols x 11 rows of 192x208)." >&2
    exit 1
  fi
fi

# 2. Emotes
for pair in lv:b/b6/Lov.gif heh:5/57/Heh.gif swt:1/17/Swt.gif wah:5/5c/Wah.gif omg:8/80/Omg.gif slur:4/4c/Slur.gif; do
  name=${pair%%:*}; path=${pair#*:}
  out="$ASSETS/emotes/$name.gif"
  [ -s "$out" ] && continue
  if download "$RELEASE/emote-$name.gif" "$out" "GIF" || download "https://irowiki.org/w/images/$path" "$out" "GIF"; then
    echo "Emote: $name"
  else
    echo "Could not download emote '$name' (Angeling works without it)" >&2
  fi
done

# 3. Reminder chime
out="$ASSETS/sounds/levelup.mp3"
if [ ! -s "$out" ]; then
  if download "$RELEASE/levelup.mp3" "$out" "audio" \
     || download "https://www.myinstants.com/media/sounds/ragnarok-online-level-up-sound.mp3" "$out" "audio"; then
    echo "Sound: levelup"
  else
    echo "Could not download the level-up sound (reminders use a macOS sound instead)" >&2
  fi
fi

# 4. Bomber characters (the release only)
out="$ASSETS/characters"
if [ ! -s "$out/characters.json" ]; then
  zip=$(mktemp)
  if download "$RELEASE/characters.zip" "$zip" "Zip" && mkdir -p "$out" && unzip -qo "$zip" -d "$out"; then
    echo "Characters: $(($(ls "$out" | wc -l) - 1)) sheets"
  else
    rm -rf "$out"
    echo "Could not download the Bomber characters (Angeling works without them)" >&2
  fi
  rm -f "$zip"
fi

# 5. Extra Codex pets (the release only)
out="$ASSETS/pets"
if ! ls "$out"/*/pet.json >/dev/null 2>&1; then
  zip=$(mktemp)
  if download "$RELEASE/pets.zip" "$zip" "Zip" && mkdir -p "$out" && unzip -qo "$zip" -d "$out"; then
    echo "Pets: $(ls "$out" | tr '\n' ' ')"
  else
    rm -rf "$out"
    echo "Could not download the extra pets (Angeling works without them)" >&2
  fi
  rm -f "$zip"
fi
