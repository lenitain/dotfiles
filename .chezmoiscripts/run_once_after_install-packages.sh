#!/usr/bin/env bash
set -euo pipefail

sudo pacman -Syu --needed --noconfirm \
  neovim \
  yazi \
  satty grim slurp \
  swayidle \
  fcitx5 fcitx5-chinese-addons fcitx5-configtool \
  lazygit cliphist \
  htop strace gdb \
  aria2 imv mpv \
  hurl zip \
  kdenlive evemu \
  tesseract tesseract-data-eng \
  bpftrace zathura
