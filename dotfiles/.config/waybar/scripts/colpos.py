#!/usr/bin/env python3
"""waybar center module — column indicator blocks only.

Data source: niri IPC (`niri msg`). niri reports every tiled window's position in
the workspace's scrolling layout as

    layout.pos_in_scrolling_layout = [column, tile-in-column]

both 1-based (leftmost column = 1, topmost tile in column = 1).

Display: 每列一个纯色像素块，当前列绿色、其余灰色。
无平铺焦点窗口 -> 空文本，由 hide-empty-text 隐藏。
"""

import json
import subprocess
import time

FILL = "                        "
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
    """每列一个等大像素块；当前列绿色高亮。
    不在这里做任何截断：全部列都渲染，可见多少列、在哪截断、
    省略号的位置完全由 waybar/GTK 依实际布局决定（碰撞点省略）。"""
    indices = range(1, total_cols + 1)

    out = []
    for i in indices:
        color = COLOR_CURRENT if i == col else COLOR_PAST
        out.append(f"<span background='{color}'>{FILL}</span>")

    gap = "<span size='15%'>   </span>"
    return gap.join(out)


def emit(win, wins):
    global _last_text, _last_tooltip
    col = pos_of(win)
    ws_id = win.get("workspace_id") if win else None
    total_cols = workspace_stats(wins, ws_id)
    if not total_cols:
        total_cols = 1

    text = ""
    tooltip = ""
    if win is not None and col is not None:
        total = total_cols if total_cols else 1
        text = f"<span size='15%'>{render_segments(col, total)}</span>"
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
