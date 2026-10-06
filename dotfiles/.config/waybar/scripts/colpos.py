#!/usr/bin/env python3
"""waybar 左侧模块 — 列指示器（每列一个等宽色块，只表达列）。

Data source: niri IPC (`niri msg`). niri reports every tiled window's position in
the workspace's scrolling layout as

    layout.pos_in_scrolling_layout = [column, tile-in-column]

both 1-based (leftmost column = 1, topmost tile in column = 1).

Display: 每列一个圆点，当前列**绿色**、其余灰色，字号全部一样（DOT_PX 写死成整数 px）。
间距是唯一个常量（DOT_ADVANCE），增删窗口不会改变任何点的位置；换列只是绿色挪一格。
无平铺窗口 -> 空文本，由 hide-empty-text 隐藏。

Anchor（"当前"指哪个窗口）：
    正常模式 = 聚焦窗口，即窗口表里的 is_focused 标志（焦点的唯一表述，不另存 id）。
    overview = 聚焦工作区的活动窗口 active_window_id（见 overview_window）。niri 打开
               overview 时会把**窗口**焦点清成 None，靠聚焦窗口定位会让指示器整块消失；
               活动窗口是另一个实时字段，所以 overview 里高亮/切到哪个工作区、按 ←/→
               换到哪一列，指示器就跟到哪里，显示的是实时布局而非快照。
               高亮到没有平铺窗口的工作区 -> 同样空文本（和正常模式在空工作区上一致）。

State（本模块订阅的三个 part，见 new_state）：
    windows / workspaces / overview_open。快照由 niri 在连上 event-stream 时重放，
    增量由 handle_niri_event 里对应的事件维护 —— 启动和断线重连都不需要自己查询。
"""

import json
import subprocess
import time

DOT = "●"  # BLACK CIRCLE — 实心圆，颜色画在字形墨迹上（不是 background）

# ── 字号：全部写死成整数 px，不用 Pango 的 large/x-large 关键字（那俩是隐式 ×1.2 阶梯，
#    定义在 pango-font.h:308，容易看迷糊）。DOT_PX 由 markup 直接盖掉 CSS 字号，与 style.css
#    无关；FONT_PX 只是记着 CSS 基准字号，改 style.css 时同步改它。
FONT_PX = 16  # 基准字号 = style.css:82 #custom-colpos 的 font-size（必须与它一致）
DOT_PX = 20  # 圆点字号，选中/未选中同值（选中只换颜色）；● 墨迹直径 ≈ 15px（不撑大 28px 的 bar）
LINE_HEIGHT = 0.85  # 行高倍率（无量纲，只能是小数）：压住 22px 圆点撑高的行盒，bar 才停在 28px 地板

GAP_PX = 4  # 点与点之间的空隙再额外加多少 px（加在空格的 letter_spacing 上）。
# 空格自身 ≈ 6px，所以现在点间净空 ≈ 6 + GAP_PX ≈ 12px；嫌太挤就调这一个数。

DOT_ADVANCE = " "  # 单个空格（字号同 DOT_PX）→ 点间距是唯一定值
COLOR_CURRENT = "#a7c080"  # accent green (matches workspaces active bar)
COLOR_PAST = "#7a8478"  # dim gray (past AND future columns)


def _size(px):
    """px → Pango markup 的 size 值。size 单位是 1/1024 pt，96dpi 下 1px = 0.75pt = 768。

    例：16px → 12288，22px → 16896（等价于旧写法 size='large' / 'x-large'）。
    """
    return int(round(px * 768))


def _letter_spacing(px):
    """px → Pango markup 的 letter_spacing 值。

    注意它和 size 的单位**不一致**：size/rise 是 768 单位/px，letter_spacing 实测是
    1024 单位/px（本机 Pango 1.58 + GTK3，标定见注释：0/768/1024/2048/6144 → 位移
    0/0/1/2/6px）。以实测为准，别套 _size 的系数。
    """
    return int(round(px * 1024))


# 已输出的内容。初值 = 模块在 waybar 里的初始显示状态（空文本、被 hide-empty-text 藏着），
# 于是启动时那次"算出来是空"的结果会被去重掉，不会白打一行 JSON。
_last_text = ""
_last_tooltip = ""


def new_state():
    """本模块订阅的 niri 状态：只用得到的三个 part，字段名贴着协议（EventStreamState）。

    windows       = 窗口表（id -> Window），带 layout.pos_in_scrolling_layout 与 is_focused
    workspaces    = 工作区表（id -> Workspace），带 is_focused 与 active_window_id
    overview_open = overview 是否打开

    每个 part 只有一个维护者（handle_niri_event 里对应的事件），渲染只读、从不写。
    """
    return {"windows": {}, "workspaces": {}, "overview_open": False}


def pos_of(win):
    """窗口所在列号；没有列（浮动窗口 / 窗口不存在）时 None。"""
    if win is None:
        return None
    layout = win.get("layout") or {}
    pos = layout.get("pos_in_scrolling_layout")
    if pos is None:
        return None
    return pos[0]


def workspace_column_count(wins, ws_id):
    """工作区里有几列（由窗口表里的列号去重数出）；没有工作区时 None。"""
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


def apply_focus(wins, focused_id):
    """把焦点落到窗口表：is_focused 就是焦点唯一的表述，不再另存一个 id 变量。

    niri 的 WindowFocusChanged 语义正是「这个 id 的窗口聚焦、其余都不聚焦」，
    id 为 None 即没有任何窗口聚焦 —— 照抄即可，不用自己推。
    """
    for w in wins.values():
        w["is_focused"] = w["id"] == focused_id


def focused_window(wins):
    return next((w for w in wins.values() if w.get("is_focused")), None)


def focused_workspace(workspaces):
    """当前聚焦的工作区；overview 打开时它就是高亮（下一次会进入）的那个工作区。

    只认 is_focused：多显示器下每个输出各有一个 is_active 工作区，但全局只有一个是
    is_focused；实测 overview 里切工作区时 is_focused 跟着搬、is_active 不动。
    """
    return next((ws for ws in workspaces.values() if ws.get("is_focused")), None)


def overview_window(state):
    """overview 打开时用来定位列的窗口：聚焦工作区的活动窗口（active_window_id）。

    niri 打开 overview 会把**窗口**焦点清成 None（WindowFocusChanged{id:null}，所有窗口
    is_focused=false），所以聚焦窗口不能再当锚点（那正是指示器整块消失的原因）。但工作区的
    active_window_id 照常实时维护，语义就是「焦点回到这个工作区时落在哪个窗口」——
    overview 里按 ←/→ 换列、按 ↑/↓ 换工作区（overview 的硬编码键）都会更新它。
    于是指示器在 overview 里跟着高亮的工作区/列走，读到的是当前值，不是进 overview 前的快照。

    高亮的工作区没有平铺窗口（没窗口，或活动窗口是浮动窗）-> None -> 空文本。
    """
    ws = focused_workspace(state["workspaces"])
    if ws is None:
        return None
    active_id = ws.get("active_window_id")
    return state["windows"].get(active_id) if active_id is not None else None


def render_segments(col, total_cols):
    """每列一个圆点，当前列绿色（COLOR_CURRENT）、其余灰色（COLOR_PAST），字号统一 DOT_PX。

    间距是唯一一个常量（DOT_ADVANCE = 1 个空格，字号同 DOT_PX），不随列数、不随位置
    变化。于是增删窗口时已有点一动不动，只是多一个或少一个点；换列只是绿色挪一格。
    所有 span 共用 size，写在最外层（子 span 只剩颜色），颜色变化不影响几何。

    之前是 background + 空格的「色块」做法（24 个空格 + 背景色 = 24×2.4px 的
    横杠）。改用 ● 字符 + 前景色：颜色画在字形墨迹上、形状就是字符本身的圆
    —— Pango 的 background 永远是矩形，做不出真正的圆。22px 字号的墨迹直径
    约 15px，在 28px 地板的 bar 里清晰但不撑边。

    也试过并放弃的方案（留个记录，别再走一遍）：
      - 当前列做大一号（字号差、加宽 1.7/1.3 倍都试过）：字号差要靠 rise 上移才共线，
        宽度差会带来"吞并/滑动"观感，且未选中块宽一旦随列数变化（早期实现的 bug），
        加减窗口时满行都在跳 —— 现在选中/未选中只差颜色，几何完全一致；
      - "背景矩形 + 提高字号"做高矮差：Pango 会把同一行里所有 run 的背景矩形
        拉齐到行高，15%/25% 渲染出来一样高（实测像素扫描都是 8px）；
      - 字形墨迹做粗细差（▂ 细线 vs █ 厚块）：能做出真粗细差，但观感不佳；
      - 用 ○（空心）做未选中、●（实心）做选中：和绿色实心 ● 共存不协调，
        视觉噪音比单纯「实心 + 颜色差」更大。

    不在这里做任何截断：全部列都渲染，可见多少列、在哪截断、
    省略号的位置完全由 waybar/GTK 依实际布局决定（碰撞点省略）。"""
    out = []
    for i in range(1, total_cols + 1):
        color = COLOR_CURRENT if i == col else COLOR_PAST
        out.append(f"<span color='{color}'>{DOT}</span>")

    gap = f"<span letter_spacing='{_letter_spacing(GAP_PX)}'>{DOT_ADVANCE}</span>"
    return f"<span size='{_size(DOT_PX)}' line_height='{LINE_HEIGHT}'>{gap.join(out)}</span>"


def emit(state):
    """渲染一次（去重后输出）。只读状态，从不修改它。

    聚焦窗口从窗口表的 is_focused 标志读；overview 打开时换成高亮工作区的活动窗口
    （见 overview_window）。
    """
    global _last_text, _last_tooltip
    win = (
        overview_window(state)
        if state["overview_open"]
        else focused_window(state["windows"])
    )
    col = pos_of(win)
    ws_id = win.get("workspace_id") if win else None
    total_cols = workspace_column_count(state["windows"], ws_id) or 1

    text = ""
    tooltip = ""
    if win is not None and col is not None:
        # 外层 span 带 size/line-height，每个点 span 只带前景色
        text = render_segments(col, total_cols)
        tooltip = f"{col} / {total_cols}"

    if (text, tooltip) == (_last_text, _last_tooltip):
        return
    _last_text = text
    _last_tooltip = tooltip
    print(json.dumps({"text": text, "tooltip": tooltip}), flush=True)


def handle_niri_event(ev, state):
    """把一条 niri event-stream 事件应用到 state，然后渲染一次。

    事件名就是 niri IPC 的 Event 变体名，直接查 `niri msg --json event-stream` 的输出即可。
    本模块只用得上这几个（其余如 KeyboardLayoutsChanged / ConfigLoaded / Casts* /
    ScreenshotCaptured / WindowUrgencyChanged 一概忽略）：
      OverviewOpenedOrClosed / WorkspacesChanged / WorkspaceActivated /
      WorkspaceActiveWindowChanged -> 决定「当前」是哪个窗口（见 overview_window）
      WindowFocusChanged / WindowOpenedOrChanged / WindowLayoutsChanged /
      WindowsChanged / WindowClosed          -> 决定窗口表和列数据

    每个分支只改状态；渲染只有末尾一个出口（不关心的事件提前 return，连渲染都省了）。
    """
    wins = state["windows"]
    if "OverviewOpenedOrClosed" in ev:
        state["overview_open"] = ev["OverviewOpenedOrClosed"]["is_open"]
    elif "WorkspacesChanged" in ev:
        # 连上 event-stream 时 niri 会重放完整状态，含工作区表的 active_window_id
        state["workspaces"] = {
            ws["id"]: ws for ws in ev["WorkspacesChanged"]["workspaces"]
        }
    elif "WorkspaceActivated" in ev:
        # 激活工作区，overview 里换高亮（鼠标点、硬编码方向键、IPC）走的就是这个事件。
        # 只维护 is_focused —— 本模块唯一的判定依据。is_active 是「某个输出上的活动
        # 工作区」，多显示器下同时有多个、且本模块用不到，就不往缓存里写，免得半真半假。
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
        apply_focus(wins, ev["WindowFocusChanged"].get("id"))
    elif "WindowOpenedOrChanged" in ev:
        w = ev["WindowOpenedOrChanged"]["window"]
        wins[w["id"]] = w
        # niri 文档：新窗口若带 is_focused，其它窗口都不再聚焦（库的 WindowsState::apply
        # 同样处理）；不带就保持既有标志不动。
        if w.get("is_focused"):
            apply_focus(wins, w["id"])
    elif "WindowLayoutsChanged" in ev:
        for wid, layout in ev["WindowLayoutsChanged"]["changes"]:
            if wid in wins:
                wins[wid]["layout"] = layout
    elif "WindowsChanged" in ev:
        # 快照里的 is_focused 就是焦点本身，不必再扫一遍做归一化
        wins.clear()
        wins.update({w["id"]: w for w in ev["WindowsChanged"]["windows"]})
    elif "WindowClosed" in ev:
        wins.pop(ev["WindowClosed"].get("id"), None)
    else:
        return
    emit(state)


def main():
    # 空表起步：连上 event-stream 的首帧就是 niri 重放的完整状态（含 overview 开关与焦点）
    state = new_state()

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
            handle_niri_event(ev, state)
        proc.wait()
        # 断线兜底不需要全量重查：重连时 niri 会重放完整状态（EventStreamState::replicate
        # 覆盖 windows / workspaces / overview，焦点又随窗口对象的 is_focused 一起回来），
        # 下一轮的首帧就自愈了。
        time.sleep(1)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"text": "", "tooltip": f"colpos error: {e}"}), flush=True)
        raise
