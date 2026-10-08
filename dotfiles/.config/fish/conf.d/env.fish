set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER qutebrowser
set -gx TERMINAL foot
set -gx MANPAGER 'nvim - +Man!'

# ─── PATH ───
fish_add_path ~/.local/bin
fish_add_path ~/.local/bin/scripts
fish_add_path ~/.moon/bin
fish_add_path ~/go/bin
# 不要再加 ~/.cargo/bin (旧 CARGO_HOME): rust/cargo 的 PATH 由 mise [env] 注入
# (conf.d/mirrors.toml), 旧位置已废弃待删。

# ─── XDG ───
set -gx QT_QPA_PLATFORMTHEME gtk3
set -gx XDG_DATA_DIRS "/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:/usr/local/share:/usr/share"

# GOPROXY / RUSTUP_* / PIP_INDEX_URL / UV_DEFAULT_INDEX / NODEJS_ORG_MIRROR /
# NPM_CONFIG_REGISTRY 全部由 mise 的 [env] 注入, 见 mise 配置的 conf.d/mirrors.toml。
# 这里不要再抄一遍 —— 那里是镜像的唯一来源。
# 例外: RUSTUP_HOME/CARGO_HOME 另有一处 environment.d/50-rustup-cargo.conf,
# 兜不经 mise 的 systemd/图形会话。换路径时两处同改 (勿再加进 .profile / niri)。
