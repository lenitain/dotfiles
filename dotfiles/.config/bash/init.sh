# bash 的唯一入口：~/.bashrc 与 ~/.bash_profile 都只 source 这个文件。
#
# 分两层，按当前 shell 是否交互决定：
#   环境层（所有 shell）—— 变量、PATH、工具链、密钥。niri 会用登录 shell 跑一个
#     非交互 bash（见 ~/.bash_profile 顶部），那条路径只靠这一层。
#   交互层（只有交互 shell）—— 函数、别名、键位、提示符。
#
# 下面每一段的顺序都是依赖，不是偏好。

: "${BASH_CONFIG_HOME:=$HOME/.config/bash}"

__bash_source() {
    local file
    for file in "$@"; do
        [ -r "$file" ] && . "$file"
    done
}

# ─── 环境层 ───
# env 先（PATH/变量是其它文件的前提），mise 后（activate 会再改一次 PATH，它自己收尾去重）。
__bash_source "$BASH_CONFIG_HOME"/conf.d/env.sh "$BASH_CONFIG_HOME"/conf.d/mise.sh

# 密钥：*KEY.sh 是唯一约定，仓库根 .gitignore 也按它忽略。没有文件时这个 glob 不展开，
# __bash_source 会因为读不到而跳过。
__bash_source "$BASH_CONFIG_HOME"/conf.d/*KEY.sh

# ─── 交互层 ───
# 非交互 shell（niri 的登录路径、`ssh host cmd`）到环境层为止。
if [[ $- != *i* ]]; then
    unset -f __bash_source
    return 0
fi

# functions/：只定义函数、互不依赖，所以用 glob，加文件不用登记。
__bash_source "$BASH_CONFIG_HOME"/functions/*.sh

# prompt/：主 shell 只需要 PS1 与钩子；repo.sh 由 widgets/repo.sh 在子进程里自己 source。
__bash_source "$BASH_CONFIG_HOME"/prompt/ps1.sh "$BASH_CONFIG_HOME"/prompt/hooks.sh

# conf.d/：顺序有依赖，显式列出 ——
#   aliases  无依赖
#   flyline  必须在 fzf / zmx 之前（两者靠 __bash_flyline_enabled 决定要不要绑键）
#   fzf      依赖 flyline（__flyline_widget_* 入口也定义在这个文件里）
#   history  无依赖
#   prompt   依赖 functions/ 与 prompt/ps1.sh、prompt/hooks.sh
#   zmx      依赖 flyline
__bash_source \
    "$BASH_CONFIG_HOME"/conf.d/aliases.sh \
    "$BASH_CONFIG_HOME"/conf.d/flyline.sh \
    "$BASH_CONFIG_HOME"/conf.d/fzf.sh \
    "$BASH_CONFIG_HOME"/conf.d/history.sh \
    "$BASH_CONFIG_HOME"/conf.d/prompt.sh \
    "$BASH_CONFIG_HOME"/conf.d/zmx.sh

unset -f __bash_source
