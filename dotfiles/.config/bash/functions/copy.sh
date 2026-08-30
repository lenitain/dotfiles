# copy <src> <dst>：源是目录时自动补 -r，其余原样交给 cp。

copy() {
    if [ $# -eq 2 ] && [ -d "$1" ]; then
        local from=${1%/}
        cp -r -- "$from" "$2"
    else
        command cp -- "$@"
    fi
}
