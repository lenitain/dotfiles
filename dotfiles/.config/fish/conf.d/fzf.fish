# ─── fzf 统一配置 ───

# ─── Theme ───
source $HOME/.config/fzf/everforest_dark_medium.sh

# ─── 绑定（追加到主题之后，避免被覆盖）───
set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS --bind='tab:replace-query' --bind='btab:toggle+down'"

# ─── 预览变量 ───
set -gx FZF_PREVIEW_SCRIPT "$HOME/.config/fish/scripts/fzf_preview.sh"
set -gx FZF_PREVIEW_WINDOW right:38%

# ─── 预览参数生成 ───
function fzf_preview_opts
    # 用法: fzf_preview_opts [dir]
    # 返回: --preview "script {}" --preview-window right:38%
    if test (count $argv) -gt 0
        set -l prefix "$argv[1]/"
        printf "%s\n" "--preview" "$FZF_PREVIEW_SCRIPT $prefix{}" "--preview-window" "$FZF_PREVIEW_WINDOW"
    else
        printf "%s\n" "--preview" "$FZF_PREVIEW_SCRIPT {}" "--preview-window" "$FZF_PREVIEW_WINDOW"
    end
end

# ─── 自定义函数 ───
function pfzf
    fzf (fzf_preview_opts)
end

function dfzf
    set target_dir (fd -t d -H | fzf (fzf_preview_opts))
    if [ -n "$target_dir" ]
        cd "$target_dir"
        echo "已切换到目录："(pwd)
    else
        echo "未选择目录，取消操作"
    end
end

function nfzf
    set target_dir (fd -t d -H | fzf (fzf_preview_opts))
    if [ -n "$target_dir" ]
        cd "$target_dir"
        nvim .
        echo "nvim打开目录："(pwd)
    else
        echo "未选择目录，取消操作"
    end
end

# ─── Keybindings（Ctrl+T / Alt+C 带预览）───
if command -q fzf
    fzf --fish | source

    function fzf-file-widget
        set -l commandline (__fzf_parse_commandline)
        set -lx dir $commandline[1]
        set -l fzf_query $commandline[2]
        set -l prefix $commandline[3]
        set -lx FZF_DEFAULT_OPTS (__fzf_defaults \
            "--reverse --walker=file,dir,follow,hidden --scheme=path" \
            "--multi --print0")
        set -lx FZF_DEFAULT_COMMAND "$FZF_CTRL_T_COMMAND"
        set -lx FZF_DEFAULT_OPTS_FILE
        set -l fzf_cmd (__fzfcmd)
        set -l result ($fzf_cmd --walker-root=$dir --query=$fzf_query (fzf_preview_opts $dir) | string split0)
        and commandline -rt -- (string join -- ' ' $prefix(string escape -n -- $result))' '
        commandline -f repaint
    end

    function fzf-cd-widget
        set -l commandline (__fzf_parse_commandline)
        set -lx dir $commandline[1]
        set -l fzf_query $commandline[2]
        set -l prefix $commandline[3]
        set -lx FZF_DEFAULT_OPTS (__fzf_defaults \
            "--reverse --walker=dir,follow,hidden --scheme=path" \
            "$FZF_ALT_C_OPTS --no-multi --print0")
        set -lx FZF_DEFAULT_OPTS_FILE
        set -lx FZF_DEFAULT_COMMAND "$FZF_ALT_C_COMMAND"
        set -l fzf_cmd (__fzfcmd)
        if set -l result ($fzf_cmd --query=$fzf_query --walker-root=$dir (fzf_preview_opts $dir) | string split0)
            cd -- $result
            commandline -rt -- $prefix
        end
        commandline -f repaint
    end
end
