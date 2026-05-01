#!/bin/bash

DIC_DB="$HOME/.local/share/stardict/ecdict.db"

selected=$(cliphist list | ~/.config/wofi/wofi-wrapper --dmenu --prompt="Translate")
if [ -z "$selected" ]; then
  exit 1
fi

ORIG=$(echo "$selected" | cliphist decode)

TEXT=$(echo "$ORIG" | awk '{gsub(/^[^a-zA-Z]*|[^a-zA-Z]*$/, ""); print}' | xargs)

if [ -z "$TEXT" ]; then
  notify-send "Translate" "No English text found"
  exit 1
fi

RESULT=$(sqlite3 "$DIC_DB" "SELECT
  '音标: /' || COALESCE(phonetic, '') || '/' || char(10) ||
  '中文: ' || COALESCE(translation, '') || char(10) ||
  '英文: ' || COALESCE(definition, '') || char(10) ||
  '变形: ' || COALESCE(exchange, '')
FROM ecdict WHERE word='$TEXT' COLLATE NOCASE LIMIT 1;")

if [ -z "$RESULT" ]; then
  RESULT="Not found: $TEXT"
fi

echo -n "$ORIG" | wl-copy
notify-send "$TEXT" "$RESULT"
