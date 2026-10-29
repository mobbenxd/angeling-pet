#!/bin/bash
# One-line installer for Angeling (no Xcode, git or Claude Code needed):
#   curl -fsSL https://raw.githubusercontent.com/mobbenxd/angeling-pet/main/get.sh | bash
# Downloads the latest release bundle (prebuilt app + artwork) and runs its install.sh.
# Arguments pass through, e.g. `| bash -s -- --no-login`.
set -euo pipefail
URL="${ANGELING_BUNDLE_URL:-https://github.com/mobbenxd/angeling-pet/releases/latest/download/Angeling.zip}"

[ "$(uname)" = "Darwin" ] || { echo "Angeling runs on macOS only." >&2; exit 1; }
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "==> Downloading Angeling"
curl -fL --progress-bar --retry 3 -o "$TMP/Angeling.zip" "$URL"
ditto -x -k "$TMP/Angeling.zip" "$TMP"
bash "$TMP/angeling-pet/install.sh" "$@"
