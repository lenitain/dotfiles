# dotfiles

Personal dotfiles managed by [chezmoi](https://chezmoi.io), targeting CachyOS with Sway (Wayland).

## Contents

| Category | Tools |
|----------|-------|
| Shell | Fish, fzf, tmux |
| Terminal | Alacritty |
| Editor | Neovim |
| File Manager | yazi |
| Status Bar | Waybar |
| Launcher | Wofi |
| Lock Screen | swaylock |
| IME | fcitx5 |
| Theme | Everforest Dark Medium |
| Font | Maple Mono NF CN |

## Usage

```bash
chezmoi init git@github.com:lenitain/dotfiles.git
chezmoi apply
```

## Structure

```
.chezmoiscripts/        # One-time setup scripts (package install, bat cache, etc.)
dot_config/             # ~/.config/*
dot_local/share/        # ~/.local/share/* (fonts, fcitx5 themes)
dot_gitconfig           # ~/.gitconfig
```
