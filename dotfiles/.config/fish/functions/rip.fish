# rip: 最近安装的 200 个包
# 原 expac 实现，已改为直接解析 pacman 本地数据库（expac 已卸载）
# 用法: rip
function rip
    awk '
        /^%NAME%$/ {
            if (name != "" && inst != "") print inst "\t" name " " ver
            getline; name = $0; next
        }
        /^%VERSION%$/     { getline; ver = $0; next }
        /^%INSTALLDATE%$/ { getline; inst = $0; next }
        END { if (name != "" && inst != "") print inst "\t" name " " ver }
    ' /var/lib/pacman/local/*/desc | sort -n | tail -200 | while read -l line
        set -l f (string split \t -- $line)
        printf '%s\t%s\n' (date -d "@$f[1]" '+%Y-%m-%d %H:%M:%S') $f[2]
    end | nl
end
