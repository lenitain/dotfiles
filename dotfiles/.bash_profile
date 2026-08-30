# 登录 bash 的入口：与 .bashrc 一样只 source init.sh，由它按是否交互决定加载哪一层。
#
# 注意 niri-session 会用登录 shell 再执行一次自己：
#   exec bash -c "exec -l '$SHELL' -c 'niri-session -l'"
# 那个 shell 是非交互的，不会读 .bashrc。PATH（~/.local/bin/scripts、mise shims）
# 必须由 init.sh 的环境层就绪，否则 niri 的 spawn "qb-open" / fuzzel-wrapper 等会找不到命令。

: "${BASH_CONFIG_HOME:=$HOME/.config/bash}"
[ -r "$BASH_CONFIG_HOME/init.sh" ] && . "$BASH_CONFIG_HOME/init.sh"
