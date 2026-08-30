#!/bin/bash
# Idle inhibit toggle script for waybar
# 显示眼睛图标：睁眼=抑制中(不会熄屏)，闭眼=正常(niri 侧 idle 超时后熄屏)
#   注意：niri 侧 idle 只熄屏、从不锁屏（只有合盖和 before-sleep 才 swaylock），
#   所以这个按钮的语义是「不熄屏」，不是「不锁屏」。
#
# 抑制原理：swayidle 认 logind 的 idle 抑制剂 —— 发现有就整条 timeout 都不注册。
# 那个 timeout 的实际数值在 ../niri/startup.kdl 的 swayidle 行，图标 tooltip 与
# 本脚本的回显文字以那里为准。
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
# 被一起带走，图标会自己变回闭眼，而用户什么也没做。stdin 关 /dev/null；
# stdout 是握手管道（必须保留）；stderr 不关 —— systemd-inhibit 的报错要能进
# waybar 日志，失败不静默（同下面 pkill 不加 `|| true` 的理由）。

WHO="waybar-idle-inhibit"

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

start() {
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

stop() {
    # 关闭抑制：一次清掉所有属于我们的抑制器（重复实例也收干净）
    inhibitor_pids | xargs -r kill 2>/dev/null
    # 死亡确认：kill 成功投递 ≠ 已死。每次探针 ~6ms + 1ms，上限 50 次 ≈ 350ms；
    # 还没死就不硬改状态，交给 show() 如实显示（图标保持睁眼 = 真相）
    local i
    for ((i = 0; i < 50; i++)); do
        [ -z "$(inhibitor_pids)" ] && return 0
        sleep 0.001
    done
    return 1
}

show() {
    if [ "$(state)" = "on" ]; then
        # 抑制中 - 显示睁开的眼睛（不会熄屏）
        echo '{"text": "", "alt": "active", "class": "active", "tooltip": "Idle Inhibit: ON"}'
    else
        # 正常 - 显示闭上的眼睛（niri idle 超时后会熄屏）
        echo '{"text": "", "alt": "inactive", "class": "inactive", "tooltip": "Idle Inhibit: OFF"}'
    fi
}

toggle() {
    if [ "$(state)" = "on" ]; then
        stop
    else
        # start 失败已在内部收干净：state 仍是 off，图标保持闭眼 ——
        # 用户看到「点了没反应」，而不是被骗成绿色
        start
    fi
    # 触发 waybar 重跑本模块（modules.json 的 "signal": 8 == SIGRTMIN+8）。
    # 必须写 --signal：pkill 的 -s 是 session id 不是信号；-x 精确匹配进程名。
    # 不加 `|| true`：waybar 没在跑、或参数写错时报错要看得见，
    # 而不是静默让人以为刷新成功了（custom 模块没有 interval 兜底）。
    # 刷新放最后：此时状态已被上面的握手/死亡确认敲定，show() 现场查询
    # 拿到的必然是新状态，不存在「抢在状态落地前重读」的竞态。
    pkill --signal RTMIN+8 -x waybar
}

case "$1" in
    toggle)
        toggle
        ;;
    *)
        show
        ;;
esac
