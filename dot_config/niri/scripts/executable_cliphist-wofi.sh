#!/bin/bash
# 使用 wofi 显示剪贴板历史,支持文本和图片

# 检查是否已经有实例在运行
if pgrep -x "wofi" > /dev/null; then
    pkill -x "wofi"
    exit 0
fi

# 获取选择,保留完整的 ID\t内容 格式传给 wofi
selected=$(cliphist list | wofi --dmenu --prompt="Clipboard" --width=1100 --height=700 --hide-scroll)

if [ -n "$selected" ]; then
    # 直接用选中的完整行(包含ID)进行decode
    echo "$selected" | cliphist decode | wl-copy
fi
