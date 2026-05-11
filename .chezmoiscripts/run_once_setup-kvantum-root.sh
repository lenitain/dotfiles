#!/usr/bin/env bash
# chezmoi: run_once
set -euo pipefail

SRC="${HOME:?}/.local/share/Kvantum/Everforest-Dark-Medium"
DST="/usr/share/Kvantum/Everforest-Dark-Medium"

if [ ! -d "$DST" ]; then
  sudo mkdir -p "$DST"
  sudo cp -r "$SRC"/. "$DST/"
fi

if [ ! -f /root/.config/Kvantum/kvantum.kvconfig ]; then
  sudo mkdir -p /root/.config/Kvantum
  printf '[General]\ntheme=Everforest-Dark-Medium\n' | sudo tee /root/.config/Kvantum/kvantum.kvconfig >/dev/null
fi
