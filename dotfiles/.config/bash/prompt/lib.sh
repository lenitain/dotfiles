# 提示符共用底座：终端调色板配色、ANSI 可见宽度、片段拼接。
# 由 ps1.sh 与 repo.sh 各自 source。

# pure 的颜色用终端调色板的 ANSI 名（blue/magenta/red/cyan/yellow/brblack），
# 不写死十六进制：终端的 Everforest 调色板一改，提示符跟着变。
__bash_prompt_color_blue=$'\e[34m'
__bash_prompt_color_magenta=$'\e[35m'
__bash_prompt_color_red=$'\e[31m'
__bash_prompt_color_cyan=$'\e[36m'
__bash_prompt_color_yellow=$'\e[33m'
__bash_prompt_color_white=$'\e[37m'
__bash_prompt_color_mute=$'\e[90m'
__bash_prompt_color_reset=$'\e[0m'

__bash_prompt_symbol='❯'
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
