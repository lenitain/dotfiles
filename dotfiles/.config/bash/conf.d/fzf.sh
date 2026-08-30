# fzf 配置：主题、布局、预览、flyline 键位入口。
# 预览只有一份定义 —— Ctrl+T（选文件）与 Alt+C（选目录）都走 scripts/fzf_preview.sh，
# 两边显示效果一致。

# shellcheck source=/dev/null
. "${BASH_CONFIG_HOME:-$HOME/.config/bash}/theme/everforest_dark_medium.sh"

# fzf 的基础选项 —— 所有 fzf 调用点的唯一来源（bash 侧）。
#
# 布局固定 reverse：输入栏在上、候选列表在下。调用点不要再自带 layout，
# 命令行优先级高于 FZF_DEFAULT_OPTS，两边不一致时以调用点为准，反而会跑偏。
# 主题的十六进制值取自 theme/everforest_dark_medium.sh，改色只改那一处。
#
# FZF_DEFAULT_OPTS 由 fzf 自己继承：从 shell 启动的每个 fzf 都拿到这一份设置
# （bash 集成的 Ctrl+T / Alt+C、functions/zmx-select.sh，以及 yazi、nvim 里
# 启动的 fzf），所以布局与配色天然统一。重复 source 只是重新算出同一个字符串。
__bash_fzf_opts() {
    printf '%s\n' \
        '--layout=reverse' \
        '--highlight-line' \
        '--info=inline-right' \
        '--ansi' \
        '--border=none' \
        "--color=bg+:#$EVERFOREST_BG_PLUS" \
        "--color=bg:#$EVERFOREST_BG" \
        "--color=border:#$EVERFOREST_COMMENT" \
        "--color=fg:#$EVERFOREST_FG" \
        "--color=fg+:#$EVERFOREST_FG:bold" \
        "--color=gutter:#$EVERFOREST_BG" \
        "--color=header:#$EVERFOREST_GREEN" \
        "--color=hl+:#$EVERFOREST_GREEN" \
        "--color=hl:#$EVERFOREST_GREEN" \
        "--color=info:#$EVERFOREST_COMMENT" \
        "--color=marker:#$EVERFOREST_RED" \
        "--color=pointer:#$EVERFOREST_RED" \
        "--color=prompt:#$EVERFOREST_YELLOW:regular" \
        "--color=query:#$EVERFOREST_FG:regular" \
        "--color=scrollbar:#$EVERFOREST_SCROLLBAR" \
        "--color=separator:#$EVERFOREST_SEPARATOR" \
        "--color=spinner:#$EVERFOREST_RED" \
        "--bind='tab:replace-query'" \
        "--bind='btab:toggle+down'"
}
export FZF_DEFAULT_OPTS="$(__bash_fzf_opts)"

# ─── 预览 ───
# 预览脚本：~/.config/bash/scripts/fzf_preview.sh
__bash_fzf_preview_script=${FZF_PREVIEW_SCRIPT:-${BASH_CONFIG_HOME:-$HOME/.config/bash}/scripts/fzf_preview.sh}
if [ -x "$__bash_fzf_preview_script" ]; then
    # fzf 自己解析 FZF_*_OPTS 里的引号，所以这里必须保留单引号。
    __bash_fzf_preview_opts="--preview '$__bash_fzf_preview_script {}' --preview-window 'right:38%,wrap' --preview-wrap-sign '│ '"
    # Ctrl+T 只列文件：fzf 集成自带的 --walker=file,dir,... 会被同串里靠后的同名字段覆盖。
    export FZF_CTRL_T_OPTS="$__bash_fzf_preview_opts --walker=file,follow,hidden"
    # Alt+C 只列目录（fzf 集成默认就是 --walker=dir,follow,hidden）。
    export FZF_ALT_C_OPTS="--walker=dir,follow,hidden $__bash_fzf_preview_opts"
    unset __bash_fzf_preview_opts
fi

# fzf 的 bash 集成：提供 __fzf_select__ / __fzf_cd__ / fzf-file-widget。
# 它内部的 bind -x 在 flyline 接管行编辑后必然失败，重载配置会刷「bind: 未启用行编辑」；
# 键位本身由本文件末尾的 flyline key bind 负责，所以只丢掉这段的 stderr。
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash)" 2>/dev/null
fi

# ─── flyline 键位入口 ───
# flyline 取代了 readline，fzf 集成里的 bind 不生效，必须用 runBashCommand 转接。
# runBashCommand 只看得见 shell 函数名，所以用 __flyline_widget_* 包一层。
__flyline_widget_fzf_file() {
    fzf-file-widget
}

__flyline_widget_fzf_cd() {
    local cmd
    cmd=$(__fzf_cd__) && READLINE_LINE="$cmd" READLINE_POINT=${#cmd}
}

if [ -n "${__bash_flyline_enabled-}" ] && declare -F fzf-file-widget >/dev/null && [ -z "${__bash_fzf_keys_bound-}" ]; then
    flyline key bind Ctrl+t 'always=runBashCommand(__flyline_widget_fzf_file)'
    flyline key bind Alt+c 'always=runBashCommand(__flyline_widget_fzf_cd)+submitOrNewline'
    __bash_fzf_keys_bound=1
fi
