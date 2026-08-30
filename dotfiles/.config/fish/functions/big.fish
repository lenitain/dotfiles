# big: 按安装体积列出所有包（从小到大）
# 原 expac 实现，已改为纯 pacman -Qi 解析（expac 已卸载）
# 用法: big
function big
    LC_ALL=C pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4, $5, name}' | sort -h | nl
end
