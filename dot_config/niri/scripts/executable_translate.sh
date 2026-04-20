#!/bin/bash

DIC_DB="$HOME/.local/share/stardict/ecdict.db"

TEXT=$(wl-paste --primary)
if [ -z "$TEXT" ]; then
  notify-send "Translate" "No text selected"
  exit 1
fi

TEXT_LOWER=$(echo "$TEXT" | tr '[:upper:]' '[:lower:]')

RESULT=$(sqlite3 "$DIC_DB" "SELECT definition FROM ecdict WHERE word='$TEXT_LOWER' COLLATE NOCASE LIMIT 1;")
if [ -z "$RESULT" ]; then
  RESULT="Not found: $TEXT"
fi

echo -e "原文: $TEXT\n\n翻译: $RESULT" | ~/.config/wofi/wofi-wrapper -d --prompt "翻译"
