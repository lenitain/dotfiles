# rip：最近安装的 200 个包，按安装时间排序。

rip() {
    awk '
        /^%NAME%$/ {
            if (name != "" && inst != "") print inst "\t" name " " ver
            getline; name = $0; next
        }
        /^%VERSION%$/     { getline; ver = $0; next }
        /^%INSTALLDATE%$/ { getline; inst = $0; next }
        END { if (name != "" && inst != "") print inst "\t" name " " ver }
    ' /var/lib/pacman/local/*/desc | sort -n | tail -200 | while IFS=$'\t' read -r stamp package; do
        printf '%s\t%s\n' "$(date -d "@$stamp" '+%Y-%m-%d %H:%M:%S')" "$package"
    done | nl
}
