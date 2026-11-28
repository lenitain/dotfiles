-- 智能进入：光标在目录上就进入该目录，在文件上就用默认程序打开
-- 只处理光标处的那一个文件，多选的文件不会被一起打开
--- @since 25.5.31
--- @sync entry

local function entry()
	local h = cx.active.current.hovered
	if not h then
		return
	end

	if h.cha.is_dir then
		ya.emit("enter")
	else
		ya.emit("open", { hovered = true })
	end
end

return { entry = entry }
