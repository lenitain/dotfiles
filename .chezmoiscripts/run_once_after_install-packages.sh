#!/bin/bash
set -euo pipefail

if command -v pacman &>/dev/null; then
  sudo pacman -S --needed --noconfirm neovim yazi satty grim slurp
elif command -v apt &>/dev/null; then
  sudo apt install -y neovim
elif command -v dnf &>/dev/null; then
  sudo dnf install -y neovim
fi
