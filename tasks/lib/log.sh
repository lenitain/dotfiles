#!/usr/bin/env bash
# 供 tasks/* 共用的日志函数（source 引入, 不直接执行）。
#
# 规范:
#   info — 正在做什么
#   ok   — 成功
#   warn — 可恢复失败（"更新软失败"）: 打印原因, 保留现状, 继续执行
#   err  — 不可恢复失败: 调用方随后 exit 1
#
# 全部走 stdout（与既有 setup-* 输出风格一致, mise 会原样转发）。
# 注意: 本文件会被 `source`, 调用方需自行 `set -euo pipefail`。

# ── 输出格式: 颜色码与标签的唯一定义处, 改这里即全部任务同步生效 ──
# $'..' 让 bash 把 \033 解释成 ESC 字节(颜色码本体, 不是字面反斜杠)
LOG_COLOR_INFO=$'\033[34m'   # 蓝: 进行中
LOG_COLOR_OK=$'\033[32m'     # 绿: 成功
LOG_COLOR_WARN=$'\033[33m'   # 黄: 可恢复失败
LOG_COLOR_ERR=$'\033[31m'    # 红: 不可恢复失败
LOG_COLOR_RESET=$'\033[0m'   # 复位: 必须跟在每次上色之后

LOG_TAG_INFO="[info]"
LOG_TAG_OK="[ok]"
LOG_TAG_WARN="[warn]"
LOG_TAG_ERR="[err]"

# 标签后的空格写在格式串里(不在颜色区间内), 用于把 4 种标签的正文对齐到同一列:
# [info]+2 / [ok]+4 / [warn]+2 / [err]+3 = 正文均从第 9 列开始
info() { printf '%s%s%s  %s\n' "$LOG_COLOR_INFO" "$LOG_TAG_INFO" "$LOG_COLOR_RESET" "$*"; }
ok()   { printf '%s%s%s    %s\n' "$LOG_COLOR_OK" "$LOG_TAG_OK" "$LOG_COLOR_RESET" "$*"; }
warn() { printf '%s%s%s  %s\n' "$LOG_COLOR_WARN" "$LOG_TAG_WARN" "$LOG_COLOR_RESET" "$*"; }
err()  { printf '%s%s%s   %s\n' "$LOG_COLOR_ERR" "$LOG_TAG_ERR" "$LOG_COLOR_RESET" "$*"; }
