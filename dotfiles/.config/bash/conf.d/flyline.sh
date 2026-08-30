# flyline 的装配入口：加载 builtin，再按「配色 → widget → 行为」顺序 source 各段。
# 实现都在 flyline/ 里；这个文件只决定顺序和「没加载成功就整段跳过」。

__bash_config_home=${BASH_CONFIG_HOME:-$HOME/.config/bash}

. "$__bash_config_home/flyline/load.sh"

[ -n "${__bash_flyline_enabled-}" ] || { unset __bash_config_home; return 0; }

. "$__bash_config_home/flyline/style.sh"
. "$__bash_config_home/flyline/widget.sh"
. "$__bash_config_home/flyline/behavior.sh"

unset __bash_config_home
