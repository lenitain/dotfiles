# 提示符共用底座：终端调色板配色、ANSI 可见宽度、片段拼接。
# 由 ps1.sh 与 repo.sh 各自 source。

# pure 的颜色用终端调色板的 ANSI 名（blue/magenta/red/cyan/yellow/brblack），
# 不写死十六进制：终端的 Everforest 调色板一改，提示符跟着变。
__bash_prompt_color_blue=$'\e[34m'
__bash_prompt_color_magenta=$'\e[35m'
__bash_prompt_color_red=$'\e[31m'
__bash_prompt_color_cyan=$'\e[36m'
__bash_prompt_color_white=$'\e[37m'
__bash_prompt_color_mute=$'\e[90m'
__bash_prompt_color_reset=$'\e[0m'

__bash_prompt_symbol='❯'
# 符号行上的其它符号，取值同 pure 的默认值：
#   root 前缀 #（pure_symbol_prefix_root_prompt）
#   nix develop 前缀 ❄（不带 VS16：终端按 1 列画，flyline 的宽度也算 1 列）
#   退出码前缀 |（pure_symbol_exit_status_prefix，分隔符同值）
__bash_prompt_symbol_root='#'
__bash_prompt_symbol_nixdevshell='❄'
__bash_prompt_symbol_exit_status='|'
# repo 段的符号：dirty 由 git 与 jj 共用（两边各写一遍就是两份事实，见 README 的「验证」）；
# ≡ ⇡ ⇣ 只有 git 段用。
__bash_prompt_symbol_dirty='*'
__bash_prompt_symbol_stash='≡'
__bash_prompt_symbol_ahead='⇡'
__bash_prompt_symbol_behind='⇣'
# ANSI SGR 的 ERE。必须存成变量：[[ =~ ]] 里直接写带引号的模式会被当字面量。
__bash_prompt_ansi_pattern=$'\e''\[[0-9;]*m'

__bash_prompt_join_into() {
    local separator=${1-}
    [ $# -gt 0 ] && shift
    local joined='' part
    for part in "$@"; do
        [ -n "$part" ] || continue
        joined+="${joined:+$separator}$part"
    done
    REPLY=$joined
}

__bash_prompt_visible_length() {
    local text=${1-}
    text=${text//\\[}
    text=${text//\\]}
    while [[ $text =~ $__bash_prompt_ansi_pattern ]]; do
        text=${text/"${BASH_REMATCH[0]}"/}
    done
    REPLY=${#text}
}

# 仓库段的宽度：仓库里先用这个上限，之后用 widget 写回的实际宽度（见下）。
# 上限是 jj/git 段的观测最大值（含前导空格，见 prompt/ps1.sh）。
__bash_prompt_repo_reserved=40

# widget 的输出宽度 bash 看不到，只能由子进程写、父 shell 下一条提示符读；
# 路径按 shell PID 分。只放 XDG_RUNTIME_DIR（per-user 0700，登出即清）：
# 没有它就返回 1，调用方继续用上限，不去 /tmp 里按 PID 猜文件名。
__bash_prompt_repo_width_file() {
    [ -n "${XDG_RUNTIME_DIR-}" ] || return 1
    REPLY=$XDG_RUNTIME_DIR/bash-prompt-repo-width.$1
}

# 读回缓存的宽度写进 REPLY；没有文件或内容不是数字时返回 1。
__bash_prompt_repo_width_read() {
    __bash_prompt_repo_width_file "$1" || return 1
    local file=$REPLY width
    [ -r "$file" ] || return 1
    read -r width < "$file" || return 1
    case $width in
        ''|*[!0-9]*) return 1 ;;
    esac
    REPLY=$width
}
