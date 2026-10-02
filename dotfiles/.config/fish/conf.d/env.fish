set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER qutebrowser
set -gx TERMINAL foot
set -gx MANPAGER 'nvim - +Man!'

# ─── PATH ───
fish_add_path ~/.local/bin
fish_add_path ~/.local/bin/scripts
fish_add_path ~/.cargo/bin
fish_add_path ~/.moon/bin
fish_add_path ~/go/bin

# ─── XDG ───
set -gx QT_QPA_PLATFORMTHEME gtk3
set -gx XDG_DATA_DIRS "/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:/usr/local/share:/usr/share"

# GOPROXY / RUSTUP_* / PIP_INDEX_URL / UV_DEFAULT_INDEX / NODEJS_ORG_MIRROR /
# NPM_CONFIG_REGISTRY 全部由 mise 的 [env] 注入, 见 mise 配置的 conf.d/mirrors.toml。
# 这里不要再抄一遍 —— 那里是镜像的唯一来源。
