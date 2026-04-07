source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
    # Disable fastfetch greeting
end

fish_add_path ~/.bun/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.local/bin
fish_add_path ~/.moon/bin

# 定义 dfzf 函数：交互式查找目录并切换（带预览）
function dfzf
    # 1. 用 fd 找所有目录（含隐藏），fzf 交互式选择（带预览）
    set target_dir (fd -t d -H | fzf --preview "bash -c 'ls -la \"{}\"'" --preview-window right:41%)

    # 2. 检查是否选中了目录（避免按 Esc 退出时 cd 到空路径）
    if [ -n "$target_dir" ]
        cd "$target_dir"
        echo "已切换到目录：$target_dir"
    else
        echo "未选择目录，取消操作"
    end
end

function nfzf
    # 1. 用 fd 找所有目录（含隐藏），fzf 交互式选择（带预览）
    set target_dir (fd -t d -H | fzf --preview "bash -c 'ls -la \"{}\"'" --preview-window right:41%)

    # 2. 检查是否选中了目录（避免按 Esc 退出时 cd 到空路径）
    if [ -n "$target_dir" ]
        nvim "$target_dir"
        echo "nvim打开目录：$target_dir"
    else
        echo "未选择目录，取消操作"
    end
end

# 最终版 pfzf 函数（无任何 fish 语法冲突）
function pfzf
    fzf --preview "bash -c '~/.config/fish/scripts/fzf_preview.sh \"{}\"'" --preview-window=right:41%:wrap
end

# 别名：仅替换命令，无任何逻辑
alias nwt='alacritty --working-directory "$PWD" & disown'

# 创建开发环境：当前窗口 nvim + 右侧两个新窗口 (空白 + opencode)
function devbox
    set dir (pwd)
    setsid alacritty --working-directory "$dir" & disown
    sleep 0.2
    setsid alacritty --working-directory "$dir" -e opencode & disown
    sleep 0.2
    exec nvim .
end

# moonbit
fish_add_path "$HOME/.moon/bin"
