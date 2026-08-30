#!/usr/bin/env sh

# waybar 重启 / 热重载脚本（手动使用）
#
# - waybar 正在运行 → 发送 SIGUSR2 热重载：
#     waybar v0.15 默认 SIGUSR2 = reload，重读 config + CSS，进程不退出、
#     模块原地重建。比重启快，且没有 killall 的竞态窗口。
# - waybar 未运行   → 交给 systemd 拉起（waybar.service 已 enable 到
#     graphical-session.target）。别直接 `waybar &`：裸进程崩了不会自恢复，
#     而且会和 service 在 systemd 视图里变成两个同名进程。
#
# 若 waybar 卡死导致热重载无效，再彻底重启：
#   systemctl --user restart waybar.service

if pgrep -x waybar >/dev/null; then
    pkill -USR2 waybar
    echo "waybar: SIGUSR2 热重载已发送"
else
    systemctl --user start waybar.service
    echo "waybar: 未运行，已交给 systemctl --user start waybar.service"
fi
