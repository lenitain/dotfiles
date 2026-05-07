# fzf 配置
# Tab 补全路径（replace-query：选中项替换到输入框，逐级导航）
# Shift+Tab 多选切换（恢复 toggle+down 默认行为）

set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS --bind='tab:replace-query' --bind='btab:toggle+down'"

# fzf shell 集成（Ctrl+T 搜文件、Ctrl+R 搜历史、Alt+C cd 进目录）
if command -q fzf
    fzf --fish | source
end
