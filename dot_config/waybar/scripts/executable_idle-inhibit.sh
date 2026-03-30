#!/bin/bash
# Idle inhibit toggle script for waybar
# 显示眼睛图标：睁开=抑制中(不会锁屏)，闭眼=正常(会锁屏)

STATE_FILE="/tmp/waybar-idle-inhibit"
PID_FILE="/tmp/waybar-idle-inhibit.pid"

get_status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "active"
    else
        echo "inactive"
    fi
}

show() {
    status=$(get_status)
    if [ "$status" = "active" ]; then
        # 抑制中 - 显示睁开的眼睛（不会自动锁屏）
        echo '{"text": " ", "alt": "active", "class": "active", "tooltip": "Idle Inhibit: ON (屏幕不会自动锁定)"}'
    else
        # 正常 - 显示闭上的眼睛（会自动锁屏）
        echo '{"text": " ", "alt": "inactive", "class": "inactive", "tooltip": "Idle Inhibit: OFF (屏幕会自动锁定)"}'
    fi
}

toggle() {
    status=$(get_status)
    if [ "$status" = "active" ]; then
        # 关闭抑制
        if [ -f "$PID_FILE" ]; then
            kill "$(cat "$PID_FILE")" 2>/dev/null
            rm -f "$PID_FILE"
        fi
    else
        # 开启抑制 - 使用systemd-inhibit或swayidle阻止idle
        systemd-inhibit --what=idle --who="waybar-idle-inhibit" --why="User requested" sleep infinity &
        echo $! > "$PID_FILE"
    fi
    # 触发waybar刷新
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

case "$1" in
    toggle)
        toggle
        ;;
    *)
        show
        ;;
esac
