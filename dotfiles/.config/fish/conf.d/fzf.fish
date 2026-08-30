# ─── fzf 统一配置 ───

# ─── Theme (本文件唯一的加载点; theme.fish 不再重复 source) ───
source $HOME/.config/fzf/everforest_dark_medium.sh

# ─── 绑定（追加到上面那次 theme 之后，避免被覆盖）───
# 逐条查重，重复 source 时不会叠加
for bind_spec in tab:replace-query btab:toggle+down
    string match -q -- "*--bind='$bind_spec'*" "$FZF_DEFAULT_OPTS"
    or set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS --bind='$bind_spec'"
end

# ─── 预览变量 ───
# 刻意不用 FZF_ 前缀：fzf 本体不读这两个变量，fzf.fish 内部自用。
set -g __fzf_preview_script "$HOME/.config/fish/scripts/fzf_preview.sh"
# wrap: 长路径（尤其符号链接那两行）超出窗口宽度时换行，否则被截断到屏幕外。
# 注意 wrap-sign 是独立选项，不能塞进 --preview-window 的逗号列表里。
set -g __fzf_preview_window right:38%,wrap
set -g __fzf_preview_wrap_sign '│ '

# ─── 预览参数生成 ───
function fzf_preview_opts -d '生成 fzf 预览参数；用法: fzf (fzf_preview_opts [dir])'
    # 注意: fish 4.x 的 if 块有独立作用域，set -l 不会带出块外，
    #       所以 target 先声明好，块内只赋值不用 set -l
    set -l target '{}'
    if test (count $argv) -gt 0
        set target "$argv[1]/{}"
    end
    # 逐行输出，由命令替换按换行切成独立参数（fish 不做二次解析）
    printf "%s\n" \
        --preview "$__fzf_preview_script $target" \
        --preview-window "$__fzf_preview_window" \
        --preview-wrap-sign "$__fzf_preview_wrap_sign"
end

# ─── 自定义函数 ───
function pfzf -d '带预览的裸 fzf（配合管道使用）'
    fzf (fzf_preview_opts)
end

function dfzf -d 'fuzzy 选择目录并跳转；取消返回 1'
    set -l target_dir (fd -t d -H | fzf (fzf_preview_opts))
    if test -z "$target_dir"
        echo "未选择目录，取消操作"
        return 1
    end
    cd "$target_dir"
    echo "已切换到目录："(pwd)
end

function nfzf -d 'fuzzy 选择目录，跳转后用 nvim 打开'
    dfzf
    or return 1
    nvim .
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
