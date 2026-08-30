# ─── Editor ───
set -gx EDITOR nvim
set -gx VISUAL nvim

# ─── Browser & Terminal ───
set -gx BROWSER qutebrowser
set -gx TERMINAL foot

# ─── Man Pages ───
set -x MANPAGER 'nvim - +Man!'

# ─── PATH ───
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.moon/bin
fish_add_path ~/.go/bin

# ─── XDG ───
set -gx QT_QPA_PLATFORMTHEME qt6ct
set -gx XDG_DATA_DIRS "/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:/usr/local/share:/usr/share"

# ─── Rust (USTC Mirror) ───
set -gx RUSTUP_DIST_SERVER https://mirrors.ustc.edu.cn/rust-static
set -gx RUSTUP_UPDATE_ROOT https://mirrors.ustc.edu.cn/rust-static/rustup

# ─── Go (goproxy.cn) ───
set -gx GOPROXY https://goproxy.cn,direct
