#!/usr/bin/env sh

# waybar 重启脚本（手动使用）
#
# 没有热重载了：SIGUSR2 在 ~/.config/waybar/config 里被改成 on-sigusr2="hide"，
# 好让 ~/.config/niri/scripts/waybar-overview 按 overview 状态幂等地下发
# show / hide（SIGUSR1 = show）。默认的 `SIGUSR2 = reload` 被这个用途占掉了。
#
# 于是改完 config / CSS 只能重启进程：起来时是 hidden（config 的 start_hidden），
# 开 overview 才出现。别直接 `waybar &`：裸进程崩了不会自恢复，而且会和 service
# 在 systemd 视图里变成两个同名进程。restart 在没有进程时就是 start，两个情况通用。

systemctl --user restart waybar.service
