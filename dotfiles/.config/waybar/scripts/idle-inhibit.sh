#!/bin/bash
# Idle inhibit toggle script for waybar
# 显示 desktop（显示器）图标：两态共用同一张字形；绿色=抑制中(不会熄屏)，
# 米色=正常(niri 侧 idle 超时后熄屏)。单字形切换，零位移。
#   注意：niri 侧 idle 只熄屏、从不锁屏（只有合盖和 before-sleep 才 swaylock），
#   所以这个按钮的语义是「不熄屏」，不是「不锁屏」。
#
# 熄屏的原理：swayidle 的 timeout 命令是本脚本的 blank —— 它现场查 logind 的
# 抑制器列表，锁在（常亮）就什么都不做，锁不在就照常熄屏。熄屏的超时值就在下面
# start_swayidle 里（300 秒），图标 tooltip 与本脚本的回显文字以那里为准。
#   （早先是靠 swayidle 自己认 logind 的 idle 抑制剂来决定要不要注册 timeout，
#    但那条路只在它连上 logind 时才成立 —— 见 start_swayidle 的注释。判断放到
#    自己这边更直白，也不受 swayidle 版本差异影响。）
#
# 状态不记在 pid 文件里，而是每次现场查 logind 的 ListInhibitors（busctl）。
# 选它而不是 pgrep：一是快 —— 实测 6ms，pgrep -f 要 21-45ms（全量扫 300+ 进程
# 的 cmdline），是旧版 toggle 延迟的大头；二是准 —— 它查的是锁本身，正是
# swayidle 读的那个东西，比「进程在不在」更接近真相，抑制器被外部杀掉 /
# logind 重启后同样自动纠正，不留「假 ON」。pid 也从同一条目取：持锁进程一死
# fd 就关、logind 当场删条目，所以「被列出的 pid 必然是活的持锁者」，不会被
# 系统复用的旧 pid 骗到误杀；依旧不往 /tmp 写 pid 文件（别人可预建抢占）。
#
# 开启不轮询状态，而是等「就绪握手」：让被启动的命令在 Inhibit 成功之后写一行
# ready，脚本阻塞读管道 —— 读到行 = 注册成功，读到 EOF = 失败（systemd-inhibit
# 在 fork 之前就会因 Inhibit 失败退出，比如 logind/dbus 不可用）。事件一到立刻
# 返回；成败在同一次读里分流，失败路径不需要单独的回滚分支，也不会有「抢在
# 状态落地前刷新」的竞态（刷新永远发生在握手之后）。关闭路径 kill 后做死亡
# 确认：kill 只是异步投递，进程死亡没有事件源可用，只能确认 —— 每次探针 6ms、
# 典型第 1-2 次就过，是兜底，不是主路径上的等待。
#
# 抑制器必须 setsid 脱离调用方进程组：否则 waybar（或启动它的终端）一退出它就
# 被一起带走，图标会自己变回米色/正常，而用户什么也没做。stdin 关 /dev/null；
# stdout 是握手管道（必须保留）；stderr 不关 —— systemd-inhibit 的报错要能进
# waybar 日志，失败不静默（同下面 pkill 不加 `|| true` 的理由）。
#
# 命令：on / off / toggle / blank / 不带参数。
#   on  = 确保整套机制就位：swayidle 在跑（它管 5 分钟自动熄屏）+ 锁在（此刻不熄）。
#         已经开着就什么都不做（幂等），所以 niri 开机那行 spawn-at-startup 调的就是
#         它 —— 每次开机都是常亮起点。
#   off = 解除抑制：锁一放，5 分钟自动熄屏立刻恢复。
#   toggle = on/off 来回切（waybar 按钮用）。
#   blank = swayidle 的 timeout 命令：熄不熄屏由这把锁决定。
#   不带参数 = 只打印当前状态（waybar 模块的 exec 用它）。

WHO="waybar-idle-inhibit"

# 自己的绝对路径：swayidle 的 timeout 命令要拿它当 argv 传过去，而那条命令是
# swayidle 用 sh -c 跑的 —— 相对路径会在别的 cwd 下失效。
SCRIPT="$(readlink -f "$0")"

# 输出「属于我们」的持锁进程 pid（可能多个，一行一个；没有则为空）。
# busctl 输出的元组是 a(ssssuu)：what who why mode uid pid，pid 是最后一个字段；
# 用 what+who 双字段锚定，免得被别人 why 里的同名片段误匹配。
inhibitor_pids() {
    busctl --system call org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager ListInhibitors 2>/dev/null \
        | grep -o "\"idle\" \"${WHO}\" \"[^\"]*\" \"[^\"]*\" [0-9][0-9]* [0-9][0-9]*" \
        | awk '{print $NF}'
}

state() {
    if [ -n "$(inhibitor_pids)" ]; then
        echo "on"
    else
        echo "off"
    fi
}

# 熄屏：swayidle 的 timeout 命令跑的就是它。
# 熄不熄屏由这把锁决定 —— 锁在（常亮）就什么都不做；锁不在就照常熄屏。
blank() {
    if [ "$(state)" = "on" ]; then
        return 0
    fi
    niri msg action power-off-monitors
}

# 起 swayidle（管熄屏的那个 daemon）。已经在跑就别再起一个：两个 swayidle 会各
# 注册一次 timeout，退出其中一个状态就乱了。
# 交给 niri 起（niri msg action spawn）：它会把进程放进 niri 自己的 transient
# scope —— 属于本次会话，注销时随会话一起收掉，也不会因为「谁发起的这行命令」
# （终端、脚本）而跟着陪葬。自己 setsid 起的话就会继承调用方的 cgroup，
# 终端一关，daemon 跟着死。
# before-sleep 那句不能省：swayidle 只有配了 before-sleep/lock/unlock/idlehint
# 才会去连 logind，也只有连上了才认 idle 抑制剂（BlockInhibited）—— 缺了这些
# 它连 logind 都不连，抑制器对它完全无效。现在熄屏的决定权在 blank() 自己手里，
# 不再依赖它那条路，但 before-sleep 的 swaylock 还得留着。
start_swayidle() {
    if pgrep -x swayidle >/dev/null 2>&1; then
        return 0
    fi
    niri msg action spawn -- swayidle -w timeout 300 "$SCRIPT blank" \
        before-sleep "swaylock -f"
}

on() {
    # 熄屏机制先就位，再挂锁：锁挂不上时，至少还有 5 分钟自动熄屏兜着。
    start_swayidle || return 1
    # on = 确保锁在：已经开着就什么都不做，不叠第二条锁。幂等，
    # 所以 niri 开机那行可以无条件调。
    if [ "$(state)" = "on" ]; then
        return 0
    fi
    # 就绪握手：systemd-inhibit 的顺序是「先 Inhibit、再 fork/exec 命令」，
    # 所以 sh 里那句 echo ready 只可能在锁已拿到之后执行 —— 读到它就是
    # 注册成功这个事件本身，不是猜测。
    exec 3< <(setsid systemd-inhibit --what=idle --who="$WHO" \
        --why="User requested" sh -c 'echo ready; exec sleep infinity' </dev/null)
    local ready
    read -r -t 5 ready <&3
    exec 3<&-
    if [ "$ready" = ready ]; then
        return 0
    fi
    # EOF = 注册失败，进程根本不存在，下面是空操作；万一 5s 超时但进程其实
    # 起来了，收干净，别留一个图标看不见的抑制器（假 OFF）
    inhibitor_pids | xargs -r kill 2>/dev/null
    return 1
}

off() {
    # 关闭抑制：一次清掉所有属于我们的抑制器（重复实例也收干净）
    inhibitor_pids | xargs -r kill 2>/dev/null
    # 死亡确认：kill 成功投递 ≠ 已死。每次探针 ~6ms + 1ms，上限 50 次 ≈ 350ms；
    # 还没死就不硬改状态，交给 show() 如实显示（图标保持实际颜色 = 真相）
    local i
    for ((i = 0; i < 50; i++)); do
        [ -z "$(inhibitor_pids)" ] && return 0
        sleep 0.001
    done
    return 1
}

show() {
    if [ "$(state)" = "on" ]; then
        # 抑制中 - 绿色（CSS .active）
        echo '{"text": "", "alt": "active", "class": "active", "tooltip": "Idle Inhibit: ON"}'
    else
        # 正常 - 同一张 desktop 字形，米色（CSS base）
        echo '{"text": "", "alt": "inactive", "class": "inactive", "tooltip": "Idle Inhibit: OFF"}'
    fi
}

toggle() {
    if [ "$(state)" = "on" ]; then
        off
    else
        # on 失败已在内部收干净：state 仍是 off，图标保持米色 ——
        # 用户看到「点了没反应」，而不是被骗成绿色
        on
    fi
}

# 触发 waybar 重跑本模块（modules.json 的 "signal": 8 == SIGRTMIN+8）。
# 这不是「杀 waybar」的开关：waybar 的 custom 模块在 "signal" 配置下处于
# waitingWorker 状态，收到这个实时信号只会 thread_.wake_up()，重新跑一遍
# exec 并把图标刷新成当前状态（见 waybar 源码 Custom::refresh）。
# 但实时信号在 waybar 装好处理器之前，默认动作是 Term —— 冷启动时它还在
# 动态链接器里，此时发过去就是静默秒杀（没有日志、没有 core）。
#
# 所以这里不按名字广播，而是逐个核对目标：
#   1. /proc/<pid>/exe 必须是 waybar（同名进程不算）；
#   2. SigCgt 掩码里 SIGRTMIN+8 对应位必须是 1，即 waybar 已经把这个信号
#      接成「刷新」而不是「终止」。
# 两条都满足才发。不满足就跳过 —— 它启动后会自己跑一遍 show()，状态不会丢。
# 结论：on / toggle / off 都只能请求刷新，没有正常路径能杀死 waybar。
refresh_waybar() {
    local pid mask
    for pid in $(pgrep -x waybar); do
        case "$(readlink -f "/proc/$pid/exe" 2>/dev/null)" in
            */waybar) ;;
            *) continue ;;
        esac
        mask=$(sed -n 's/^SigCgt:[[:space:]]*//p' "/proc/$pid/status" 2>/dev/null)
        [ -n "$mask" ] || continue
        # glibc: SIGRTMIN=34，SIGRTMIN+8=42，对应掩码第 41 位（从 0 数）
        (( (16#$mask >> 41) & 1 )) || continue
        kill -s RTMIN+8 "$pid" 2>/dev/null
    done
}

case "$1" in
    toggle)
        toggle
        status=$?
        ;;
    on)
        on
        status=$?
        ;;
    off)
        off
        status=$?
        ;;
    blank)
        # swayidle 的 timeout 命令：不改状态，也不刷新图标。
        blank
        exit 0
        ;;
    *)
        show
        exit 0
        ;;
esac

# 状态已经落定，再请求刷新（能否刷新由 refresh_waybar 的就绪检查决定）。
refresh_waybar
exit "$status"
