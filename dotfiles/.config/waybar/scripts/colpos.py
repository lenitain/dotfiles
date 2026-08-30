#!/usr/bin/env python3
"""waybar module: current column of the focused window inside its workspace.

Data source: niri IPC (`niri msg`). niri reports every tiled window's position in
the workspace's scrolling layout as

    layout.pos_in_scrolling_layout = [column, tile-in-column]

both 1-based (leftmost column = 1, topmost tile in column = 1).

Display: 每列一个纯色像素块（Unicode 块元素字符，非字形/非SVG），
当前列绿色、其余灰色，像 workspaces 的指示条一样：
    ▂▂ ▂▂ ▂▂

实现：custom 文本模块，常驻进程订阅 niri 事件流 -> 事件驱动、零进程 spawn、
零栅格化、无卡顿。块元素为 Maple 原生字形（无需字体覆写）。
22px 行高 = 原 Maple 22px -> bar 严格 36px 不撑。
无平铺焦点窗口 -> hide-empty-text 隐藏。
"""

import json
import os
import subprocess
import sys
import time

# 每列一个像素块。想捏形状：▁▁▁(40x5 细条) ▂▂(27x8 平块) ▃▃(27x12) ▄▄(27x15) █(满高)
# ▁▂▃▄▅▇█ 都是 Maple 原生块元素，画出来就是纯色矩形（像素块）。
FILL = "▁▁"
COLOR_CURRENT = "#a7c080"  # accent green (matches workspaces active bar)
COLOR_PAST = "#7a8478"  # dim gray (past AND future columns)

_last_text = None
_last_tooltip = None
_focused_id = None  # single source of truth: id of the focused window


def niri_windows():
    out = subprocess.run(
        ["niri", "msg", "--json", "windows"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    return {w["id"]: w for w in json.loads(out)}


def pos_of(win):
    """Return column number for a tiled window, or None if it has no column."""
    if win is None:
        return None
    layout = win.get("layout") or {}
    pos = layout.get("pos_in_scrolling_layout")
    if pos is None:
        return None
    return pos[0]


def workspace_stats(wins, ws_id):
    """Total columns in a workspace, from the window list."""
    if ws_id is None:
        return None
    cols = set()
    for w in wins.values():
        if w.get("workspace_id") != ws_id:
            continue
        col = pos_of(w)
        if col is None:
            continue
        cols.add(col)
    return len(cols)


def note_focus(wins, wid):
    global _focused_id
    _focused_id = wid
    for w in wins.values():
        w["is_focused"] = w["id"] == wid
    return wins.get(wid)


def focused_window(wins):
    return next((w for w in wins.values() if w.get("is_focused")), None)


def render_segments(col, total_cols):
    """每列一个等大像素块；当前列绿色高亮。"""
    out = []
    for i in range(1, total_cols + 1):
        color = COLOR_CURRENT if i == col else COLOR_PAST
        out.append(f"<span foreground='{color}'>{FILL}</span>")
    gap = "<span size='70%'> </span>"  # 段间隙；不能 >100% 否则顶破行高
    return gap.join(out)


def emit(win, wins):
    global _last_text, _last_tooltip
    col = pos_of(win)
    ws_id = win.get("workspace_id") if win else None
    total_cols = workspace_stats(wins, ws_id)

    if win is None or col is None:
        text = ""
        tooltip = ""
    else:
        total = total_cols if total_cols else 1
        text = render_segments(col, total)
        tooltip = f"{col} / {total}"

    if (text, tooltip) == (_last_text, _last_tooltip):
        return
    _last_text = text
    _last_tooltip = tooltip
    print(json.dumps({"text": text, "tooltip": tooltip}), flush=True)


def main():
    wins = niri_windows()

    # 初始全量查询的 is_focused 是准的，播种 _focused_id
    fw = focused_window(wins)
    emit(note_focus(wins, fw["id"] if fw else None), wins)

    # 主事件循环：niri 事件流（事件驱动，常驻进程，零 spawn）
    while True:
        proc = subprocess.Popen(
            ["niri", "msg", "--json", "event-stream"],
            stdout=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
        assert proc.stdout is not None
        for line in proc.stdout:
            try:
                ev = json.loads(line)
            except json.JSONDecodeError:
                continue
            if "WindowFocusChanged" in ev:
                wid = ev["WindowFocusChanged"].get("id")
                emit(note_focus(wins, wid), wins)
            elif "WindowOpenedOrChanged" in ev:
                w = ev["WindowOpenedOrChanged"]["window"]
                wins[w["id"]] = w
                # 新窗口若获得焦点则更新真相；否则保持既有 _focused_id。
                # 不用 focused_window(wins) 扫 is_focused 标志（缓存里会过期）。
                if w.get("is_focused"):
                    note_focus(wins, w["id"])
                emit(wins.get(_focused_id), wins)
            elif "WindowLayoutsChanged" in ev:
                for wid, layout in ev["WindowLayoutsChanged"]["changes"]:
                    if wid in wins:
                        wins[wid]["layout"] = layout
                emit(wins.get(_focused_id), wins)
            elif "WindowsChanged" in ev:
                wins.clear()
                wins.update({w["id"]: w for w in ev["WindowsChanged"]["windows"]})
                fw = focused_window(wins)
                emit(note_focus(wins, fw["id"] if fw else None), wins)
            elif "WindowClosed" in ev:
                wins.pop(ev["WindowClosed"].get("id"), None)
                emit(wins.get(_focused_id), wins)
        proc.wait()
        # 断线期间可能有窗口/焦点变化被漏掉，全量重查补上（恢复兜底，非轮询）
        try:
            fresh = niri_windows()
            wins.clear()
            wins.update(fresh)
            fw = focused_window(wins)
            emit(note_focus(wins, fw["id"] if fw else None), wins)
        except Exception:
            pass
        time.sleep(1)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"text": "", "tooltip": f"colpos error: {e}"}), flush=True)
        raise
