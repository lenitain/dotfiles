#!/bin/bash
# 限制 cliphist 历史记录为 100 条

limit=100

# 获取当前条目数
count=$(cliphist list | wc -l)

if [ "$count" -gt "$limit" ]; then
    # 删除旧的条目，只保留最新的 100 条
    # cliphist list 输出最新的记录在最前面，所以需要删除多余的条目
    # 计算 需要删除的条目数，使用tail获取需要删除的最老记录
    cliphist list | tail -n $((count - limit)) | cliphist delete
fi
