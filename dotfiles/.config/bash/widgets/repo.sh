#!/usr/bin/env bash
# flyline 的 custom prompt widget：输出第一行的仓库段（jj 优先，否则 git）。
# 由 conf.d/flyline.sh 注册成 FLYLINE_REPO，每个提示符在子进程里跑一次；
# 超过 --block 的等待时间就显示空白（--placeholder 0），慢仓库不阻塞提示符。
# 契约：输出单行，没有内容就什么都不打印，退出码永远 0。
# 另外把这次输出的可见宽度写进缓存，供 ps1.sh 下一条提示符按实际宽度缩 cwd。

config=${BASH_CONFIG_HOME:-$HOME/.config/bash}

# shellcheck source=/dev/null
. "$config/prompt/repo.sh"

__bash_prompt_repo
output=''
width=0
if [ -n "${repo_ansi-}" ]; then
    output=" $repo_ansi"
    printf '%s' "$output"
    __bash_prompt_visible_length "$output"
    width=$REPLY
fi

# flyline 直接 spawn 本脚本，PPID 就是交互 shell；ps1.sh 用同样的路径读回去。
# 没有 XDG_RUNTIME_DIR 时不写：ps1.sh 会继续用上限。
if __bash_prompt_repo_width_file "$PPID"; then
    printf '%s\n' "$width" > "$REPLY" 2>/dev/null
fi

exit 0
