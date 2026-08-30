#!/usr/bin/env bash
# smoke.sh — end-to-end verification of the wrfm skill's environment:
# wrfm CLI present + magick present + sample models clean + image pipeline works.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
echo "== 1. wrfm CLI =="
command -v wrfm >/dev/null || { echo "FAIL: wrfm CLI not on PATH" >&2; exit 1; }
wrfm format >/dev/null   # a stale (pre-format) binary exits non-zero here

echo "== 2. ImageMagick =="
command -v magick >/dev/null || { echo "FAIL: magick not on PATH" >&2; exit 1; }

echo "== 3. reference samples check (broken fails; warnings allowed) =="
for f in "$REPO"/references/wrfm_assests/*.wrfm; do
  ec=0
  out="$(wrfm check "$f" 2>&1)" || ec=$?
  verdict="$(printf '%s\n' "$out" | grep -oE '^(ok|warn|broken):' | head -1)"
  echo "  $(basename "$f"): ${verdict:-no-verdict} (exit $ec)"
  # warn is acceptable for reference samples; broken or an uncheckable model fails.
  if [ "$ec" -ge 2 ] || [ "$verdict" = "broken:" ]; then
    echo "FAIL: $f is broken or uncheckable" >&2
    exit 1
  fi
done

echo "== 4. image pipeline: six-view montage =="
"$REPO/scripts/wrfm-shot.sh" "$REPO/references/wrfm_assests/anvil.wrfm" /tmp/wrfm-smoke.png
[ -s /tmp/wrfm-smoke.png ] || { echo "FAIL: montage PNG is empty" >&2; exit 1; }
magick identify /tmp/wrfm-smoke.png

echo "== 5. image pipeline: single-view close-up =="
"$REPO/scripts/wrfm-shot.sh" "$REPO/references/wrfm_assests/anvil.wrfm" /tmp/wrfm-smoke-zoom.png --views front
[ -s /tmp/wrfm-smoke-zoom.png ] || { echo "FAIL: zoom PNG is empty" >&2; exit 1; }

echo "== 6. image content is non-blank (objective check) =="
# mean brightness must be clearly above a blank image (0) and below a white one.
# A rendered cube on a dark background measures ~0.05-0.15.
for img in /tmp/wrfm-smoke.png /tmp/wrfm-smoke-zoom.png; do
  mean="$(magick "$img" -colorspace gray -format '%[fx:mean]' info:)"
  awk -v m="$mean" -v f="$img" 'BEGIN{ if (m > 0.001 && m < 0.999) { print "  " f " mean=" m " OK"; exit 0 } print "FAIL: blank image " f " mean=" m; exit 1 }'
done

echo "NOTE: the visual check (a human or a multimodal model reads the PNGs and"
echo "confirms the anvil is visible) is the operator's step — not part of this gate."

echo "SMOKE OK"
