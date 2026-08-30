#!/usr/bin/env python3
"""Focused workspace's column titles -> one Waybar custom module.

niri's event stream is the only input; one JSON line goes to stdout per change.
niri replays the full state on connect, so nothing is polled or queried.
"""

import functools
import html
import json
import subprocess
import sys
import time

ACTIVE_COLOR = "#d3c6aa"
INACTIVE_COLOR = "#859289"
# 列与列之间的分隔：一枚暗竖线。原来的 20px 空格和窗口标题自己的 " - " 一样宽，
# 所以读不出「这里换列了」。竖线取自 niri 的列概念，颜色在暗盘上刚好可见。
# 竖线字形 advance 16px，两侧各留一枚 en space（8px）：列间总 32px，
# 竖线本身两边各 8px 空白，比普通空格（4px）松一档。
TITLE_GAP = "<span foreground='#4f5b58'>\u2002│\u2002</span>"
MAX_TITLE_PX = 400
FONT = "Noto Sans,Maple Mono NL NF CN"
FONT_SIZE_PX = 16

_layout = None
_last = None


def _pango_layout():
    global _layout
    if _layout is None:
        import gi

        gi.require_version("Pango", "1.0")
        gi.require_version("PangoCairo", "1.0")
        from gi.repository import Pango, PangoCairo

        context = PangoCairo.FontMap.get_default().create_context()
        desc = Pango.FontDescription()
        desc.set_family(FONT)
        desc.set_weight(Pango.Weight.MEDIUM)
        desc.set_absolute_size(FONT_SIZE_PX * Pango.SCALE)
        _layout = Pango.Layout(context)
        _layout.set_font_description(desc)
    return _layout


@functools.lru_cache(maxsize=1024)
def _width(text):
    layout = _pango_layout()
    layout.set_text(text, -1)
    return layout.get_pixel_size()[0]


@functools.lru_cache(maxsize=256)
def fit_title(text):
    """Truncate to MAX_TITLE_PX of rendered text, not to a character count."""
    if _width(text) <= MAX_TITLE_PX:
        return text
    ellipsis = "…"
    if _width(ellipsis) > MAX_TITLE_PX:
        return ellipsis

    best = ellipsis
    lo, hi = 0, len(text)
    while lo <= hi:
        mid = (lo + hi) // 2
        prefix = text[:mid].rstrip()
        candidate = f"{prefix}{ellipsis}" if prefix else ellipsis
        if _width(candidate) <= MAX_TITLE_PX:
            best = candidate
            lo = mid + 1
        else:
            hi = mid - 1
    return best


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

    spans = []
    lines = []
    for col in sorted(columns):
        win = pick_window(columns[col])
        if col == active_col:
            win = active
        title = normalize_title(win)
        color = ACTIVE_COLOR if col == active_col else INACTIVE_COLOR
        spans.append(
            f"<span foreground='{color}'>"
            f"{html.escape(fit_title(title), quote=False)}</span>"
        )
        suffix = " (当前)" if col == active_col else ""
        lines.append(f"{col}. {html.escape(title, quote=False)}{suffix}")

    total = len(columns)
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
