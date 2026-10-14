# zmx 集成: 完成 + 提示符前缀 + zmx-select (fzf 会话面板)

if type -q zmx
    zmx completions fish | source
end

functions -c fish_prompt _original_fish_prompt 2>/dev/null

function fish_prompt --description 'Write out the prompt'
    if set -q ZMX_SESSION
        echo -n "[$ZMX_SESSION] "
    end
    _original_fish_prompt
end

function zmx-select --description 'Pick a zmx session (or create one) via fzf'
    if not command -q fzf; or not command -q zmx
        echo "zmx-select: zmx and fzf required" >&2
        return 1
    end

    set -l prefix
    if set -q ZMX_SESSION_PREFIX
        set prefix $ZMX_SESSION_PREFIX
    end

    # fish string split 的 SEP 后面那个 -- 会被当成 "另一个待拆字符串" 而不是参数分隔符,
    # 拆出来会多一个前导 '--'. 用一个真 tab 变量绕过.
    set -l tab (printf '\t')

    set -l display
    for line in (zmx list 2>/dev/null)
        set -l fields (string split $tab -- $line)
        if not string match -q '*=*' $fields[1]
            continue
        end
        # README bash 版用的是 start_dir=, 实际 0.8.x 输出是 cwd=
        set -l name (string replace -r '^.*?name=' '' $fields[1])
        set -l pid (string replace -r '^.*?pid=' '' $fields[2])
        set -l clients (string replace -r '^.*?clients=' '' $fields[3])
        set -l cwd (string replace -r '^.*?cwd=' '' $fields[-1])
        if test -n "$prefix"
            if not string match -q "$prefix*" $name
                continue
            end
            set name (string replace -- "$prefix" '' $name)
        end
        set -a display (printf '%-20s  pid:%-8s  clients:%-2s  %s\n' \
            $name $pid $clients $cwd)
    end

    set -l output (printf '%s\n' $display | fzf \
        --print-query \
        --expect=ctrl-n \
        --height=80% \
        --reverse \
        --prompt='zmx> ' \
        --header='Enter: select | Ctrl-N: create new' \
        --preview='zmx history {1}' \
        --preview-window='right:60%:follow' \
    )
    set -l rc $status

    # fzf --print-query + --expect=KEY 输出 1/2/3 行皆有可能, 缺位即空, 别 count 守卫.
    set -l query $output[1]
    set -l key $output[2]
    set -l selected $output[3]

    set -l session_name
    if test "$key" = ctrl-n; and test -n "$query"
        set session_name $query
    else if test $rc -eq 0; and test -n "$selected"
        set session_name (string replace -r '\s.*' '' $selected)
    else if test -n "$query"
        set session_name $query
    else
        return 130
    end

    zmx attach "$session_name"
end