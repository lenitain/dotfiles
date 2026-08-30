# y：yazi 退出后把 shell 切到它最后所在的目录。

y() {
    local tmp cwd
    tmp=$(mktemp -t yazi-cwd.XXXXXX) || return 1
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ]; then
        builtin cd -- "$cwd"
    fi
    command rm -f -- "$tmp"
}
