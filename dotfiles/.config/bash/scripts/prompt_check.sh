#!/usr/bin/env bash
# 提示符全局自检：动态文本进 PS1 的转义、~ 边界、标题控制字符。
# 改 prompt/lib.sh、ps1.sh、hooks.sh 的转义/路径逻辑后跑一遍（见 README 的「验证」）；
# 退出码 0 才算过。这里可以随便 fork：手动脚本，不在热路径上。

config=${BASH_CONFIG_HOME:-$HOME/.config/bash}

# shellcheck source=/dev/null
. "$config/prompt/ps1.sh"
# shellcheck source=/dev/null
. "$config/prompt/hooks.sh"

fail=0
report() { printf 'prompt_check: %s\n' "$1" >&2; fail=1; }
strip_ansi() { sed $'s/\x1b\\[[0-9;]*m//g; s/\\\\\\[//g; s/\\\\\\]//g'; }

# 1. ~ 只替换完整的 $HOME 路径段。
(
    HOME=/home/promptcheck
    PWD=/home/promptcheck
    __bash_prompt_home_path
    [ "$REPLY" = '~' ] || report "HOME 本身期望 ~，实际 [$REPLY]"
    PWD=/home/promptcheck2
    __bash_prompt_home_path
    [ "$REPLY" = '/home/promptcheck2' ] || report "同前缀目录期望原样，实际 [$REPLY]"
    PWD=/home/promptcheck/sub
    __bash_prompt_home_path
    [ "$REPLY" = '~/sub' ] || report "子目录期望 ~/sub，实际 [$REPLY]"
)

# 2. 动态文本转义：命令替换、反引号、prompt 转义都只显示字面。
check_escape() {  # 原值 期望的可见文本
    local value=$1 expected=$2 out
    __bash_prompt_escape "$value"
    PS1=$REPLY
    shopt -s promptvars
    out=$(printf '%s' "${PS1@P}" | strip_ansi)
    [ "$out" = "$expected" ] || report "转义 [$value] 期望 [$expected] 实际 [$out]"
}
check_escape '/tmp/$(echo PWNED)' '/tmp/$(echo PWNED)'
check_escape '/tmp/`echo PWNED`' '/tmp/`echo PWNED`'
check_escape '/tmp/\u\w' '/tmp/\u\w'
check_escape $'/tmp/esc\x1b]0;x\x07bel' '/tmp/esc]0;xbel'

# 3. 完整 PS1：恶意 cwd 不能执行命令，且字面路径保留。
check_dir=$(mktemp -d) || { printf 'prompt_check: mktemp 失败\n' >&2; exit 1; }
trap 'rm -rf "$check_dir"' EXIT
sentinel=$check_dir/pwned
evil="$check_dir/"'$(touch '"$sentinel"')'
mkdir -p "$evil" || exit 1
(
    cd "$evil" || exit 1
    unset SSH_CONNECTION ZMX_SESSION __bash_flyline_repo_widget
    COLUMNS=200
    __bash_prompt
    expanded=${PS1@P}
    [ ! -e "$sentinel" ] || report "PS1 执行了 cwd 里的命令"
    visible=$(printf '%s' "$expanded" | strip_ansi)
    case $visible in
        *'$(touch '* ) ;;
        *) report "PS1 没有保留字面 cwd，实际 [$visible]" ;;
    esac
)

# 4. 标题/OSC 7 的控制字符。
__bash_prompt_strip_control $'a\e]0;b\ac'
[ "$REPLY" = 'a]0;bc' ] || report "strip_control 期望 [a]0;bc]，实际 [$REPLY]"

[ "$fail" = 0 ] && printf 'prompt_check: ok\n'
exit "$fail"
