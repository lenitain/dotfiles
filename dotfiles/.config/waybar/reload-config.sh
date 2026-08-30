#!/usr/bin/env sh

# waybar 重启 / 热重载脚本（手动使用）
#
# - waybar 正在运行 → 发送 SIGUSR2 热重载：
#     waybar v0.15 默认 SIGUSR2 = reload，重读 config + CSS，进程不退出、
#     模块原地重建。比重启快，且没有 killall 的竞态窗口。
# - waybar 未运行   → 直接启动（首次启动 / 崩溃恢复）。
#
# 若 waybar 卡死导致热重载无效，再手动彻底重启：
#   killall waybar && waybar &

if pgrep -x waybar >/dev/null; then
    pkill -USR2 waybar
    echo "waybar: SIGUSR2 热重载已发送"
else
    waybar &
    echo "waybar: 未运行，已启动"
fi
