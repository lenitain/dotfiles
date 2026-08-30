# 提示符 widget：PS1 里的 FLYLINE_REPO 占位符由 flyline 换成 widgets/repo.sh 的输出。
# --block 100 是等待上限，超时就先显示 --placeholder 的空白（0 个空格：列宽已由
# ps1.sh 预算），慢仓库（jj log / git status）不阻塞提示符。这里不能用 prev：
# 切到慢仓库时它会先把上一个仓库的分支和 ⇡⇣ 画出来，而那是错的。
# 占位符只在 flyline 加载成功时才会写进 PS1（见 prompt/ps1.sh）。

flyline create-prompt-widget custom --name FLYLINE_REPO \
    --command "${BASH_CONFIG_HOME:-$HOME/.config/bash}/widgets/repo.sh" \
    --block 100 --placeholder 0

# 命令耗时默认不显示。要开就取消下面一行，并把 FLYLINE_DURATION 加回 PS1
# （prompt/ps1.sh，同时为它预留 8 列宽度）。
# flyline create-prompt-widget last-command-duration --name FLYLINE_DURATION
