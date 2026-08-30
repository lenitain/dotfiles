#!/usr/bin/env bash
# flyline 的 custom prompt widget：输出第一行的仓库段（jj 优先，否则 git）。
# 由 conf.d/flyline.sh 注册成 FLYLINE_REPO，每个提示符在子进程里跑一次；
# 超过 --block 的等待时间就沿用上一次输出，慢仓库不阻塞提示符。
# 契约：输出单行，没有内容就什么都不打印，退出码永远 0。

config=${BASH_CONFIG_HOME:-$HOME/.config/bash}

# shellcheck source=/dev/null
. "$config/prompt/repo.sh"

__bash_prompt_repo
if [ -n "${repo_ansi-}" ]; then
    printf ' %s' "$repo_ansi"
fi

exit 0
