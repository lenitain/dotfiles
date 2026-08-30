# 交互 shell 的入口：只 source init.sh，加载逻辑全在那边（.bash_profile 也 source 它），
# 两个入口不再各自维护一份清单。说明见 ~/.config/bash/README.md。

: "${BASH_CONFIG_HOME:=$HOME/.config/bash}"
[ -r "$BASH_CONFIG_HOME/init.sh" ] && . "$BASH_CONFIG_HOME/init.sh"
