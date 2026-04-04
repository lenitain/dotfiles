#!/bin/bash
set -euo pipefail

if command -v pacman &>/dev/null; then
  sudo pacman -S --needed --noconfirm neovim yazi satty grim slurp swayidle fcitx5 fcitx5-chinese-addons fcitx5-configtool lazygit cliphist htop strace docker
elif command -v apt &>/dev/null; then
  sudo apt install -y neovim
elif command -v dnf &>/dev/null; then
  sudo dnf install -y neovim
fi
