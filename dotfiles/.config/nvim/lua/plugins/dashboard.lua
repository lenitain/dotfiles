-- 启动页：nvimdev/dashboard-nvim（doom 主题）
--   * header 空行 = wrfm 模型画布区，透明浮窗盖在其上；vertical_center 由主题
--     把「画布 + 按钮 + 页脚」整块垂直居中，不依赖窗口高度，不会把内容推出屏
--   * 不改写 dashboard 缓冲：doom 的快捷键提示是 eol virt_text extmark，
--     整缓冲重写会把它冲掉
-- wrfm/wireforge 永远绕文件原点旋转、原点投影到画布中心（wireforge view.rs
-- 的 project_point），原版马桶站立在 y=0 地面、只占画布上半部；因此 logo 用
-- bbox 居中的专用资产（assets/toilet-logo.wrfm，`wrfm transform --to-origin`
-- 从参考模型生成），画布中心即模型中心，画布即模型区。
-- 图标用 \u{} 码点转义（Font Awesome BMP 区，Maple Mono NF 全覆盖）
local logo_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/assets/utah-teapot-logo.wrfm")
local logo_id = "dashboard-logo"

local center = {
	{ icon = "\u{F067} ", desc = "New file", key = "n", action = "enew" },
	{ icon = "\u{F002} ", desc = "Find file", key = "f", action = "Yazi" },
	{ icon = "\u{F011} ", desc = "Quit", key = "q", action = "qa" },
}

-- 文字位置不变的前提:画布高沿用 0.85 启发式(doom 的 vertical_center 会按
-- 缓冲行数自动补顶部填充,画布一高文字就被推下去)。模型与文字之间的留白
-- 由 camera_zoom 吃掉:zoom 越小模型越大,在画布里越贴近下沿。
local gap = 2 -- 画布与按钮之间的空行
local n_content = #center * 2 + 1 -- 按钮区 + 页脚（每按钮 2 行 + 页脚 1 行）
local camera_zoom = 0.37 -- ← 模型贴近文字的唯一可调值(全相位扫描:0.37 不裁且留白最小)
local function canvas_size()
	local usable = vim.o.lines - vim.o.cmdheight - n_content - gap
	local h = math.max(math.floor(usable * 0.85), 8)
	-- 宽度拉满终端:模型是宽扁形状(宽高比约 2:1),拉近相机后横向先撑满画布
	-- 被裁掉;画布透明看不见,宽度只用来给 spout/handle 留横向余量。
	return vim.o.columns - 2, h
end
local logo_w, logo_h = canvas_size()
-- 横向防裁自适应:模型最宽姿态约占 1.1*h/zoom 个字符(实测常数),窄终端上
-- 把 zoom 抬高到刚好放得下;宽终端用 camera_zoom 本身。
local camera_zoom_eff = math.max(camera_zoom, 1.1 * logo_h / logo_w)

local function place_logo(dashboard_buf)
	local wrfm = require("wrfm")
	-- 模型区首行从缓冲反推（vertical_center 插入的顶部填充已含在按钮行号里）
	local btn_row
	for i, line in ipairs(vim.api.nvim_buf_get_lines(dashboard_buf, 0, -1, false)) do
		if line:find("New file", 1, true) then
			btn_row = i - 1
			break
		end
	end
	if not btn_row then
		return
	end
	local row = math.max(btn_row - gap - logo_h, 0)
	local existing
	for _, m in ipairs(wrfm.get_models()) do
		if m.id == logo_id then
			existing = m
			break
		end
	end
	if existing then
		-- resize 后 dashboard 重渲染，已有模型只需重新对位
		if existing.winid and vim.api.nvim_win_is_valid(existing.winid) then
			existing:move(math.floor((vim.o.columns - (existing.width or logo_w)) / 2), row)
			pcall(
				vim.api.nvim_set_option_value,
				"winhighlight",
				"NormalFloat:WrfmDashTransparent",
				{ win = existing.winid }
			)
		end
		return
	end
	local ok, model = pcall(wrfm.from_file, logo_path, {
		id = logo_id,
		width = logo_w,
		height = logo_h,
		ignore_max_size = true, -- 画布已按终端算好，绕过 80%/60% 窗口占比钳制
		spin_speed = 0.012,
		border = false, -- 无框直出（image.nvim 观感）：只有 braille 本体浮在页面上
	})
	if not ok then
		return -- 资产缺失时静默跳过，不影响 dashboard
	end
	-- 画布大小 ≠ 模型大小:auto-fit 只占画布一部分,拉近放大。
	model:set_distance(model.fit_dist * camera_zoom_eff)
	model:render()
	model:move(math.floor((vim.o.columns - (model.width or logo_w)) / 2), row)
	-- 透明浮窗：背景透明，braille 点用主题标题色，文字从模型空隙透出
	pcall(vim.api.nvim_set_option_value, "winhighlight", "NormalFloat:WrfmDashTransparent", { win = model.winid })
	vim.api.nvim_create_autocmd("BufUnload", {
		buffer = dashboard_buf,
		once = true,
		callback = function()
			pcall(function()
				wrfm.clear(logo_id)
			end)
		end,
	})
end

local header = {}
for _ = 1, logo_h + gap do
	header[#header + 1] = ""
end

return {
	"nvimdev/dashboard-nvim",
	event = "VimEnter",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		theme = "doom",
		hide = {
			statusline = true,
			-- 已移除 bufferline；原生 showtabline 默认仅在多标签页时显示，
			-- 停在 dashboard（单标签）时不会出现，无需在此插手
			tabline = false,
			winbar = true,
		},
		config = {
			header = header,
			center = center,
			vertical_center = true,
			footer = function()
				local stats = require("lazy").stats()
				local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
				return {
					"⚡ " .. stats.loaded .. "/" .. stats.count .. " plugins loaded in " .. ms .. "ms",
				}
			end,
		},
	},
	config = function(_, opts)
		require("dashboard").setup(opts)
		-- 透明浮窗高亮：用主题 Title 前景色渲染 braille，背景完全透明
		local title_hl = vim.api.nvim_get_hl(0, { name = "Title" })
		local fg = title_hl.fg or vim.api.nvim_get_hl(0, { name = "Normal" }).fg
		vim.api.nvim_set_hl(0, "WrfmDashTransparent", { fg = fg, bg = "NONE", ctermbg = "NONE" })
		-- 挂 DashboardLoaded 而非 FileType：dashboard 在 VimResized 时会整体重渲染，
		-- 而它在每次渲染结束后都发这个事件，保证对位永远跑在主题重排之后
		vim.api.nvim_create_autocmd("User", {
			group = vim.api.nvim_create_augroup("dashboard.layout", { clear = true }),
			pattern = "DashboardLoaded",
			callback = function()
				vim.schedule(function()
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						if vim.bo[buf].filetype == "dashboard" then
							place_logo(buf)
							break
						end
					end
				end)
			end,
		})
	end,
}
