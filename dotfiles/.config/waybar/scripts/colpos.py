#!/usr/bin/env python3
"""waybar center module — column indicator blocks only.

Data source: niri IPC (`niri msg`). niri reports every tiled window's position in
the workspace's scrolling layout as

    layout.pos_in_scrolling_layout = [column, tile-in-column]

both 1-based (leftmost column = 1, topmost tile in column = 1).

Display: 每列一个**等宽**的色块，只有颜色区分 —— 当前列绿色、其余灰色。
宽度是唯一个常量（BLOCK_WIDTH），换列 / 增删窗口都不会改变任何块的宽度。
无平铺焦点窗口 -> 空文本，由 hide-empty-text 隐藏。

设置项（modules.json 的 exec 里传参）:
    --tooltip-window-title / --no-tooltip-window-title
        悬浮弹窗里除了「当前列 / 总列数」，再在下面一行显示当前聚焦窗口的名字
        （窗口标题，标题为空时退回 app_id）。默认关闭。
"""

import argparse
import json
import subprocess
import time
from xml.sax.saxutils import escape as escape_xml

BLOCK_WIDTH = 24  # 每列的块宽（空格数 = px）——所有列等宽，宽度永不变化
BLOCK_SIZE = "15%"  # 字号：15% 下每个空格 advance = 1px，所以块宽(px) == 空格数
COLOR_CURRENT = "#a7c080"  # accent green (matches workspaces active bar)
COLOR_PAST = "#7a8478"  # dim gray (past AND future columns)

_last_text = None
_last_tooltip = None
_focused_id = None  # single source of truth: id of the focused window
_show_window_title = False  # --tooltip-window-title，main() 里按参数设置


def parse_args():
    parser = argparse.ArgumentParser(description="waybar 中心列指示器（custom/colpos）")
    parser.add_argument(
        "--tooltip-window-title",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="tooltip 的数字下方再显示当前聚焦窗口的名字（标题，标题为空时用 app_id）",
    )
    return parser.parse_args()


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


def escape_pango_markup(text):
    """窗口标题是外部输入，而 waybar 用 set_tooltip_markup 渲染 tooltip：
    不转义 & < > 会让整条 tooltip 解析失败（悬停什么都看不到）。
    顺带压成一行（去掉控制字符和换行），保证布局就是「数字一行 + 名字一行」。"""
    one_line = "".join(c for c in text if c >= " " and c != "\x7f")
    return escape_xml(one_line)


def window_display_name(win):
    """当前聚焦窗口的名字：标题优先，标题为空时退回 app_id。"""
    if win is None:
        return ""
    name = (win.get("title") or "").strip() or (win.get("app_id") or "").strip()
    return escape_pango_markup(name)


def render_segments(col, total_cols):
    """每列一个**等宽**的色块，只有颜色区分：当前列绿色、其余灰色。

    宽度是唯一一个常量（BLOCK_WIDTH = 24px），不随列数、不随位置变化。于是：
      - 换列时**任何块的边缘都不移动**，只有两个块的颜色互换 —— 观感是"标记挪了
        一格"，而不是"某块胀大吞掉了旁边"（宽度不一时就会读成后者）；
      - 增删窗口时已有块一动不动，只是多一个或少一个块。

    也试过并放弃的方案（留个记录，别再走一遍）：
      - 当前列加宽（1.7 倍、1.3 倍都试过）：宽度差本身就会带来"吞并/滑动"观感，
        且未选中块宽一旦随列数变化（早期实现的 bug），加减窗口时满行都在跳；
      - "背景矩形 + 提高字号"做高矮差：Pango 会把同一行里所有 run 的背景矩形
        拉齐到行高，15%/25% 渲染出来一样高（实测像素扫描都是 8px）；
      - 字形墨迹做粗细差（▂ 细线 vs █ 厚块）：能做出真粗细差，但观感不佳。

    不在这里做任何截断：全部列都渲染，可见多少列、在哪截断、
    省略号的位置完全由 waybar/GTK 依实际布局决定（碰撞点省略）。"""
    out = []
    for i in range(1, total_cols + 1):
        color = COLOR_CURRENT if i == col else COLOR_PAST
        out.append(f"<span background='{color}' size='{BLOCK_SIZE}'>{' ' * BLOCK_WIDTH}</span>")

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
        if _show_window_title:
            name = window_display_name(win)
            if name:
                tooltip = f"{tooltip}\n{name}"

    if (text, tooltip) == (_last_text, _last_tooltip):
        return
    _last_text = text
    _last_tooltip = tooltip
    print(json.dumps({"text": text, "tooltip": tooltip}), flush=True)


def main():
    global _show_window_title
    _show_window_title = parse_args().tooltip_window_title
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
