# dotfiles

chezmoi-managed dotfiles for CachyOS with Niri (Wayland).

## Quick Start

```bash
chezmoi init git@github.com:lenitain/dotfiles.git
chezmoi apply
```

## What's Included

| Component | Tools |
|-----------|-------|
| Shell | Fish + fzf + tmux |
| Terminal | Alacritty |
| Editor | Neovim (LazyVim) |
| Compositor | Niri |
| Launcher | Wofi |
| Status Bar | Waybar |
| File Manager | yazi |
| System Info | fastfetch, btop |
| Input Method | fcitx5 |
| Theme | GTK2/3/4 + Qt5/6 + everforest |

## Structure

```
.chezmoiscripts/           # One-time setup scripts
dot_config/                 # ~/.config/ (alacritty, niri, neovim, waybar, etc.)
dot_local/share/            # ~/.local/share/ (fonts, fcitx5 themes, stardict)
dot_gitconfig               # ~/.gitconfig
dot_gtkrc-2.0               # GTK2 settings
```

## Setup Scripts

- `run_once_after_install-packages.sh` - Package installation
- `run_once_setup-bat-cache.sh` - bat cache setup
- `run_once_create-user-dirs.sh` - XDG user directories
