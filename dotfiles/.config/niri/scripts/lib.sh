#!/bin/bash
# 截图 / 录屏 / OCR / 剪贴板共用的通知与复制逻辑。
# 只 source，不直接执行。

# 通知统一入口：summary, body, 可选图标。
# 调用方可能开了 set -e，通知失败不该把成功操作变成失败。
notify() {
    local -a args=()
    if [ -n "${3:-}" ]; then
        args+=("-i" "$3")
    fi
    notify-send "${args[@]}" "$1" "$2" 9>&- || true
}

# wl-copy 会 fork 后台进程持有剪贴板并继承调用者的 stdio。
# 不重定向会让 "$(script)" / pipeline 永久等待；9>&- 则避免它攥住 record 的单例锁。
copy_stream() {
    if ! wl-copy >/dev/null 2>&1 9>&-; then
        notify "复制失败" "无法写入剪贴板"
        return 1
    fi
}

copy_path() {
    printf '%s' "$1" | copy_stream
}
