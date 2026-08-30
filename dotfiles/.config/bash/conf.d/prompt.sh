# pure 式提示符的接线。函数在 prompt/，这里只注册 PROMPT_COMMAND。
# 关掉 venv 自带的提示符前缀：venv/conda 名由 prompt/ps1.sh 画（pure 式，符号行上）。
export VIRTUAL_ENV_DISABLE_PROMPT=1

__bash_prompt_command_prepend() {
    if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
        PROMPT_COMMAND=("$1" "${PROMPT_COMMAND[@]}")
    else
        PROMPT_COMMAND="$1${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    fi
}

__bash_prompt_command_append() {
    if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
        PROMPT_COMMAND+=("$1")
    else
        PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}$1"
    fi
}

__bash_prompt_command_remove() {
    local target=$1 item
    local -a kept=()
    if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
        for item in "${PROMPT_COMMAND[@]}"; do
            [ "$item" = "$target" ] || kept+=("$item")
        done
        PROMPT_COMMAND=("${kept[@]}")
    fi
}

# 提示符是第一个元素：先重建 PS1，再让别的 hook 跑。
# 重新 source 时 mise 会把自己再插到最前，所以这里把已有的 __bash_prompt 挪回第一位，
# 而不是再插一份。
case " ${PROMPT_COMMAND[*]:-} " in
    *" __bash_prompt "*)
        if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]] && [ "${PROMPT_COMMAND[0]-}" != "__bash_prompt" ]; then
            __bash_prompt_command_remove __bash_prompt
            __bash_prompt_command_prepend __bash_prompt
        fi
        ;;
    *)
        __bash_prompt_command_prepend __bash_prompt
        ;;
esac

# 窗口标题空闲时显示当前目录，命令开始执行时由 PS0 加上程序名。先摘掉系统
# （/etc/bash.bashrc）加的 OSC 0 标题命令，两条 OSC 0 连发会让终端标题闪一下；
# 标题只留 __bash_prompt_title / __bash_prompt_title_running 一个 owner。
__bash_prompt_title_takeover
case " ${PROMPT_COMMAND[*]:-} " in
    *" __bash_prompt_title "*) ;;
    *) __bash_prompt_command_append __bash_prompt_title ;;
esac

# PS0 在命令开始执行前展开：从历史里取刚读入的命令行，把程序名追加到标题。
# 重新 source 时不重复追加。
case ${PS0-} in
    *'$(__bash_prompt_title_running)'*) ;;
    *) PS0="${PS0-}"'$(__bash_prompt_title_running)' ;;
esac

# OSC 7 上报当前目录：foot 的 Ctrl+Shift+N 用它决定新终端从哪起步。
# flyline 的 OSC 7 只在 shell 启动时发一次，cd 之后不更新，所以每条提示符都补发。
case " ${PROMPT_COMMAND[*]:-} " in
    *" __bash_prompt_osc7 "*) ;;
    *) __bash_prompt_command_append __bash_prompt_osc7 ;;
esac

# 历史在提示符之后立即落盘：新会话（或 history -r）能看到本次会话敲过的命令。
# 命令耗时不由 bash 统计：flyline 的内建 widget 自己记时间，不需要 DEBUG trap。
case " ${PROMPT_COMMAND[*]:-} " in
    *" __bash_history_append "*) ;;
    *) __bash_prompt_command_append __bash_history_append ;;
esac
