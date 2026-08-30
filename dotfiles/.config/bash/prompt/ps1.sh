# PS1 构建：会话段 + cwd + 仓库占位符，本身不输出内容。
# 由 conf.d/prompt.sh 挂在 PROMPT_COMMAND 第一位，每次提示符重建一次 PS1。
. "${BASH_SOURCE[0]%/*}/lib.sh"

# pure 4.19.2 的 bash 版提示符。
# 只在 PROMPT_COMMAND 里运行：结果写进 PS1（不再写 PS1_FINAL），本身不输出内容。
#
# 渲染归 flyline：PS1 里的 FLYLINE_REPO 由 flyline 换成 widget 输出（仓库段
# 异步跑），这里只算 flyline 拿不到的东西：cwd 的宽度取舍、
# 以及会话开始后就固定的段。

# flyline widget 的实际宽度 bash 看不到（PS1 里只有占位符名字），按上限预留：
#   FLYLINE_REPO  jj/git 段：变更 id + 书签 + ~N/+N + ⇡⇣?!×≠ 的观测上限（含前导空格）
# 留宽了只会让 cwd 提前缩略，留窄了会让第一行折行。
__bash_prompt_repo_reserved=32

# 在 jj/git 仓库里才预留仓库段的宽度：仓库外 widget 输出为空，预留给它只会白白
# 吃掉 cwd 的列宽。只为挑预算，不要求精确，所以纯 bash 向上找标记，不 fork。
__bash_prompt_in_repo() {
    local dir=$PWD parent
    while :; do
        [ -e "$dir/.jj" ] || [ -e "$dir/.git" ] && return 0
        parent=${dir%/*}
        [ "$parent" != "$dir" ] || return 1
        dir=$parent
    done
}

# 把多个片段拼进 REPLY；空片段丢掉，分隔符默认空格。

# 去掉 \[ \] 和 ANSI 序列后的可见长度记进 REPLY，用于按终端宽度缩 cwd。
# 按字符数算；CJK 双宽路径会比终端列宽略宽。

# 超宽时只留尾部若干段，前面用 … 代替。flyline 的 find_cwd_in_span 会把
# “省略号 + 真实后缀”整体识别成 cwd 段，所以剩下的每一段仍然可点击跳转；
# 每段只留首字母（~/.c/m/d/foo）flyline 只能匹配到最后一段，中间段点不到。
__bash_prompt_abbreviate_path() {
    local path=$1 limit=$2 rest
    rest=${path#/}
    [ -n "$rest" ] || { REPLY=/; return 0; }
    while [ "${#rest}" -gt "$(( limit - 2 ))" ]; do
        case $rest in
            */*) rest=${rest#*/} ;;
            *) break ;;
        esac
    done
    REPLY="…/$rest"
}

# pure 会先算 cwd 之外的宽度，超宽才把路径缩成 …/尾段。
__bash_prompt_cwd() {
    local other_width=$1
    local cwd=${PWD/#$HOME/\~}
    local limit=$(( ${COLUMNS:-80} - other_width - 1 ))
    [ "$limit" -lt 4 ] && limit=4
    if [ "${#cwd}" -gt "$limit" ]; then
        __bash_prompt_abbreviate_path "$cwd" "$limit"
        cwd=$REPLY
    fi
    cwd_ansi="\[$__bash_prompt_color_blue\]$cwd\[$__bash_prompt_color_reset\]"
}

# 会话内不变的段只算一次：ZMX 会话名和 SSH 的 user@host 在会话开始后就不再变，
# PROMPT_COMMAND 里因此不用再 fork 一个 id -un。
__bash_prompt_build_static() {
    local -a parts=()
    [ -n "${ZMX_SESSION-}" ] && parts+=("[${ZMX_SESSION}]")
    __bash_prompt_ssh_build
    [ -n "$__bash_prompt_ssh_ansi" ] && parts+=("$__bash_prompt_ssh_ansi")
    __bash_prompt_join_into ' ' "${parts[@]}"
    local joined=$REPLY
    __bash_prompt_visible_length "$joined"
    __bash_prompt_static_width=$REPLY
    if [ -n "$joined" ]; then
        __bash_prompt_static="$joined "
        __bash_prompt_static_width=$(( __bash_prompt_static_width + 1 ))
    else
        __bash_prompt_static=''
    fi
    __bash_prompt_static_ready=1
}

__bash_prompt() {
    # 程序可能把光标改回 block。flyline 的 terminal 光标后端只让终端自己画，
    # 不代发 DECSCUSR，所以每条提示符前重发一次。
    if [ -t 1 ]; then
        printf '\e[6 q'
    fi

    [ -n "${__bash_prompt_static_ready-}" ] || __bash_prompt_build_static

    # 第一行的仓库段是 flyline 的异步 widget：宽度按预留上限计入，占位符交给 flyline 替换。
    # flyline 没加载成功时两件事都不做——否则 PS1 里会原样显示 FLYLINE_REPO 这个字符串。
    local repo_reserved=0 repo_placeholder=''
    if [ -n "${__bash_flyline_enabled-}" ]; then
        repo_placeholder='FLYLINE_REPO'
        __bash_prompt_in_repo && repo_reserved=$__bash_prompt_repo_reserved
    fi
    __bash_prompt_cwd "$(( __bash_prompt_static_width + repo_reserved ))"

    local symbol_ansi="\[$__bash_prompt_color_magenta\]$__bash_prompt_symbol\[$__bash_prompt_color_reset\]"

    # 非首次提示符前空一行。
    local leading_newline=''
    [ -n "${__bash_prompt_ran_before-}" ] && leading_newline=$'\n'

    PS1="\[$__bash_prompt_color_reset\]${leading_newline}${__bash_prompt_static}${cwd_ansi}${repo_placeholder}"$'\n'"${symbol_ansi} "
    # 不用瞬态提示符：命令提交后 flyline 的最后一次重绘沿用完整 PS1，第一行（会话段 +
    # cwd + 仓库段）和命令前的空行都留在历史里。
    # unset 而不是把 PS1 复制进 PS1_FINAL：flyline 对每个提示符变量各跑一遍 widget，
    # 复制一份会让 FLYLINE_REPO 多跑一次 jj/git。
    unset PS1_FINAL
    __bash_prompt_ran_before=1
}

__bash_prompt_ssh_build() {
    __bash_prompt_ssh_ansi=''
    [ -n "${SSH_CONNECTION-}" ] || return 0
    local user
    user=$(id -un)
    local user_color=$__bash_prompt_color_mute
    [ "$user" = root ] && user_color=$__bash_prompt_color_white
    local host=${HOSTNAME-}
    [ -n "$host" ] || host=$(uname -n)
    __bash_prompt_ssh_ansi="\[$user_color\]$user\[$__bash_prompt_color_mute\]@\[$__bash_prompt_color_mute\]${host}\[$__bash_prompt_color_reset\]"
}
