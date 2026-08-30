#!/usr/bin/env bash
# wrfm-shot.sh — turn a .wrfm model into a PNG image a multimodal model can SEE.
# Usage:
#   wrfm-shot.sh <model.wrfm> <out.png>                 # all six standard views, 2x3 montage
#   wrfm-shot.sh <model.wrfm> <out.png> --views front   # extra args are passed to `wrfm render`
#                                                       #   (single view / group / region / camera)
# Depends on: `wrfm` CLI on PATH, ImageMagick (`magick`).
set -euo pipefail

MODEL="${1:?usage: wrfm-shot.sh <model.wrfm> <out.png> [render args...]}"
OUT="${2:?usage: wrfm-shot.sh <model.wrfm> <out.png> [render args...]}"
shift 2

BG='#0d1117'   # dark background, any terminal
FG='#9cdcfe'   # light blue foreground — visible on dark
PT=16          # pointsize: 120 braille cols * ~9.8px/char -> ~1180px wide per view

command -v wrfm  >/dev/null || { echo "wrfm-shot: wrfm CLI not found on PATH" >&2; exit 2; }
command -v magick >/dev/null || { echo "wrfm-shot: magick not found on PATH" >&2; exit 2; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Pick a font that can actually draw braille (U+2800). The previous first
# candidate, DejaVu-Sans-Mono, is installed almost everywhere but deliberately
# lacks the braille block — a "successful" render comes out blank. DejaVu-Sans
# is the most universal braille-capable face; Adwaita-Mono is the mono
# equivalent when a GNOME desktop put it there.
FONT=''
if command -v fc-list >/dev/null 2>&1; then
  fc-list ':charset=2800' --format '%{family}\n' 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | cut -d, -f1 | sort -u \
    > "$tmp/braille-fonts.txt"
  for f in Adwaita-Mono DejaVu-Sans DejaVu-Serif; do
    if grep -Fixq "$f" "$tmp/braille-fonts.txt"; then FONT="$f"; break; fi
  done
fi
if [ -z "$FONT" ]; then
  FONTLIST="$(magick -list font)"
  for f in DejaVu-Sans-Mono Monospace; do
    if grep -qi "$f" <<< "$FONTLIST"; then FONT="$f"; break; fi
  done
  [ -n "$FONT" ] || FONT='Monospace'
fi

to_png() { # $1 = output path; reads render text from stdin
  magick -background "$BG" -fill "$FG" -font "$FONT" -pointsize "$PT" label:@- "$1"
}

if [ "$#" -gt 0 ]; then
  # explicit render args -> ONE frame (single view / group / region / camera)
  wrfm render "$MODEL" --format braille --width 120 --height 60 "$@" | to_png "$OUT"
else
  i=0
  for v in front back left right top bottom; do
    wrfm render "$MODEL" --format braille --width 120 --height 60 --views "$v" | to_png "$tmp/$i.png"
    i=$((i + 1))
  done
  magick montage "$tmp"/*.png -tile 2x -geometry +6+6 -background "$BG" "$OUT"
fi

echo "wrfm-shot: wrote $OUT ($(wc -c < "$OUT") bytes)"
