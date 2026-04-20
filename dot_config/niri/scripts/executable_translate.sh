#!/bin/bash

DIC_DB="$HOME/.local/share/stardict/ecdict.db"

TEXT=$(wl-paste --primary | xargs)
if [ -z "$TEXT" ]; then
  notify-send "Translate" "No text selected"
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

notify-send "$TEXT" "$RESULT"
echo -n "$RESULT" | wl-copy
