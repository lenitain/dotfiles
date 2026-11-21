# flyline 的编辑行为：建议文字、换行标记、光标、补全、历史。

# 内联历史建议只显示文本，不显示历史序号和时间戳（默认 true）。
flyline editor --show-inline-history-metadata false

# Ctrl+C 之后上一行没有换行结尾，标记会粘在 ^C 后面露出来；传空串关掉标记
# （补换行的行为不变）。
flyline --set-newline-marker ""

# 光标保持 beam：flyline 自绘的光标是块状，只有 terminal 后端 + PS1 里每条提示符的
# DECSCUSR（prompt/ps1.sh）才能保持 beam。
flyline set-cursor --backend terminal

# 关掉 flyline 的鼠标接管：它在 smart 模式下开启 mouse tracking（DECSET 1000/1002/1003/1006），
# foot 见到客户端抓鼠标就不做拖选，选中输出要精确命中或按住 Shift。代价是失去点哪跳哪、
# 点选建议、悬停 tooltip。
flyline mouse --mode disabled

# 补全：输入时自动弹出候选菜单保持默认开启（auto-suggest 默认 true），这里只关掉
# flycomp —— 也就是「No completion script found for 'xxx' ... Proceed?」那个询问。
# 连自动弹出也不要、只想要 Tab 触发，就再加一行：
#   flyline suggestions --auto-suggest false
flyline suggestions flycomp --enabled false

# 历史：保留 bash 后端。flyline 的 JSONL 后端不写 bash 的内存历史，!!、!$、history 会失效，
# 所以历史存储留在 bash，flyline 只负责历史搜索的界面。显式写出来，
# 不让默认值哪天变了一悄悄换后端（`ls ~/.local/share/flyline` 不存在即 bash 后端）。
flyline history --backend bash

# 验证：关闭 flyline 的彩蛋（python 命令词会显示蛇形动画）
flyline --enable-easter-eggs false

# 窗口缩放时的光标定位策略，同一时刻只能生效一种。
# default 让 flyline 按终端自动选择：Zellij → reflowed-all-whitespace-trimmed，
# 其它复用器 → reflowed-all，Ghostty/Kitty → auto-cleared，xterm.js 系 →
# reflowed-apart-from-cursor，其余 → reflowed-all。
# 想固定成某种：注释掉下面 default 那行，取消对应行的注释。也可以在 shell 里直接敲
# 同样的命令临时切换（当前会话立即生效，不用重开）。
# flyline --set-resize-logic default

# 终端缩放时清屏而不重排，光标按上方已有的行数上移；适合 Ghostty、Kitty。
# flyline --set-resize-logic auto-cleared

# 重排光标上方各行，并补上光标下方各行换行新增的行；光标所在行本身不重排。
# flyline --set-resize-logic reflowed-apart-from-cursor

# 重排光标上方各行，并补上光标所在行自身的换行偏移；忽略光标下方各行。
# flyline --set-resize-logic reflowed-all

# 同 reflowed-all，但测量行宽时忽略行尾空白；适合 Zellij。
# flyline --set-resize-logic reflowed-all-whitespace-trimmed

# 缩放时完全不动光标。
# flyline --set-resize-logic dont-move-cursor
