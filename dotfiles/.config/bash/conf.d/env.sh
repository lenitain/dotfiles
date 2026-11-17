# 环境变量与 PATH。
# GOPROXY / RUSTUP_* / 各语言镜像由 mise 的 [env] 注入，这里不重复。

export EDITOR=nvim
export VISUAL=nvim
export BROWSER=qutebrowser
export TERMINAL=foot
export MANPAGER='nvim - +Man!'
export ORT_DISABLE_TELEMETRY=1

# ─── Qt ───
# flatpak 的 XDG_DATA_DIRS 补丁由 /etc/profile.d/flatpak.sh 负责，systemd --user
# 侧也已就位，两处同值；这里不重复（重复写会因为守卫永远命中而死代码）。
export QT_QPA_PLATFORMTHEME=gtk3

# ─── PATH ───
# 只补手工加的三处；~/.cargo/bin 与 go install 的产物都由 mise 负责。
for _bash_path_dir in "$HOME/.local/bin" "$HOME/.local/bin/scripts" "$HOME/.moon/bin"; do
    [ -d "$_bash_path_dir" ] || continue
    case ":$PATH:" in
        *":$_bash_path_dir:"*) ;;
        *) PATH="$_bash_path_dir:$PATH" ;;
    esac
done
unset _bash_path_dir

# 按「保留第一次出现」给 PATH 去重；空元素（代表当前目录）直接丢掉。
# 存在的理由：mise env 前置 shims 和 ~/.cargo/bin 时不检查是否已存在，
# 而且它自己输出的 PATH 里 ~/.cargo/bin 就已经有两份相邻副本，于是每嵌套一层
# bash 就多一份。PATH 的自增点在这里和 conf.d/mise.sh 两处，两边各收一次尾。
__bash_path_dedupe() {
    local out='' dir
    local -A seen=()
    local IFS=':'
    for dir in $PATH; do
        [ -n "$dir" ] || continue
        [ -n "${seen[$dir]+x}" ] && continue
        seen[$dir]=1
        out="${out:+$out:}$dir"
    done
    PATH=$out
}

__bash_path_dedupe
export PATH
