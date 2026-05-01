#!/bin/bash

REGION=$(slurp)
if [ -z "$REGION" ]; then
  notify-send "OCR" "No area selected"
  exit 1
fi

TMP=$(mktemp /tmp/ocr_XXXXXX)
grim -g "$REGION" "$TMP"
TEXT=$(tesseract "$TMP" stdout 2>/dev/null | xargs)
rm -f "$TMP"

if [ -z "$TEXT" ]; then
  notify-send "OCR" "No text recognized"
  exit 1
fi

echo -n "$TEXT" | wl-copy
notify-send "OCR(copied to clipboard): " "${TEXT}"
