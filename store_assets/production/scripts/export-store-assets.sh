#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/src"
DIST="$ROOT/dist"

mkdir -p "$DIST"

export_svg() {
  local input="$1"
  local name="$2"
  local width="$3"

  rm -f "$DIST/$name.png" "$DIST/$(basename "$input").png"
  qlmanage -t -s "$width" -o "$DIST" "$input" >/dev/null 2>&1
  mv "$DIST/$(basename "$input").png" "$DIST/$name.png"
}

export_svg "$SRC/google-play-feature.svg" "google-play-feature" 1024
export_svg "$SRC/app-store-01-input.svg" "app-store-01-input" 1290
export_svg "$SRC/app-store-02-results.svg" "app-store-02-results" 1290

echo "Exported store assets to $DIST"
