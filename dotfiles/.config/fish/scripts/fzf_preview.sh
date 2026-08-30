#!/bin/bash
# ~/.config/fish/scripts/fzf_preview.sh
# fzf 预览逻辑脚本（独立文件，避免 fish 语法冲突）

# 接收 fzf 传递的文件路径参数
FILE="$(realpath -m "$1" 2>/dev/null || echo "$1")"

# 1. 判断文件是否存在
if [ ! -e "$FILE" ]; then
  echo "⚠️ 文件不存在或路径错误：$FILE"
  exit 0
fi

# 2. 判断文件类型并预览
if [ -L "$FILE" ]; then
  # 符号链接：显示链接目标
  TARGET="$(readlink -f "$FILE" 2>/dev/null)"
  echo "🔗 符号链接: $FILE"
  echo "   -> $TARGET"
  if [ -e "$TARGET" ]; then
    echo ""
    if [ -d "$TARGET" ]; then
      eza -a --icons --group-directories-first --color=always "$TARGET"
    elif file --mime-type "$TARGET" 2>/dev/null | grep -q text; then
      bat --color=always --style=numbers --theme="Everforest Dark" "$TARGET"
    else
      file -b "$TARGET"
    fi
  else
    echo "   ⚠️ 目标不存在"
  fi
elif [ -d "$FILE" ]; then
  # 目录：eza 彩色列出内容
  eza -a --icons --group-directories-first --color=always "$FILE"
elif file --mime-type "$FILE" 2>/dev/null | grep -q text; then
  # 文本文件：bat 高亮显示（带行号）
  bat --color=always --style=numbers --theme="Everforest Dark" "$FILE"
else
  # 二进制文件：格式化输出文件信息
  file -b "$FILE"
fi
