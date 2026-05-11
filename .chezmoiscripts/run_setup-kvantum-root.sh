#!/usr/bin/env bash
# chezmoi: run
# Description: Ensure Everforest Kvantum theme is accessible by root (Btrfs Assistant)
set -euo pipefail

KVANTUM_SRC="$HOME/.local/share/Kvantum/Everforest-Dark-Medium"
KVANTUM_DEST="/usr/share/Kvantum/Everforest-Dark-Medium"
ROOT_KVANTUM_DIR="/root/.config/Kvantum"
ROOT_KVANTUM_CONF="$ROOT_KVANTUM_DIR/kvantum.kvconfig"

# Copy theme to system directory (if not already there)
if [ ! -d "$KVANTUM_DEST" ]; then
  echo "Installing Everforest Kvantum theme for system-wide access..."
  sudo mkdir -p "$KVANTUM_DEST"
  sudo cp -r "$KVANTUM_SRC"/* "$KVANTUM_DEST/"
fi

# Create root's Kvantum config (if not already there)
if [ ! -f "$ROOT_KVANTUM_CONF" ]; then
  echo "Creating root Kvantum config..."
  sudo mkdir -p "$ROOT_KVANTUM_DIR"
  echo '[General]
theme=Everforest-Dark-Medium' | sudo tee "$ROOT_KVANTUM_CONF" > /dev/null
fi
