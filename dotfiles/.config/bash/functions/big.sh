# big：所有 pacman 包按安装体积从小到大列出。

big() {
    LC_ALL=C pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4, $5, name}' | sort -h | nl
}
