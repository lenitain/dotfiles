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
