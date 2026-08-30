# pyright: reportUndefinedVariable=false, reportAttributeAccessIssue=false
# ruff: noqa: F821
# qutebrowser 配置文件
config.load_autoconfig(False)

# ==================== Chromium 参数 ====================
# 禁用 GPU shader 磁盘缓存：GPUCache 是可再生缓存（每次启动会被 QtWebEngine 重写），
# 在 psd overlay 模式下会被整体 copy-up 进不可回收的内存（约 15MB）。
# 常驻实例（qb-server）只编译一次 shader，禁用后无感知。
c.qt.args = ["disable-gpu-shader-disk-cache"]
# 限制 HTTP 磁盘缓存上限（~/.cache/qutebrowser/webengine/Cache）：
# 默认无上限，视频分段会累积到数 GB。300MB 足够日常网页，视频冷数据更快被 LRU 淘汰。
c.content.cache.size = 320 * 1024 * 1024

# ==================== 会话：手动控制 ====================
c.session.default_name = ""  # 启动时不加载任何会话，永远开新页面
c.auto_save.session = False  # 退出时不自动保存会话
c.session.lazy_restore = False  # 不延迟加载恢复的标签页

# 源码里没有能关闭后台 _autosave 的配置项，这里直接从内部禁掉它的写入
import qutebrowser.misc.sessions as _sessions
import qutebrowser.mainwindow.statusbar.bar as _statusbar_bar
import qutebrowser.mainwindow.tabwidget as _tabwidget
from qutebrowser.qt.gui import QPainterPath, QColor, QPainter
from qutebrowser.qt.core import QRectF
from qutebrowser.qt.widgets import QStyle


def _noop_save_autosave(self):
    pass


_sessions.SessionManager._save_autosave = _noop_save_autosave

# ==================== 默认页面和搜索引擎 ====================
c.url.default_page = "about:blank"
c.url.start_pages = ["about:blank"]

c.url.searchengines = {
    "DEFAULT": "https://www.bing.com/search?q={}",
    "b": "https://www.bing.com/search?q={}",
    "g": "https://www.google.com/search?q={}",
    "ddg": "https://duckduckgo.com/?q={}",
}

# ==================== 字体：Noto Sans CJK SC（多层回退） ====================
font_family = [
    "Noto Sans CJK SC",
    "Noto Sans CJK TC",
    "Noto Sans CJK JP",
    "Noto Sans CJK KR",
    "Noto Sans CJK HK",
    "Source Han Sans SC",
    "Microsoft YaHei",
    "WenQuanYi Micro Hei",
    "PingFang SC",
    "Hiragino Sans GB",
    "SimHei",
    "Arial",
    "sans-serif",
]
c.fonts.default_size = "16pt"
c.fonts.default_family = font_family

# ==================== 网页字体：Noto（按语义分配，多层回退） ====================
_noto_sans = [
    "Noto Sans CJK SC",
    "Noto Sans CJK TC",
    "Noto Sans CJK JP",
    "Noto Sans CJK KR",
    "Noto Sans CJK HK",
    "Source Han Sans SC",
    "Microsoft YaHei",
    "WenQuanYi Micro Hei",
    "PingFang SC",
    "Hiragino Sans GB",
    "SimHei",
    "Arial",
    "sans-serif",
]
_noto_serif = [
    "Noto Serif CJK SC",
    "Noto Serif CJK TC",
    "Noto Serif CJK JP",
    "Noto Serif CJK KR",
    "Noto Serif CJK HK",
    "Source Han Serif SC",
    "SimSun",
    "STSong",
    "Noto Serif",
    "Times New Roman",
    "serif",
]
_noto_fixed = [
    "Noto Sans Mono",
    "Noto Sans CJK SC",
    "Noto Sans CJK TC",
    "Noto Sans CJK JP",
    "Source Han Sans SC",
    "WenQuanYi Micro Hei Mono",
    "Microsoft YaHei",
    "Courier New",
    "monospace",
]

c.fonts.web.family.standard = ", ".join(_noto_sans)
c.fonts.web.family.sans_serif = ", ".join(_noto_sans)
c.fonts.web.family.serif = ", ".join(_noto_serif)
c.fonts.web.family.fixed = ", ".join(_noto_fixed)
c.fonts.web.family.cursive = ", ".join(_noto_sans)  # 无 Noto CJK 草书，回退到无衬线
c.fonts.web.family.fantasy = ", ".join(_noto_sans)  # 无 Noto CJK 幻想，回退到无衬线

# ==================== 标签页：左侧显示 ====================
c.tabs.position = "left"
c.tabs.width = "3%"
c.tabs.title.format = "{audio}{index}: {current_title}"
c.tabs.title.format_pinned = "{audio}{index}: {current_title}"
c.tabs.indicator.width = 4
c.tabs.padding = {"top": 6, "bottom": 6, "left": 8, "right": 8}

# 下载
c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = False

# 隐私
c.content.cookies.accept = "no-3rdparty"
# javascript.clipboard 保持默认 'ask'：网页 JS 请求读写剪贴板时弹窗询问

# 广告拦截：双引擎（Brave 规则 + hosts），默认列表上追加中文规则
# ,b 对当前网站开关拦截（官方 FAQ 推荐做法，误伤时一键放行）
c.content.blocking.method = "both"
c.content.blocking.adblock.lists += [
    "https://easylist-downloads.adblockplus.org/easylistchina.txt"
]
# hosts 引擎默认源在 raw.githubusercontent.com（直连不可达），换 jsdelivr 镜像
c.content.blocking.hosts.lists = [
    "https://cdn.jsdelivr.net/gh/StevenBlack/hosts@master/hosts"
]
config.bind(
    ",b", "config-cycle -p -u *://{url:host}/* content.blocking.enabled true false"
)

# 快捷键
config.bind("J", "tab-next")
config.bind("K", "tab-prev")
config.unbind("f")  # 禁用 hint follow

# 外部编辑器：文本框内 <Ctrl+E>（默认键位 edit-text）调 nvim 编辑
c.editor.command = [
    "footclient",
    "-e",
    "nvim",
    "{file}",
    "-c",
    "normal {line}G{column0}l",
]

# ==================== Everforest Dark Medium 配色 ====================
# 参考 ~/palette.md

# 背景色 (palette1 - dark medium)
bg_dim = "#232A2E"
bg0 = "#2D353B"
bg1 = "#343F44"
bg2 = "#3D484D"
bg3 = "#475258"
bg4 = "#4F585E"
bg5 = "#56635f"
bg_visual = "#543A48"
bg_red = "#514045"
bg_yellow = "#4D4C43"
bg_green = "#425047"
bg_blue = "#3A515D"
bg_purple = "#4A444E"

# 前景色 (palette2 - dark)
fg = "#D3C6AA"
red = "#E67E80"
orange = "#E69875"
yellow = "#DBBC7F"
green = "#A7C080"
aqua = "#83C092"
blue = "#7FBBB3"
purple = "#D699B6"
grey0 = "#7A8478"
grey1 = "#859289"
grey2 = "#9DA9A0"

# 状态栏颜色
statusline1 = "#A7C080"
statusline2 = "#D3C6AA"
statusline3 = "#E67E80"

# 状态栏
c.colors.statusbar.normal.bg = bg0
c.colors.statusbar.normal.fg = fg
c.colors.statusbar.insert.bg = bg0
c.colors.statusbar.insert.fg = green
c.colors.statusbar.command.bg = bg0
c.colors.statusbar.command.fg = fg
c.colors.statusbar.url.success.http.fg = blue
c.colors.statusbar.url.success.https.fg = green
c.colors.statusbar.url.error.fg = red
c.colors.statusbar.url.warn.fg = orange
c.colors.statusbar.url.hover.fg = aqua
c.colors.statusbar.progress.bg = statusline1

# 标签栏
c.colors.tabs.bar.bg = bg_dim
c.colors.tabs.indicator.start = green
c.colors.tabs.indicator.stop = red
c.colors.tabs.indicator.error = red
c.colors.tabs.indicator.system = "rgb"
c.colors.tabs.odd.bg = bg1
c.colors.tabs.odd.fg = fg
c.colors.tabs.even.bg = bg1
c.colors.tabs.even.fg = fg
c.colors.tabs.selected.odd.bg = bg2
c.colors.tabs.selected.odd.fg = fg
c.colors.tabs.selected.even.bg = bg2
c.colors.tabs.selected.even.fg = fg
c.colors.tabs.pinned.odd.bg = bg1
c.colors.tabs.pinned.odd.fg = fg
c.colors.tabs.pinned.even.bg = bg1
c.colors.tabs.pinned.even.fg = fg
c.colors.tabs.pinned.selected.odd.bg = bg2
c.colors.tabs.pinned.selected.odd.fg = fg
c.colors.tabs.pinned.selected.even.bg = bg2
c.colors.tabs.pinned.selected.even.fg = fg

# 下载栏
c.colors.downloads.bar.bg = bg0
c.colors.downloads.start.bg = green
c.colors.downloads.start.fg = bg0
c.colors.downloads.stop.bg = aqua
c.colors.downloads.stop.fg = bg0
c.colors.downloads.error.bg = red
c.colors.downloads.error.fg = bg0

# 提示
c.colors.hints.bg = bg1
c.colors.hints.fg = fg
c.colors.hints.match.fg = green

# 消息
c.colors.messages.error.bg = bg_red
c.colors.messages.error.fg = red
c.colors.messages.info.bg = bg1
c.colors.messages.info.fg = fg
c.colors.messages.warning.bg = bg_yellow
c.colors.messages.warning.fg = yellow

# 补全
c.colors.completion.fg = fg
c.colors.completion.odd.bg = bg1
c.colors.completion.even.bg = bg1
c.colors.completion.category.bg = bg0
c.colors.completion.category.fg = fg
c.colors.completion.category.border.top = bg0
c.colors.completion.category.border.bottom = bg0
c.colors.completion.item.selected.bg = bg2
c.colors.completion.item.selected.fg = fg
c.colors.completion.item.selected.border.top = bg2
c.colors.completion.item.selected.border.bottom = bg2
c.colors.completion.match.fg = green
c.colors.completion.scrollbar.bg = bg0
c.colors.completion.scrollbar.fg = fg

# 键提示
c.colors.keyhint.bg = bg0
c.colors.keyhint.fg = fg
c.colors.keyhint.suffix.fg = green

# 网页暗色模式
c.colors.webpage.preferred_color_scheme = "dark"
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = "lightness-cielab"
c.colors.webpage.darkmode.policy.images = "never"
c.colors.webpage.darkmode.threshold.background = 87

# 全局页面底色：Everforest bg0，亮度低于阈值，darkmode 不会把它反转成纯黑
c.content.user_stylesheets = "dark-bg.css"

# ==================== 圆角 ====================
_cornerRadius = 8  # px — 全局圆角半径

# --- Hints & Prompt ---
c.hints.radius = _cornerRadius
c.prompt.radius = _cornerRadius

# --- Status bar ---
_orig_statusbar_ss = _statusbar_bar._generate_stylesheet


def _rounded_statusbar_ss():
    ss = _orig_statusbar_ss()
    radius_css = f"border-radius: {_cornerRadius}px;"
    ss = ss.replace(
        "QWidget#StatusBar {\n            background-color:",
        f"QWidget#StatusBar {{\n            {radius_css}\n            padding: 0 {_cornerRadius}px;\n            background-color:",
    )
    return ss


_statusbar_bar._generate_stylesheet = _rounded_statusbar_ss
_statusbar_bar.StatusBar.STYLESHEET = _rounded_statusbar_ss()

# --- Tab bar: rounded tab shapes via custom drawControl ---
_orig_draw = _tabwidget.TabBarStyle.drawControl


def _rounded_draw(self, element, opt, p, widget=None):
    if element == QStyle.ControlElement.CE_TabBarTabShape:
        r = opt.rect
        bg = opt.palette.window().color()
        p.save()
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        path = QPainterPath()
        path.addRoundedRect(QRectF(r), _cornerRadius, _cornerRadius)
        p.setClipPath(path)
        p.fillPath(path, QColor(bg))
        # indicator strip (left edge, 4px wide, full height)
        indicator_color = opt.palette.base().color()
        if indicator_color.isValid():
            p.fillRect(QRectF(r.x(), r.y(), 4, r.height()), indicator_color)
        p.restore()
        return
    _orig_draw(self, element, opt, p, widget)


_tabwidget.TabBarStyle.drawControl = _rounded_draw

# 全局缩放
c.zoom.default = "120%"
