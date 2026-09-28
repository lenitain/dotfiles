#!/bin/bash
# Idle inhibit toggle script for waybar
# 显示眼睛图标：睁眼=抑制中(不会熄屏)，闭眼=正常(170 秒后熄屏)
#   注意：niri 侧 idle 只熄屏、从不锁屏（只有合盖和 before-sleep 才 swaylock），
#   所以这个按钮的语义是「不熄屏」，不是「不锁屏」。
#
# 抑制原理：swayidle 认 logind 的 idle 抑制剂 —— 发现有就整条 timeout 都不注册
# （二进制里的 "Not enabling timeouts: idle inhibitor found"），
# 见 ../niri/startup.kdl 的 `swayidle -w timeout 170 niri msg action power-off-monitors`。
#
# 状态不记在 pid 文件里，而是每次用 pgrep 现场找「属于我们」的抑制器
# （argv[0] 以 systemd-inhibit 开头 + --who=waybar-idle-inhibit），因此：
#   - 抑制器被外部杀掉 / logind 重启后自动纠正，不留「假 ON」或空 pid 文件
#   - 不会被系统回收复用的 pid 骗到，也就不会误 kill 无关进程
#   - 手抖点多次、或手动起过多个时，关闭一次全清干净
#   - 不往 /tmp 写固定名文件（别人可预建/抢占，同名不同用户时写入静默失败）
#
# 抑制器必须 setsid 脱离调用方进程组、且不继承 stdio：否则 waybar（或启动它的
# 终端）一退出它就被一起带走，图标会自己变回闭眼，而用户什么也没做。
# 状态不依赖 setsid 后的 $!（setsid 在已是组长时会 fork，$! 只会记到那个立刻
# 退出的 pid），所以 setsid 怎么 fork 都不影响。

WHO="waybar-idle-inhibit"
# 只认 argv[0] 就是 systemd-inhibit（可带路径）的进程，免得匹配到调用方的 shell
PATTERN="^[^[:space:]]*systemd-inhibit .*--who=${WHO}([[:space:]]|$)"

inhibitor_pids() {
    pgrep -f "$PATTERN" 2>/dev/null
}

state() {
    if [ -n "$(inhibitor_pids)" ]; then
        echo "on"
    else
        echo "off"
    fi
}

# 等状态落地再刷新图标：click → setsid → exec 中间有几十毫秒，立刻刷的话
# waybar 可能在抑制器真正出现之前就重跑本脚本，图标会停在旧状态。
wait_state() {
    local want=$1 i
    for ((i = 0; i < 20; i++)); do
        [ "$(state)" = "$want" ] && return 0
        sleep 0.05
    done
    return 1
}

show() {
    if [ "$(state)" = "on" ]; then
        # 抑制中 - 显示睁开的眼睛（不会熄屏）
        echo '{"text": "", "alt": "active", "class": "active", "tooltip": "Idle Inhibit: ON"}'
    else
        # 正常 - 显示闭上的眼睛（170 秒后会熄屏）
        echo '{"text": "", "alt": "inactive", "class": "inactive", "tooltip": "Idle Inhibit: OFF"}'
    fi
}

toggle() {
    if [ "$(state)" = "on" ]; then
        # 关闭抑制：一次清掉所有属于我们的抑制器（重复实例也收干净）
        inhibitor_pids | xargs -r kill 2>/dev/null
        wait_state off
    else
        # 开启抑制
        setsid systemd-inhibit --what=idle --who="$WHO" \
            --why="User requested" sleep infinity </dev/null >/dev/null 2>&1 &
        disown 2>/dev/null || true
        if ! wait_state on; then
            # 没注册上（比如 logind/dbus 不可用）：收干净，别留半死不活的实例。
            # 这样刷新后图标仍是闭眼 —— 用户看到「点了没反应」，而不是被骗成绿色
            inhibitor_pids | xargs -r kill 2>/dev/null
        fi
    fi
    # 触发 waybar 重跑本模块（modules.json 的 "signal": 8 == SIGRTMIN+8）。
    # 必须写 --signal：pkill 的 -s 是 session id 不是信号；-x 精确匹配进程名。
    # 不加 `|| true`：waybar 没在跑、或参数写错时报错要看得见，
    # 而不是静默让人以为刷新成功了（custom 模块没有 interval 兜底）
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
