# keep <pkg>...：把包装成显式安装，避免被 cleanup 当孤儿删掉。

keep() {
    if [ $# -eq 0 ]; then
        printf 'usage: keep <package> [package...]\nexample: keep eza bat zoxide\n' >&2
        return 1
    fi
    sudo pacman -D --asexplicit "$@"
}
