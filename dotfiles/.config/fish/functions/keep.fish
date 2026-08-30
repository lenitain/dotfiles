# keep.fish — 把软件包标记为"显式安装"，让 cleanup 不再误删它们
#
# 背景：cleanup 别名 = sudo pacman -Rns (pacman -Qtdq)，会删掉所有孤儿包
# （安装原因标记为"作为依赖安装"、且当前没有任何包需要的包）。
# keep 把这些包翻转为"显式安装"，pacman 就不再当它们是孤儿，cleanup 也不会动它们。
#
# 用法：
#   keep fish eza bat
function keep --description 'Mark packages as explicitly installed (pacman -D --asexplicit)'
    if test (count $argv) -eq 0
        echo 'usage: keep <package> [package...]' >&2
        echo 'example: keep fish eza bat' >&2
        return 1
    end
    sudo pacman -D --asexplicit $argv
end
