#!/usr/bin/env bash
# 现代化截图脚本 - 使用 grim + slurp + satty
# 支持区域选择、编辑标注、自动保存和复制到剪贴板

# 截图保存目录
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# 生成文件名（时间戳格式）
FILENAME="$SCREENSHOT_DIR/Screenshot_$(date +%Y%m%d_%H%M%S).png"

# 使用 slurp 选择区域，grim 截图，satty 编辑
grim -g "$(slurp)" - | satty --filename - --fullscreen --output-filename "$FILENAME" --early-exit --copy-command wl-copy

# 检查是否成功保存
if [ -f "$FILENAME" ]; then
    notify-send "截图已保存" "$FILENAME" -i "$FILENAME"
fi
