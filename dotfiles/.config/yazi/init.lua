-- 状态栏右侧去掉百分比：默认 RIGHT 侧 id=5 的 percent 组件
Status:children_remove(5, Status.RIGHT)

-- 状态栏左侧用完整路径替换默认只显示文件名的组件（id=3 的 name）
Status:children_remove(3, Status.LEFT)

Status:children_add(function()
	local h = cx.active.current.hovered
	if not h then
		return ""
	end
	return " " .. ya.readable_path(tostring(h.url))
end, 2000, Status.LEFT)

-- 大小从左侧（id=2）挪到右侧，落在权限和行数之间
Status:children_remove(2, Status.LEFT)

Status:children_add(function(self)
	local h = cx.active.current.hovered
	if not h then
		return ""
	end

	local style = self:style()
	return ui.Line {
		ui.Span(th.status.sep_right.open):fg(style.alt:bg()):bg(App.bg()),
		ui.Span(" " .. ya.readable_size(h.cha.len) .. " "):style(style.alt),
	}
end, 2000, Status.RIGHT)
