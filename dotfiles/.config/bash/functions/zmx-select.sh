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

        # zmx list 的字段是 tab 分隔的 key=value，字段数随会话状态变：
        # 活着的会话到 cwd 为止，结束的会话后面还跟 ended / exit_code，
        # 所以按 key 取值，不能按位置取最后一个。
        local name='' pid='' clients='' cwd=''
        local field
        for field in "${fields[@]}"; do
            field=${field#"${field%%[![:space:]]*}"}   # 去掉行首空白（name= 前有两个空格）
            case $field in
                name=*) name=${field#name=} ;;
                pid=*) pid=${field#pid=} ;;
                clients=*) clients=${field#clients=} ;;
                cwd=*) cwd=${field#cwd=} ;;
            esac
        done
        [ -n "$name" ] || continue

        # cwd 是 URI（file://localhost/home/...），显示成路径
        cwd=${cwd#file://}
        cwd=${cwd#localhost}

        if [ -n "$prefix" ]; then
            case $name in
                "$prefix"*) name=${name#"$prefix"} ;;
                *) continue ;;
            esac
        fi
        display+=("$(printf '%-20s  pid:%-8s  clients:%-2s  %s' "$name" "$pid" "$clients" "$cwd")")
    done < <(zmx list 2>/dev/null)

    # 一个会话都没有时列表是空的，但选择器照样要开：Ctrl-N 用输入的词新建会话。
    # 所以这里不能提前退出，只是不往 fzf 里塞空行。
    local rows=''
    if [ ${#display[@]} -gt 0 ]; then
        rows=$(printf '%s\n' "${display[@]}")
    fi

    local output
    # 布局与配色来自 FZF_DEFAULT_OPTS（conf.d/fzf.sh）：输入栏在上、主题与
    # Ctrl+T / Alt+C 一致。这里只补 zmx 自己的参数，别再自带 --layout。
    output=$(printf '%s' "$rows" | fzf \
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
