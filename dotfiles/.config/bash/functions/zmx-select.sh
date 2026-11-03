# zmx-select：fzf 选 zmx 会话，Ctrl-N 新建（也是 flyline 的 Alt+n 入口）。

zmx-select() {
    if ! command -v fzf >/dev/null 2>&1 || ! command -v zmx >/dev/null 2>&1; then
        printf 'zmx-select: zmx and fzf required\n' >&2
        return 1
    fi

    local prefix=${ZMX_SESSION_PREFIX-}
    local -a display=()
    local line
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        local -a fields=()
        IFS=$'\t' read -r -a fields <<< "$line"
        case ${fields[0]-} in
            *=*) ;;
            *) continue ;;
        esac
        local name=${fields[0]#*name=}
        local pid=${fields[1]-}; pid=${pid#*pid=}
        local clients=${fields[2]-}; clients=${clients#*clients=}
        local cwd=${fields[${#fields[@]}-1]-}; cwd=${cwd#*cwd=}
        if [ -n "$prefix" ]; then
            case $name in
                "$prefix"*) name=${name#"$prefix"} ;;
                *) continue ;;
            esac
        fi
        display+=("$(printf '%-20s  pid:%-8s  clients:%-2s  %s' "$name" "$pid" "$clients" "$cwd")")
    done < <(zmx list 2>/dev/null)

    local output
    # 布局与配色来自 FZF_DEFAULT_OPTS（conf.d/fzf.sh）：输入栏在上、主题与
    # Ctrl+T / Alt+C 一致。这里只补 zmx 自己的参数，别再自带 --layout。
    output=$(printf '%s\n' "${display[@]}" | fzf \
        --print-query \
        --expect=ctrl-n \
        --height=80% \
        --prompt='zmx> ' \
        --header='Enter: select | Ctrl-N: create new' \
        --preview='zmx history {1}' \
        --preview-window='right:60%:follow')
    local rc=$?

    local -a out=()
    mapfile -t out <<< "$output"
    local query=${out[0]-}
    local key=${out[1]-}
    local selected=${out[2]-}

    local session=''
    if [ "$key" = ctrl-n ] && [ -n "$query" ]; then
        session=$query
    elif [ "$rc" -eq 0 ] && [ -n "$selected" ]; then
        session=${selected%%[[:space:]]*}
    elif [ -n "$query" ]; then
        session=$query
    else
        return 130
    fi

    zmx attach "$session"
}

__flyline_widget_zmx_select() {
    zmx-select
}
