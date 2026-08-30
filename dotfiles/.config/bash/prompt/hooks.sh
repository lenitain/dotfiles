# PROMPT_COMMAND 钩子：窗口标题、OSC 7 目录上报、历史落盘。
# 三个函数都只做一件事，由 conf.d/prompt.sh 注册。

__bash_prompt_title() {
    # stdout 不是终端时不发转义序列，避免污染重定向的输出。
    [ -t 1 ] || return 0
    local cwd=${PWD/#$HOME/\~}
    printf '\033]0;%s\007' "$cwd"
}

# 窗口标题只能有一个 owner：/etc/bash.bashrc 会往 PROMPT_COMMAND 里塞一条
# user@host:cwd 的 OSC 0 标题命令。它和我们的标题命令连着发，终端会先显示
# 系统标题再被覆盖，表现为标题闪一下，所以先把别人的 OSC 0 命令摘掉。
__bash_prompt_title_takeover() {
    local item
    local -a kept=()
    if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
        for item in "${PROMPT_COMMAND[@]}"; do
            [[ "$item" == *']0;'* ]] || kept+=("$item")
        done
        PROMPT_COMMAND=("${kept[@]}")
        return 0
    fi
    [ -n "${PROMPT_COMMAND:-}" ] || return 0
    # 字符串形式：元素以 ';' 分隔。
    local IFS=';'
    local -a items=()
    read -r -a items <<< "$PROMPT_COMMAND"
    for item in "${items[@]}"; do
        [[ "$item" == *']0;'* ]] || kept+=("$item")
    done
    PROMPT_COMMAND="${kept[*]}"
}

__bash_prompt_osc7() {
    # stdout 不是终端时不发转义序列，避免污染重定向的输出。
    [ -t 1 ] || return 0
    # SSH 会话里报的是远端路径：本机没有这个目录，终端拿它开新终端会 chdir 失败。
    [ -z "${SSH_CONNECTION-}" ] || return 0
    # URI 里 % 是转义前缀：路径里的字面 % 要写成 %25，空格等也要编码。
    local path=${PWD//\%/%25}
    path=${path// /%20}
    path=${path//\#/%23}
    path=${path//\?/%3F}
    printf '\033]7;file://localhost%s\007' "$path"
}

__bash_history_append() {
    history -a
}
