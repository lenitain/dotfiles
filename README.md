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

## Structure

```
.chezmoiscripts/        # One-time setup scripts
dot_config/             # ~/.config/
dot_local/share/        # ~/.local/share/ (fonts, themes)
```

## Setup Scripts

- `run_once_after_install-packages.sh` - Package installation
- `run_once_setup-bat-cache.sh` - bat cache setup
- `run_once_create-user-dirs.sh` - XDG user directories
