# PS1 构建：会话段 + cwd + 仓库占位符 + 符号行，本身不输出内容。
# 由 conf.d/prompt.sh 挂在 PROMPT_COMMAND 第一位，每次提示符重建一次 PS1。
. "${BASH_SOURCE[0]%/*}/lib.sh"

# pure 4.19.2 的 bash 版提示符。
# 只在 PROMPT_COMMAND 里运行：结果写进 PS1（不再写 PS1_FINAL），本身不输出内容。
#
# 渲染归 flyline：PS1 里的 FLYLINE_REPO 由 flyline 换成 widget 输出（仓库段
# 异步跑），这里只算 flyline 拿不到的东西：cwd 的宽度取舍、会话开始后就固定
# 的段，以及只能从 shell 状态（PIPESTATUS / 环境变量）里读的符号行。

# flyline widget 的实际宽度 bash 看不到（PS1 里只有占位符名字）：仓库里先用
# lib.sh 的上限预留，之后用 widget 写回的实际宽度（__bash_prompt_repo_width_read）。
# 留宽了只会让 cwd 提前缩略，留窄了会让第一行折行。

# 在 jj/git 仓库里才预留仓库段的宽度：仓库外 widget 输出为空，预留给它只会白白
# 吃掉 cwd 的列宽。只为挑预算，不要求精确，所以纯 bash 向上找标记。
__bash_prompt_find_repo_marker() {
    local dir=${1:-$PWD} parent
    while :; do
        [ -e "$dir/.jj" ] || [ -e "$dir/.git" ] && return 0
        parent=${dir%/*}
        [ "$parent" != "$dir" ] || return 1
        dir=$parent
    done
}

# 逻辑路径优先（常见情况下不起子 shell）；找不到再按物理路径找一次：
# $PWD 是逻辑路径，而 jj/git 自己按物理路径解析，从符号链接进仓库子目录时
# 只有物理路径上才有标记。
__bash_prompt_in_repo() {
    __bash_prompt_find_repo_marker "$PWD" && return 0
    local physical
    physical=$(pwd -P)
    [ "$physical" = "$PWD" ] && return 1
    __bash_prompt_find_repo_marker "$physical"
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

# 会话内不变的段只算一次：ZMX 会话名、SSH 与容器的 user@host——这三样在会话开始后
# 不再变，PROMPT_COMMAND 里因此不用每条提示符都 fork 一个 id -un、读一遍 /proc。
__bash_prompt_build_static() {
    local -a parts=()
    [ -n "${ZMX_SESSION-}" ] && parts+=("[${ZMX_SESSION}]")
    __bash_prompt_ssh_build
    [ -n "$__bash_prompt_ssh_ansi" ] && parts+=("$__bash_prompt_ssh_ansi")
    __bash_prompt_container_build
    [ -n "$__bash_prompt_container_ansi" ] && parts+=("$__bash_prompt_container_ansi")
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
    # PIPESTATUS 必须是函数最先碰到的东西：下面那句 printf 就会把管道状态冲成它自己的 0。
    local pipeline=("${PIPESTATUS[@]}")

    # 程序可能把光标改回 block。flyline 的 terminal 光标后端只让终端自己画，
    # 不代发 DECSCUSR，所以每条提示符前重发一次。
    if [ -t 1 ]; then
        printf '\e[6 q'
    fi

    [ -n "${__bash_prompt_static_ready-}" ] || __bash_prompt_build_static

    # 第一行的仓库段是 flyline 的异步 widget：宽度按上一次 widget 写回的实际值计入，
    # 还没有缓存（本仓库第一条提示符）时用上限；占位符交给 flyline 替换。
    # flyline 没加载成功时两件事都不做——否则 PS1 里会原样显示 FLYLINE_REPO 这个字符串。
    local repo_reserved=0 repo_placeholder=''
    if [ -n "${__bash_flyline_enabled-}" ]; then
        repo_placeholder='FLYLINE_REPO'
        if __bash_prompt_in_repo; then
            repo_reserved=$__bash_prompt_repo_reserved
            __bash_prompt_repo_width_read "$$" && [ "$REPLY" -gt 0 ] && [ "$REPLY" -le "${COLUMNS:-80}" ] && repo_reserved=$REPLY
        fi
    fi
    __bash_prompt_cwd "$(( __bash_prompt_static_width + repo_reserved ))"

    local symbol_ansi="\[$__bash_prompt_color_magenta\]$__bash_prompt_symbol\[$__bash_prompt_color_reset\]"

    # 符号行的段（pure 的第 2 行布局）：root/nix/venv → 退出码 → ❯。
    # 都只读变量和内建，每条提示符重算也不会 fork；会话内不变的那几段在 static 里。
    local -a symbol_parts=()
    __bash_prompt_context
    [ -n "$REPLY" ] && symbol_parts+=("$REPLY")
    __bash_prompt_exit_status "${pipeline[@]}"
    [ -n "$REPLY" ] && symbol_parts+=("$REPLY")
    __bash_prompt_join_into ' ' "${symbol_parts[@]}" "$symbol_ansi"
    local symbol_line=$REPLY

    # 非首次提示符前空一行。
    local leading_newline=''
    [ -n "${__bash_prompt_ran_before-}" ] && leading_newline=$'\n'

    PS1="\[$__bash_prompt_color_reset\]${leading_newline}${__bash_prompt_static}${cwd_ansi}${repo_placeholder}"$'\n'"${symbol_line} "
    # 不用瞬态提示符：命令提交后 flyline 的最后一次重绘沿用完整 PS1，第一行（会话段 +
    # cwd + 仓库段）和命令前的空行都留在历史里。
    # unset 而不是把 PS1 复制进 PS1_FINAL：flyline 对每个提示符变量各跑一遍 widget，
    # 复制一份会让 FLYLINE_REPO 多跑一次 jj/git。
    unset PS1_FINAL
    __bash_prompt_ran_before=1
}

# user@host 的彩色形式写进 REPLY：root 的用户名用白色（pure 的 pure_color_username_root）。
__bash_prompt_user_at_host() {
    local user
    user=$(id -un)
    local user_color=$__bash_prompt_color_mute
    [ "$user" = root ] && user_color=$__bash_prompt_color_white
    local host=${HOSTNAME-}
    [ -n "$host" ] || host=$(uname -n)
    REPLY="\[$user_color\]$user\[$__bash_prompt_color_mute\]@\[$__bash_prompt_color_mute\]${host}\[$__bash_prompt_color_reset\]"
}

__bash_prompt_ssh_build() {
    __bash_prompt_ssh_ansi=''
    [ -n "${SSH_CONNECTION-}" ] || return 0
    __bash_prompt_user_at_host
    __bash_prompt_ssh_ansi=$REPLY
}

# 容器检测：只看 Linux，全部读固定路径，不 fork。顺序是「能说出名字的先」——
# 标记文件 → systemd → cgroup → PID 1。cgroup v2 的 /proc/1/cgroup 只有一行 0::/，
# 所以 rootless docker/podman 这类只能由 PID 1 兜底，那时只有泛称 container。
__bash_prompt_container_kind() {
    local cgroup=${1:-/proc/1/cgroup} sched=${2:-/proc/1/sched}
    REPLY=''
    [ -r "$cgroup" ] || return 0

    # 运行时自己留的标记最准，也不用解析。
    [ -e /.dockerenv ] && { REPLY=docker; return 0; }
    [ -e /run/.containerenv ] && { REPLY=podman; return 0; }

    local line kind
    if [ -r /run/systemd/container ]; then
        read -r kind </run/systemd/container
        [ -n "$kind" ] && { REPLY=$kind; return 0; }
    fi

    while IFS= read -r line; do
        case $line in
            *docker*) REPLY=docker; return 0 ;;
            *podman*) REPLY=podman; return 0 ;;
            *lxc*) REPLY=lxc; return 0 ;;
            *lxd*) REPLY=lxd; return 0 ;;
        esac
    done <"$cgroup"

    # PID 1 不是 init/systemd/shepherd 就是在容器里（pure 的 pid 方法）。
    if [ -r "$sched" ] && read -r line <"$sched"; then
        case ${line%% *} in
            ''|init|systemd|shepherd) ;;
            *) REPLY=container ;;
        esac
    fi
    return 0
}

# 容器里的 user@host 段（pure 的 container 段）：容器里没有 SSH_CONNECTION，
# 身份只能从这里看。pure 的前缀默认为空，这里用运行时的名字当前缀，能看出是哪一层。
__bash_prompt_container_build() {
    __bash_prompt_container_ansi=''
    __bash_prompt_container_kind
    local kind=$REPLY
    [ -n "$kind" ] || return 0
    __bash_prompt_user_at_host
    __bash_prompt_container_ansi="\[$__bash_prompt_color_mute\][$kind]\[$__bash_prompt_color_reset\] $REPLY"
}

# 符号行上的环境上下文，顺序同 pure：root 前缀 # → nix develop → Python venv。
# 全是变量判断，不 fork。
__bash_prompt_context() {
    local -a parts=()
    [ "$EUID" -eq 0 ] && parts+=("\[$__bash_prompt_color_red\]$__bash_prompt_symbol_root\[$__bash_prompt_color_reset\]")
    if [ -n "${IN_NIX_SHELL-}" ]; then
        parts+=("\[$__bash_prompt_color_cyan\]$__bash_prompt_symbol_nixdevshell\[$__bash_prompt_color_mute\]$IN_NIX_SHELL\[$__bash_prompt_color_reset\]")
    fi
    # pure 的取值顺序：VIRTUAL_ENV_PROMPT（可能自带括号）→ VIRTUAL_ENV → CONDA_DEFAULT_ENV，
    # 后两者只取末段。venv 自带的前缀在 conf.d/prompt.sh 里关掉了。
    local venv=${VIRTUAL_ENV_PROMPT:-}
    if [ -z "$venv" ]; then
        local path=${VIRTUAL_ENV:-${CONDA_DEFAULT_ENV:-}}
        [ -n "$path" ] && venv=${path##*/}
    fi
    [ -n "$venv" ] && parts+=("\[$__bash_prompt_color_mute\]$venv\[$__bash_prompt_color_reset\]")
    __bash_prompt_join_into ' ' "${parts[@]}"
}

# 128+N 换信号名（pure 的 pure_convert_exit_status_to_signal），Linux 的 1..31 号。
__bash_prompt_signal_names=(HUP INT QUIT ILL TRAP ABRT BUS FPE KILL USR1 SEGV USR2 PIPE ALRM TERM STKFLT CHLD CONT STOP TSTP TTIN TTOU URG XCPU XFSZ VTALRM PROF WINCH IO PWR SYS)

# 上一条命令失败时列出整条管道的退出码（pure 的 pure_show_exit_status）：
# 只有最后一个状态非 0 才显示，格式与 pure 的 |前缀/|分隔符一致。
__bash_prompt_exit_status() {
    REPLY=''
    local -a codes=("$@")
    local last_status=${codes[-1]:-0}
    [ "$last_status" -ne 0 ] || return 0

    local text='' code index
    for code in "${codes[@]}"; do
        index=$(( code - 129 ))
        if [ "$index" -ge 0 ] && [ "$index" -lt ${#__bash_prompt_signal_names[@]} ]; then
            code="SIG${__bash_prompt_signal_names[index]}"
        fi
        text+="${text:+$__bash_prompt_symbol_exit_status}$code"
    done
    REPLY="\[$__bash_prompt_color_red\]$__bash_prompt_symbol_exit_status$text\[$__bash_prompt_color_reset\]"
}
