#!/bin/bash
# ~/.config/fish/scripts/fzf_preview.sh
# fzf 预览逻辑脚本（独立文件，避免 fish 语法冲突）

# 接收 fzf 传递的文件路径参数
FILE="$1"

# 1. 判断文件是否存在
if [ ! -e "$FILE" ]; then
  echo "⚠️ 文件不存在或路径错误：$FILE"
  exit 0
fi

# 2. 判断文件类型并预览
if file --mime-type "$FILE" | grep -q text; then
  # 文本文件：bat 高亮显示（带行号）
  bat --color=always --style=numbers --theme="Solarized (light)" "$FILE"
else
  # 二进制文件：格式化输出文件信息
  file -b "$FILE" | awk -F: '{print "类型："$1"\n"substr($0, index($0,$2))}'
fi
