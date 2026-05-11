#!/usr/bin/env bash
# chezmoi: run_once
# Description: Install Everforest Kvantum theme for root (Btrfs Assistant needs root)
set -euo pipefail

USER_HOME="{{ .chezmoi.homeDir }}"
KVANTUM_SRC="$USER_HOME/.local/share/Kvantum/Everforest-Dark-Medium"
KVANTUM_DEST="/usr/share/Kvantum/Everforest-Dark-Medium"
ROOT_KVANTUM_DIR="/root/.config/Kvantum"
ROOT_KVANTUM_CONF="$ROOT_KVANTUM_DIR/kvantum.kvconfig"

# Copy theme to system directory
if [ ! -d "$KVANTUM_DEST" ]; then
  echo "Installing Everforest Kvantum theme for system-wide access..."
  sudo mkdir -p "$KVANTUM_DEST"
  sudo cp "$KVANTUM_SRC"/* "$KVANTUM_DEST/"
fi

# Create root's Kvantum config
if [ ! -f "$ROOT_KVANTUM_CONF" ]; then
  echo "Creating root Kvantum config..."
  sudo mkdir -p "$ROOT_KVANTUM_DIR"
  echo '[General]
theme=Everforest-Dark-Medium' | sudo tee "$ROOT_KVANTUM_CONF" > /dev/null
fi

echo "Kvantum root setup complete."
