# fzf 配置：主题、预览、flyline 键位入口。
# 预览只有一份定义 —— Ctrl+T（选文件）与 Alt+C（选目录）都走 scripts/fzf_preview.sh，
# 两边显示效果一致。

# shellcheck source=/dev/null
. "${BASH_CONFIG_HOME:-$HOME/.config/bash}/theme/everforest_dark_medium.sh"

export FZF_DEFAULT_OPTS="\
  --highlight-line \
  --info=inline-right \
  --ansi \
  --layout=default \
  --border=none \
  --color=bg+:#$EVERFOREST_BG_PLUS \
  --color=bg:#$EVERFOREST_BG \
  --color=border:#$EVERFOREST_COMMENT \
  --color=fg:#$EVERFOREST_FG \
  --color=fg+:#$EVERFOREST_FG:bold \
  --color=gutter:#$EVERFOREST_BG \
  --color=header:#$EVERFOREST_GREEN \
  --color=hl+:#$EVERFOREST_GREEN \
  --color=hl:#$EVERFOREST_GREEN \
  --color=info:#$EVERFOREST_COMMENT \
  --color=marker:#$EVERFOREST_RED \
  --color=pointer:#$EVERFOREST_RED \
  --color=prompt:#$EVERFOREST_YELLOW:regular \
  --color=query:#$EVERFOREST_FG:regular \
  --color=scrollbar:#$EVERFOREST_SCROLLBAR \
  --color=separator:#$EVERFOREST_SEPARATOR \
  --color=spinner:#$EVERFOREST_RED \
"

# 逐条查重，重复 source 时不叠加
for _bash_fzf_bind in tab:replace-query btab:toggle+down; do
    case " ${FZF_DEFAULT_OPTS-} " in
        *"--bind='$_bash_fzf_bind'"*) ;;
        *) FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} --bind='$_bash_fzf_bind'" ;;
    esac
done
unset _bash_fzf_bind
export FZF_DEFAULT_OPTS

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
