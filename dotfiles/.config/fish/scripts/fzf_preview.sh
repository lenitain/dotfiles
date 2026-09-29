#!/bin/bash
# ~/.config/fish/scripts/fzf_preview.sh
# fzf 预览逻辑脚本（独立文件，避免 fish 语法冲突）

# 预览用 plain 样式：不要行号。bat 的 numbers 样式行号字段固定 4 宽右对齐，
# 在 38% 的窄预览窗口里会把正文推得很远；而 bat 目前没有调整该宽度的选项
# (上游 sharkdp/bat#3914 在提 --line-number-width，尚未合并)。
# 语法高亮不受 plain 影响，仍然保留。
bat_preview() {
  bat --color=always --style=plain --theme="everforest-dark-medium" --paging=never "$1"
}

# 接收 fzf 传递的文件路径参数
# 用 realpath -m -s 只做规范化（消掉 . 和 ..、转绝对路径），
# 不解析符号链接，否则下面的 -L 分支永远进不去。
FILE="$(realpath -m -s -- "$1" 2>/dev/null || printf '%s\n' "$1")"

# 1. 判断文件是否存在（-e 对悬空链接为假，所以先查 -L）
if [ ! -e "$FILE" ] && [ ! -L "$FILE" ]; then
  echo "⚠️ 文件不存在或路径错误：$FILE"
  exit 0
fi

# 2. 判断文件类型并预览
if [ -L "$FILE" ]; then
  # 符号链接：显示链接目标
  echo "🔗 符号链接: $FILE"
  echo "   -> $(readlink -- "$FILE" 2>/dev/null)"
  TARGET="$(realpath -- "$FILE" 2>/dev/null)"
  if [ -n "$TARGET" ] && [ -e "$TARGET" ]; then
    echo ""
    if [ -d "$TARGET" ]; then
      eza -a --icons --group-directories-first --color=always "$TARGET"
    elif file --mime-type "$TARGET" 2>/dev/null | grep -q text; then
      bat_preview "$TARGET"
    else
      file -b "$TARGET"
    fi
  else
    echo "   ⚠️ 目标不存在（悬空链接）"
  fi
elif [ -d "$FILE" ]; then
  # 目录：eza 彩色列出内容
  eza -a --icons --group-directories-first --color=always "$FILE"
elif file --mime-type "$FILE" 2>/dev/null | grep -q text; then
  # 文本文件：bat 语法高亮
  bat_preview "$FILE"
else
  # 二进制文件：格式化输出文件信息
  file -b "$FILE"
fi
