--- @since 26.9.1

local M = {}

local state = ya.sync(function() return cx.active.current.cwd end)

function M:entry(job)
	ya.emit("escape", { visual = true })

	local cwd = state()
	if not cwd then
		return
	end
	if cwd.spec.is_virtual then
		return ya.notify { title = "Finder", content = "Not supported under virtual filesystems", timeout = 5, level = "warn" }
	end

	-- --type 接受 file / dir（可逗号分隔）。fzf 的 walker 只认这几个词，
	-- 混入空格或未知词会让 fzf 直接退出（invalid walker option），这里先挡掉。
	local kinds = {}
	for kind in tostring(job.args["type"] or "file"):gmatch("[^,%s]+") do
		if kind ~= "file" and kind ~= "dir" then
			return ya.notify { title = "Finder", content = "Unknown type: " .. kind, timeout = 5, level = "error" }
		end
		kinds[kind] = true
	end
	if not kinds.file and not kinds.dir then
		return ya.notify { title = "Finder", content = "Type must be file or dir", timeout = 5, level = "error" }
	end

	-- Mirrors fzf's own shell helpers (`__fzf_cd__` / `__fzf_select__`):
	-- `follow`/`hidden` keep dot-directories in the list, and the walker only
	-- runs while nothing overrides it with FZF_DEFAULT_COMMAND
	local walker = {}
	if kinds.file then
		table.insert(walker, "file")
	end
	if kinds.dir then
		table.insert(walker, "dir")
	end
	table.insert(walker, "follow")
	table.insert(walker, "hidden")
	local walker_arg = table.concat(walker, ",")
	local dirs_only = kinds.dir and not kinds.file
	local multi = dirs_only and "+m" or "-m"

	local permit = ui.hide()
	local output, err = M.run_with(cwd, walker_arg, multi)
	permit:drop()
	if not output then
		return ya.notify { title = "Finder", content = tostring(err), timeout = 5, level = "error" }
	end

	local urls = M.split_urls(cwd, output)
	if #urls == 0 then
		return
	elseif dirs_only then
		return ya.emit("cd", { urls[1], raw = true })
	elseif #urls == 1 then
		return ya.emit("reveal", { urls[1], raw = true })
	end

	local files = {}
	for _, url in ipairs(urls) do
		files[#files + 1] = fs.file(url)
	end
	if #files > 0 then
		files.state = "on"
		ya.emit("toggle_all", files)
	end
end

---@param cwd Url
---@param walker string
---@param multi string
---@return string?, Error?
function M.run_with(cwd, walker, multi)
	local child, err = Command("fzf")
		:arg(multi)
		:arg("--walker=" .. walker)
		:arg("--scheme=path")
		-- 布局与 shell 里的 fzf 一致（输入栏在上，候选列表在下）：
		-- 命令行优先于继承来的 FZF_DEFAULT_OPTS，脱离 shell 启动 yazi 时也一样
		:arg("--layout=reverse")
		:arg("--bind=ctrl-z:ignore")
		:env("FZF_DEFAULT_COMMAND", "")
		:env("FZF_DEFAULT_OPTS_FILE", "")
		:cwd(tostring(cwd))
		:stdin(Command.INHERIT)
		:stdout(Command.PIPED)
		:spawn()

	if not child then
		return nil, Err("Failed to start `fzf`, error: %s", err)
	end

	local output, err = child:wait_with_output()
	if not output then
		return nil, Err("Cannot read `fzf` output, error: %s", err)
	elseif not output.status.success and output.status.code ~= 130 then
		return nil, Err("`fzf` exited with error code %s", output.status.code)
	end
	return output.stdout, nil
end

function M.split_urls(cwd, output)
	local t = {}
	for line in output:gmatch("[^\r\n]+") do
		local u = Url((line:gsub("/+$", "")))
		t[#t + 1] = u.is_absolute and u or cwd:resolve(u)
	end
	return t
end

return M
