#!/usr/bin/env python3
"""Focused workspace's column titles -> one Waybar custom module.

niri's event stream is the only title input; one JSON line goes to stdout per
change. niri replays the full state on connect, so the titles themselves are
never polled and nothing is written to disk.

宽度策略：撞到右簇时从最长的那列开始压，不是按比例缩，也不是整行末尾一刀切。
- 每列标题先用 Pango 量出像素宽；
- 只维护一个数：右簇左边界（右簇里最左那枚胶囊 = 托盘的左沿）；
  可用宽度 = 这个边界 - 工作区胶囊 - 标题胶囊自己的 padding/margin。
  边界 = 屏宽 - 右簇总宽，每个输出只在第一次渲染时整簇采样一次，之后沿用同一个
  数 —— 不给簇里每个模块各设一套刷新节奏。采样之后簇里的变化（托盘增减一枚
  45px、静音约 50px，电池/音量/时钟 ±20px）不再追，交给 GTK 的 ellipsize 兜底。
- 总宽超过可用宽度时取一个统一上限 L：最长的先降到和次长一样，追平后两列
  一起降，再追平第三长时三列一起降 —— 等价于把所有超过 L 的列都压到 L，
  L 取到「总宽刚好放得下」为止；原来就短于 L 的列完全不动。
  L 一直降到放得下为止，只有降到某列自身宽度以下时，那一列才跟着变短。
- modules.json 里的 max-length（GTK ellipsize）只当兜底：预算估偏时最多再把
  行尾多截一点，不会出现整列被挤没。

采样只在第一次渲染（或换了输出）时发生：busctl 读 SNI watcher 的图标列表
（约 3ms），wpctl 读默认 sink 的音量/静音（约 12ms），都不起常驻进程、没有
定时器，跑起来之后不再碰任何外部进程。电池 capacity 只读一次（这台机器的 EC
读它偶尔要 80ms），屏宽按 output 缓存一次。
"""

import functools
import glob
import html
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime

ACTIVE_COLOR = "#d3c6aa"
INACTIVE_COLOR = "#859289"
# 列与列之间的分隔：一枚暗竖线。20px 空格和窗口标题自己的 " - " 一样宽，
# 读不出「这里换列了」。竖线取自 niri 的列概念，颜色在胶囊底上刚好可见。
# 竖线字形 advance 16px，两侧各留一枚 en space（8px）：列间总 32px，
# 竖线本身两边各 8px 空白，比普通空格（4px）松一档。
# 色值取自 .palette/everforest.md 的 dark medium：bg4 #4f585e
# （Everforest 里正好是「窗口分隔线」那一档）。
SEPARATOR_TEXT = "\u2002│\u2002"
TITLE_GAP = f"<span foreground='#4f585e'>{SEPARATOR_TEXT}</span>"

# ---------- 几何常量 ----------
# 全部对应 style.css / modules.json。改右簇或标题的字体、padding、margin 时
# 同步这里，否则预算会偏：偏大只会让胶囊离右簇多留几 px（GTK 会兜底），
# 偏小则行尾会被 GTK 多截一点。
# 前提：config 里靠 "no-center": true 取消中栏，左栏（工作区 + 标题）才真能长到
# 右簇左沿；否则 waybar 默认的 fixed-center 会把左栏卡在一半屏宽。
FONT_FAMILY = "Noto Sans,Maple Mono NL NF CN"
FONT_SIZE_PX = 18
TITLE_WEIGHT = 500
WORKSPACE_WEIGHT = 700
TITLE_PADDING_X = 16      # #custom-coltitles padding: 1px 16px
TITLE_MARGIN = 4          # 胶囊 margin: 4px（右侧那份算进 RIGHT_GAPS_PX）
WORKSPACE_BTN_PX = 40     # #workspaces button min-width
WORKSPACE_MARGINS_PX = 12  # #workspaces margin: 左 8 + 右 4
TRAY_ICON_PX = 45         # 23px 图标 + 左右各 11px padding
IDLE_CAPSULE_PX = 45      # #custom-idle-inhibit 单图标胶囊（23 + 上下/左右 padding）
BATTERY_ICON_PX = 11      # format-icons 五档与插头同宽
PULSE_ICON_PX = 11        # FA 扬声器字形在 18px 下约 11px
BATTERY_PADDING_X = 12    # #battery padding: 1px 12px
PULSE_PADDING_X = 12      # #pulseaudio padding: 1px 12px
CLOCK_PADDING_X = 13      # #clock padding: 1px 13px
# 标题胶囊右沿到屏幕右沿之间的固定间距：标题右 margin 4 + 托盘左 margin 4
# + 5 个 8px 的小间隙（托盘→抑制→电池→音量→时钟 各 8，时钟右 margin 8）。
RIGHT_GAPS_PX = 48
MIN_COLUMN_PX = 48        # 统一上限最低压到这么宽（约「…」+ 2 个汉字）

WEEKDAYS = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

_layouts = {}
_last = None

_width_cache = {"output": None, "width": None}

# 边界采样：整簇一次算完，每个输出只采一次（换输出才重采）。簇里只有托盘数和
# 音量/静音需要问系统，读失败时沿用上次的值 —— 一次查询没成功不该让边界整档跳偏。
_edge_cache = {"output": None, "edge": None}
_tray = {"count": 1}
_pulse = {"muted": False, "volume": None}
_battery_cache = {"done": False, "capacity": None}


def _layout(weight):
    """Pango layout with the same font/size/weight the bar renders with."""
    if weight not in _layouts:
        import gi

        gi.require_version("Pango", "1.0")
        gi.require_version("PangoCairo", "1.0")
        from gi.repository import Pango, PangoCairo

        context = PangoCairo.FontMap.get_default().create_context()
        desc = Pango.FontDescription()
        desc.set_family(FONT_FAMILY)
        desc.set_weight(weight)
        desc.set_absolute_size(FONT_SIZE_PX * Pango.SCALE)
        layout = Pango.Layout(context)
        layout.set_font_description(desc)
        _layouts[weight] = layout
    return _layouts[weight]


@functools.lru_cache(maxsize=2048)
def _text_px(text, weight=TITLE_WEIGHT):
    layout = _layout(weight)
    layout.set_text(text, -1)
    return layout.get_pixel_size()[0]


@functools.lru_cache(maxsize=512)
def _fit_text(text, max_px, weight=TITLE_WEIGHT):
    """Longest prefix of `text` + … that still fits into `max_px`."""
    if _text_px(text, weight) <= max_px:
        return text
    ellipsis = "…"
    if _text_px(ellipsis, weight) > max_px:
        return ""

    best = ellipsis
    lo, hi = 0, len(text)
    while lo <= hi:
        mid = (lo + hi) // 2
        prefix = text[:mid].rstrip()
        candidate = f"{prefix}{ellipsis}" if prefix else ellipsis
        if _text_px(candidate, weight) <= max_px:
            best = candidate
            lo = mid + 1
        else:
            hi = mid - 1
    return best


def _level(widths, avail):
    """统一上限 L：sum(min(width, L)) == avail，短于 L 的列不受影响。"""
    ordered = sorted(widths)
    index = 0
    count = len(ordered)
    while index < count:
        level = avail / (count - index)
        if ordered[index] >= level:
            break
        avail -= ordered[index]
        index += 1
    return avail / (count - index)


def _fit_columns(titles, avail, gap_px):
    """撞到右边时削峰：最长的先缩，追平次长的就一起缩，以此类推。"""
    count = len(titles)
    widths = [_text_px(title) for title in titles]
    text_avail = avail - gap_px * (count - 1)
    if text_avail <= 0:
        return ["" for _ in titles]
    if sum(widths) <= text_avail:
        return titles

    level = max(_level(widths, text_avail), MIN_COLUMN_PX)
    fitted = [
        _fit_text(title, min(width, level))
        for title, width in zip(titles, widths)
    ]

    # 按字符截断会有取整损失：把统一上限整体抬一点点，让被压的列一起长，
    # 保持「同一高度」，也让胶囊尽量贴到右簇。
    for _ in range(8):
        used = sum(_text_px(text) for text in fitted)
        slack = text_avail - used
        if slack < 1:
            break
        capped = [i for i, width in enumerate(widths) if width > level]
        if not capped:
            break
        candidate_level = level + slack / len(capped)
        candidate = [
            _fit_text(title, min(width, candidate_level))
            for title, width in zip(titles, widths)
        ]
        if sum(_text_px(text) for text in candidate) > text_avail:
            break
        level = candidate_level
        fitted = candidate
    return fitted


def _bar_width(output):
    """Logical width of the output this bar lives on (niri owns the number)."""
    if not output:
        return None
    if _width_cache["output"] == output and _width_cache["width"]:
        return _width_cache["width"]

    width = None
    try:
        result = subprocess.run(
            ["niri", "msg", "--json", "outputs"],
            capture_output=True,
            check=False,
            text=True,
            timeout=2,
        )
        outputs = json.loads(result.stdout)
        logical = (outputs.get(output) or {}).get("logical") or {}
        width = int(logical["width"]) if logical.get("width") else None
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        width = None

    # 失败不记：读不到屏宽就没有预算可用，下一次渲染再问一遍（niri 挂了这个模块
    # 本来也没用，重试反而能自愈）。
    if width:
        _width_cache.update(output=output, width=width)
    return width


def _sample_tray():
    """数一遍 SNI watcher 里注册的图标（waybar 的托盘胶囊按枚算 45px）。"""
    try:
        out = subprocess.run(
            [
                "busctl", "--user", "get-property",
                "org.kde.StatusNotifierWatcher",
                "/StatusNotifierWatcher",
                "org.kde.StatusNotifierWatcher",
                "RegisteredStatusNotifierItems",
            ],
            capture_output=True,
            check=False,
            text=True,
            timeout=1,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return

    match = re.match(r"\s*as\s+(\d+)", out)  # busctl: `as 2 ":1.42/a" ":1.43/b"`
    if match:
        _tray["count"] = int(match.group(1))


def _sample_pulse():
    """默认 sink 的音量与静音（对应 {volume}% 和 format-muted）。"""
    try:
        out = subprocess.run(
            ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
            capture_output=True,
            check=False,
            text=True,
            timeout=1,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return

    match = re.search(r"Volume:\s*([\d.]+)", out)  # wpctl: `Volume: 0.60 [MUTED]`
    if match:
        _pulse["muted"] = "[MUTED]" in out
        _pulse["volume"] = round(float(match.group(1)) * 100)


def _battery_capacity():
    """电池百分比：只读一次。

    这台机器的 EC 读 capacity 偶尔要 80ms，更别说它一分钟也变不了几格。
    """
    if not _battery_cache["done"]:
        capacity = None
        paths = glob.glob("/sys/class/power_supply/BAT*/capacity")
        if paths:
            capacity = 100
            try:
                with open(paths[0], encoding="ascii") as handle:
                    capacity = int(handle.read().strip())
            except (OSError, ValueError):
                pass
        _battery_cache.update(done=True, capacity=capacity)
    return _battery_cache["capacity"]


def _battery_capsule_px():
    capacity = _battery_capacity()
    if capacity is None:
        return 0  # 无电池时 waybar 的 battery 模块不显示
    return 2 * BATTERY_PADDING_X + _text_px(f"{capacity}% ") + BATTERY_ICON_PX


def _pulse_capsule_px():
    if _pulse["muted"]:
        return 2 * PULSE_PADDING_X + PULSE_ICON_PX  # format-muted 只留图标
    shown = 100 if _pulse["volume"] is None else _pulse["volume"]
    return 2 * PULSE_PADDING_X + _text_px(f"{shown}% ") + PULSE_ICON_PX


def _clock_capsule_px():
    now = datetime.now()
    date = f"{now.month}-{now.day} {WEEKDAYS[now.weekday()]} {now.hour:02d}:{now.minute:02d}"
    return 2 * CLOCK_PADDING_X + _text_px(date)


def _workspaces_px(state, output):
    total = 0
    for workspace in state["workspaces"].values():
        if workspace.get("output") != output:
            continue
        label = workspace.get("name") or str(workspace.get("idx", ""))
        total += max(WORKSPACE_BTN_PX, _text_px(label, WORKSPACE_WEIGHT))
    return total + WORKSPACE_MARGINS_PX


def _right_cluster_px():
    """右簇总宽：托盘 + idle + 电池 + 音量 + 时钟，外加固定间隙。

    系统状态只在这里读：一次采样就是整簇的一次快照。
    """
    _sample_tray()
    _sample_pulse()
    return (
        RIGHT_GAPS_PX
        + TRAY_ICON_PX * _tray["count"]
        + IDLE_CAPSULE_PX
        + _battery_capsule_px()
        + _pulse_capsule_px()
        + _clock_capsule_px()
    )


def _right_edge_px(output):
    """右簇左边界：右簇里最左那枚胶囊（托盘）的左沿，距屏幕左沿多少 px。

    标题的右端就顶在这儿 —— 它是「标题最多能用到哪儿」的那一个数。
    整簇每个输出只采一次样，之后的模块变化由 GTK 的 ellipsize 兜底。
    """
    width = _bar_width(output)
    if not width:
        return None

    if _edge_cache["output"] == output:
        return _edge_cache["edge"]

    edge = width - _right_cluster_px()
    _edge_cache.update(output=output, edge=edge)
    return edge


def _available_text_px(state):
    """Width the title module may use before it runs into the right cluster."""
    output = os.environ.get("WAYBAR_OUTPUT_NAME", "")
    if not output:
        workspace = focused_workspace(state["workspaces"])
        output = (workspace or {}).get("output", "")
    edge = _right_edge_px(output)
    if edge is None:
        return None
    return (
        edge
        - _workspaces_px(state, output)
        - TITLE_MARGIN
        - 2 * TITLE_PADDING_X
    )


def new_state():
    return {
        "windows": {},
        "workspaces": {},
        "overview": False,
        "seq": 0,
        "windows_ready": False,
        "workspaces_ready": False,
    }


def column_of(win):
    layout = (win or {}).get("layout") or {}
    pos = layout.get("pos_in_scrolling_layout")
    return pos[0] if pos is not None else None


def tile_of(win):
    pos = (win.get("layout") or {}).get("pos_in_scrolling_layout")
    return pos[1] if pos is not None else 99


def focus_time(win):
    ts = win.get("focus_timestamp") or {}
    return (ts.get("secs", 0), ts.get("nanos", 0))


def focused_window(wins):
    return next((w for w in wins.values() if w.get("is_focused")), None)


def focused_workspace(workspaces):
    return next((w for w in workspaces.values() if w.get("is_focused")), None)


def active_window(state):
    if state["overview"]:
        ws = focused_workspace(state["workspaces"])
        if ws is None:
            return None
        wid = ws.get("active_window_id")
        return state["windows"].get(wid) if wid is not None else None
    return focused_window(state["windows"])


def apply_focus(wins, focused_id):
    for win in wins.values():
        win["is_focused"] = win["id"] == focused_id


def mark_focused(wins, state, wid):
    win = wins.get(wid)
    if win is not None:
        state["seq"] += 1
        win["_seq"] = state["seq"]


def rank_windows(wins):
    for rank, win in enumerate(sorted(wins.values(), key=focus_time), 1):
        win["_seq"] = rank
    return len(wins)


def normalize_title(win):
    text = win.get("title") or win.get("app_id") or "untitled"
    return " ".join(str(text).split()) or "untitled"


def workspace_columns(wins, ws_id):
    columns = {}
    for win in wins.values():
        if win.get("workspace_id") != ws_id:
            continue
        col = column_of(win)
        if col is not None:
            columns.setdefault(col, []).append(win)
    return columns


def pick_window(wins):
    return max(wins, key=lambda w: (w.get("_seq", 0), -tile_of(w)))


def render(state):
    ws = focused_workspace(state["workspaces"])
    if ws is None:
        return None

    columns = workspace_columns(state["windows"], ws["id"])
    if not columns:
        return None

    active = active_window(state)
    active_col = None
    if active is not None and active.get("workspace_id") == ws["id"]:
        active_col = column_of(active)

    cols = sorted(columns)
    titles = []
    colors = []
    for col in cols:
        win = pick_window(columns[col])
        if col == active_col:
            win = active
        titles.append(normalize_title(win))
        colors.append(ACTIVE_COLOR if col == active_col else INACTIVE_COLOR)

    avail = _available_text_px(state)
    shown = titles if avail is None else _fit_columns(titles, avail, _text_px(SEPARATOR_TEXT))

    spans = [
        f"<span foreground='{color}'>{html.escape(title, quote=False)}</span>"
        for title, color in zip(shown, colors)
    ]
    lines = []
    for col, title in zip(cols, titles):
        suffix = " (当前)" if col == active_col else ""
        lines.append(f"{col}. {html.escape(title, quote=False)}{suffix}")

    total = len(cols)
    header = (
        f"第 {active_col} 列 / 共 {total} 列"
        if active_col is not None
        else f"共 {total} 列"
    )
    return TITLE_GAP.join(spans), "\n".join([header, *lines])


def emit(state):
    global _last
    if not (state["windows_ready"] and state["workspaces_ready"]):
        return

    rendered = render(state)
    text, tooltip = rendered if rendered else ("", "")
    if (text, tooltip) == _last:
        return
    _last = (text, tooltip)

    line = json.dumps({"text": text, "tooltip": tooltip}, ensure_ascii=False) + "\n"
    try:
        sys.stdout.buffer.write(line.encode())
        sys.stdout.buffer.flush()
    except BrokenPipeError:
        sys.exit(0)


def handle(ev, state):
    wins = state["windows"]

    if "OverviewOpenedOrClosed" in ev:
        state["overview"] = ev["OverviewOpenedOrClosed"]["is_open"]
    elif "WorkspacesChanged" in ev:
        state["workspaces"] = {
            ws["id"]: ws for ws in ev["WorkspacesChanged"]["workspaces"]
        }
        state["workspaces_ready"] = True
    elif "WorkspaceActivated" in ev:
        data = ev["WorkspaceActivated"]
        if not data["focused"]:
            return
        for ws in state["workspaces"].values():
            ws["is_focused"] = ws["id"] == data["id"]
    elif "WorkspaceActiveWindowChanged" in ev:
        data = ev["WorkspaceActiveWindowChanged"]
        ws = state["workspaces"].get(data["workspace_id"])
        if ws is not None:
            ws["active_window_id"] = data["active_window_id"]
    elif "WindowFocusChanged" in ev:
        wid = ev["WindowFocusChanged"].get("id")
        apply_focus(wins, wid)
        if wid is not None:
            mark_focused(wins, state, wid)
    elif "WindowOpenedOrChanged" in ev:
        win = ev["WindowOpenedOrChanged"]["window"]
        old = wins.get(win["id"])
        win["_seq"] = old.get("_seq", 0) if old else 0
        wins[win["id"]] = win
        if win.get("is_focused"):
            apply_focus(wins, win["id"])
            mark_focused(wins, state, win["id"])
    elif "WindowLayoutsChanged" in ev:
        for wid, layout in ev["WindowLayoutsChanged"]["changes"]:
            if wid in wins:
                wins[wid]["layout"] = layout
    elif "WindowsChanged" in ev:
        wins.clear()
        wins.update({w["id"]: w for w in ev["WindowsChanged"]["windows"]})
        state["seq"] = rank_windows(wins)
        current = focused_window(wins)
        if current is not None:
            mark_focused(wins, state, current["id"])
        state["windows_ready"] = True
    elif "WindowClosed" in ev:
        wins.pop(ev["WindowClosed"].get("id"), None)
    else:
        return

    emit(state)


def main():
    while True:
        state = new_state()
        try:
            proc = subprocess.Popen(
                ["niri", "msg", "--json", "event-stream"],
                stdout=subprocess.PIPE,
                text=True,
                bufsize=1,
            )
        except OSError:
            time.sleep(1)
            continue

        assert proc.stdout is not None
        for line in proc.stdout:
            try:
                ev = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(ev, dict):
                handle(ev, state)
        proc.wait()
        time.sleep(1)


if __name__ == "__main__":
    main()
