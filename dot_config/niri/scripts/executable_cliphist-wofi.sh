#!/bin/bash
# 使用 wofi 显示剪贴板历史,支持文本和图片

# 获取选择,保留完整的 ID\t内容 格式传给 wofi
selected=$(cliphist list | ~/.config/wofi/wofi-wrapper --dmenu --prompt="Clipboard" --hide-scroll)

if [ -n "$selected" ]; then
    # 直接用选中的完整行(包含ID)进行decode
    echo "$selected" | cliphist decode | wl-copy
fi
