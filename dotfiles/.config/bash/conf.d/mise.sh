# 启动时注入全局工具 PATH 和 [env] 变量（就是 `mise env` 的输出）。
#
# `mise env` 本机约 60ms，每开一个 shell 都付。它的结果由三样东西决定：全局配置、
# mise 二进制、启动时的 PATH（mise 会把工具目录合并进现有 PATH）。缓存把这三样
# 的指纹一起记下，都没变就直接 source 上次的结果，变了才重算。
#
# 不用 `mise activate`：它挂 PROMPT_COMMAND + chpwd 钩子，每次 cd、每个提示符
# 都重算（本机约 40ms）。代价：cd 不再自动换工具版本，手动敲 `mr` 刷新
# （它顺便作废缓存，下一个 shell 重新算一次）。
#
# 缓存只在"目录链上没有项目配置"时用：项目配置按 cwd 注入 env，不能共用全局结果。
# 标记不导出：同一 shell 只注入一次，新 shell 各自注入。

__bash_mise_cache_path() {
    printf '%s/mise/env.sh' "${XDG_CACHE_HOME:-$HOME/.cache}"
}

# mise 会从 cwd 往上找这些文件名；找到任何一个就说明 env 结果和目录有关。
# $HOME/.config/mise/config.toml 是全局配置本身，走到 $HOME 就停，别当成项目配置。
__bash_mise_has_project_config() {
    local dir=$PWD file
    while :; do
        if [ "$dir" != "$HOME" ]; then
            for file in mise.toml .mise.toml mise.local.toml .config/mise.toml .config/mise/config.toml; do
                [ -e "$dir/$file" ] && return 0
            done
        fi
        [ "$dir" = "$HOME" ] && return 1
        dir=${dir%/*}
        [ -n "$dir" ] || return 1
    done
}

# 缓存比所有输入都新才可用。全部是 bash 内建判断，不 fork。
__bash_mise_cache_fresh() {
    local cache=$1 file mise line
    [ -s "$cache" ] || return 1
    [ -z "${MISE_CONFIG_FILE-}" ] || return 1
    __bash_mise_has_project_config && return 1

    # 第一行是生成时的基准 PATH：PATH 不同，合并结果就不同。
    IFS= read -r line <"$cache" || return 1
    case $line in
    '# base PATH: ') return 1 ;;
    '# base PATH: '*) [ "${line#'# base PATH: '}" = "$PATH" ] || return 1 ;;
    *) return 1 ;;
    esac

    mise=$(command -v mise) || return 1
    for file in "$HOME/.config/mise/config.toml" "$HOME"/.config/mise/conf.d/*.toml \
        "$HOME"/.local/share/mise/installs/* "$mise"; do
        [ -e "$file" ] || continue
        [ "$file" -nt "$cache" ] && return 1
    done
    return 0
}

__bash_mise_cache_write() { # cache, 基准 PATH, 内容
    [ -n "$3" ] || return 0
    mkdir -p "${1%/*}" 2>/dev/null || return 0
    # 临时文件带 pid：同时开多个 shell 时各写各的，不会拼出半截缓存。
    if printf '# base PATH: %s\n%s\n' "$2" "$3" >|"$1.$$.tmp" 2>/dev/null; then
        mv -f "$1.$$.tmp" "$1" 2>/dev/null || rm -f "$1.$$.tmp" 2>/dev/null
    fi
    return 0
}

if [ -z "${__bash_mise_activated-}" ] && command -v mise >/dev/null 2>&1; then
    __bash_mise_cache=$(__bash_mise_cache_path)
    if __bash_mise_cache_fresh "$__bash_mise_cache"; then
        . "$__bash_mise_cache"
    else
        # 先记下基准 PATH：eval 之后 PATH 已经被 mise 改过，不能拿它当指纹。
        __bash_mise_base=$PATH
        if __bash_mise_env=$(mise env -s bash) && [ -n "$__bash_mise_env" ]; then
            eval "$__bash_mise_env"
            # 项目目录里的结果带着项目 env，只给这一个 shell 用，不能写进全局缓存。
            if [ -z "${MISE_CONFIG_FILE-}" ] && ! __bash_mise_has_project_config; then
                __bash_mise_cache_write "$__bash_mise_cache" "$__bash_mise_base" "$__bash_mise_env"
            fi
        else
            # 没拿到东西（启动失败 / 被锁）：照原样 eval，并删掉旧缓存，
            # 否则下次 shell 会把一份空结果当成新鲜缓存。
            eval "${__bash_mise_env-}"
            rm -f "$__bash_mise_cache"
        fi
        unset __bash_mise_base
    fi
    unset __bash_mise_env __bash_mise_cache
    __bash_mise_activated=1
    # mise env 在干净 shell 里不带 shims，自己补上（给 IDE、niri spawn 等
    # 不读 bashrc 的程序用）。放末尾：优先跑直接安装的工具，shims 只兜底。
    case ":$PATH:" in
        *":$HOME/.local/share/mise/shims:"*) ;;
        *) PATH="$PATH:$HOME/.local/share/mise/shims" ;;
    esac
    # 去重，免得每嵌套一层 shell PATH 就长一截。函数由 conf.d/env.sh 定义。
    __bash_path_dedupe
fi

# 手动刷新（别名 mr）：按当前目录重算环境，再补 shims、去重 PATH。
# 缓存作废即可：新开的 shell 会用新的 PATH/配置重算，不必在这里猜基准 PATH。
__bash_mise_refresh() {
    eval "$(mise hook-env -s bash)"
    rm -f "$(__bash_mise_cache_path)"
    case ":$PATH:" in
        *":$HOME/.local/share/mise/shims:"*) ;;
        *) PATH="$PATH:$HOME/.local/share/mise/shims" ;;
    esac
    __bash_path_dedupe
}
