-- ============================================================
-- 全局快捷键映射

-- 所有插件专属映射（LSP、Git、DAP、格式化、文件查找等）
-- 已在各自插件文件中定义，此处仅保留通用全局映射
-- ============================================================

local map = vim.keymap.set

-- ==================== 按显示行移动（wrap 模式） ====================

-- 当 wrap 开启时，gj/gk 按屏幕行移动而非逻辑行
map({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "按显示行向下移动" })
map({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "按显示行向上移动" })

-- ==================== Undo 断点 ====================

-- 在插入模式下对常用操作插入 undo 断点，使 undo 更精细
map("i", ",", ",<c-g>u", { desc = "逗号 undo 断点" })
map("i", ".", ".<c-g>u", { desc = "句号 undo 断点" })
map("i", ";", ";<c-g>u", { desc = "分号 undo 断点" })
map("i", "<C-w>", "<C-g>u<C-w>", { desc = "删除前一个词 undo 断点" })
map("i", "<C-u>", "<C-g>u<C-u>", { desc = "删除到行首 undo 断点" })

-- ==================== 基础操作 ====================

-- 中文冒号等效于英文冒号，输入法开启时也可直接进入命令行
map("n", "：", ":", { desc = "中文冒号打开命令行" })

-- 保存文件（支持插入/可视/普通/选择/命令行模式）
map({ "i", "v", "n", "s", "c" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "处处保存" })

-- 退出所有窗口
map("n", "<C-q>", "<cmd>qa<cr>", { desc = "退出所有" })
-- 退出 Neovim
map("n", "<leader>q", "<cmd>qa<cr>", { desc = "退出 Neovim" })

-- 取消搜索高亮
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "取消搜索高亮" })

-- ==================== 窗口导航 ====================

-- Ctrl + hjkl 在窗口间切换
map("n", "<C-h>", "<C-w>h", { desc = "跳转到左侧窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "跳转到下方窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "跳转到上方窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "跳转到右侧窗口" })

-- Ctrl + 方向键 调整窗口大小
map("n", "<C-Up>",    "<cmd>resize +2<cr>",          { desc = "增加窗口高度" })
map("n", "<C-Down>",  "<cmd>resize -2<cr>",          { desc = "减少窗口高度" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<cr>", { desc = "减少窗口宽度" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "增加窗口宽度" })

-- ==================== 缓冲区操作 ====================

-- 缓冲区切换（原生）：[b/]b 上一个/下一个；<leader>bb 切到备选缓冲区
-- 查看所有打开的文件 + 未保存标记（+ 表示已修改）：<leader>bl

-- leader + b 前缀：缓冲区管理
map("n", "<leader>bd", "<cmd>bdelete<cr>",                        { desc = "删除缓冲区" })
map("n", "<leader>bD", "<cmd>bdelete!<cr>",                       { desc = "强制删除缓冲区" })
map("n", "<leader>bb", "<cmd>e #<cr>",                            { desc = "切换到备选缓冲区" })
map("n", "<leader>bl", "<cmd>ls<cr>",                             { desc = "列出所有缓冲区 (:ls)" })

-- ==================== 行移动 ====================

-- Alt+j/k 三模式统一：行粒度整体上下移（普通/插入=当前行，可视=选区整块），
-- 均支持数字前缀、重排缩进、边缘静默忽略
-- 注：上移地址需 -(count+1)，因 :move 把行插入到目标地址之后
function _G.__alt_move(delta, srow, erow)
  srow = srow or vim.fn.line(".")
  erow = erow or srow
  local n = vim.v.count1
  local h = erow - srow + 1
  local dest = delta > 0 and (erow + n) or (srow - n - 1)
  vim.cmd(("silent! %d,%dmove %d"):format(srow, erow, dest))
  local ns = math.max(1, dest - h + 1)
  vim.cmd(("silent! %d,%dnormal! =="):format(ns, ns + h - 1))
end

-- <Cmd> 不进入命令行 UI；可视尾部 gv 重选中移动后的行；插入尾部 gi 回到原插入点
map("n", "<A-j>", "<Cmd>lua __alt_move(1)<CR>", { desc = "向下移动当前行" })
map("n", "<A-k>", "<Cmd>lua __alt_move(-1)<CR>", { desc = "向上移动当前行" })
map("v", "<A-j>", "<Cmd>lua __alt_move(1, vim.fn.line('<'), vim.fn.line('>'))<CR>gv",
  { desc = "向下移动选区" })
map("v", "<A-k>", "<Cmd>lua __alt_move(-1, vim.fn.line('<'), vim.fn.line('>'))<CR>gv",
  { desc = "向上移动选区" })
map("i", "<A-j>", "<Esc><Cmd>lua __alt_move(1)<CR>gi", { desc = "向下移动当前行" })
map("i", "<A-k>", "<Esc><Cmd>lua __alt_move(-1)<CR>gi", { desc = "向上移动当前行" })

-- 复制当前行/选区到下方（走 "a 寄存器，不污染默认寄存器）
map("n", "<leader>D", '"ayy"ap', { desc = "复制当前行到下方" })
map("v", "<leader>D", '"ay`>"ap', { desc = "复制选区到下方" })

-- ==================== 缩进操作 ====================

-- 可视模式下 Tab / Shift+Tab 快速缩进
map("v", "<Tab>",   ">gv", { desc = "增加缩进" })
map("v", "<S-Tab>", "<gv", { desc = "减少缩进" })

-- ==================== 搜索相关 ====================

-- leader + rw 全文替换光标下的单词
map("n", "<leader>rw", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>",
    { desc = "替换光标下的单词" })
map("v", "<leader>rw", ":s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>",
    { desc = "替换选中的单词" })

-- ==================== 诊断相关 ====================

-- 查看当前行诊断详情
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "行内诊断浮窗" })

-- 跳转到上/下一个诊断（所有类型）
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "上一个诊断" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1,  float = true }) end, { desc = "下一个诊断" })

-- 跳转到上/下一个错误（ERROR 级别）
map("n", "[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true }) end, { desc = "上一个错误" })
map("n", "]e", function() vim.diagnostic.jump({ count = 1,  severity = vim.diagnostic.severity.ERROR, float = true }) end, { desc = "下一个错误" })

-- 跳转到上/下一个警告（WARN 级别）
map("n", "[w", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN, float = true }) end, { desc = "上一个警告" })
map("n", "]w", function() vim.diagnostic.jump({ count = 1,  severity = vim.diagnostic.severity.WARN, float = true }) end, { desc = "下一个警告" })

-- 快速修复列表：<leader>xq（trouble 版）见 plugins/trouble.lua；
-- 原生窗口随时可用 :copen 打开

-- ==================== 终端相关 ====================

-- 终端相关映射已移至 plugins/toggleterm.lua
-- 基础终端模式映射（Ctrl+hjkl, Ctrl+\）由 toggleterm 插件处理

-- ==================== 快速编辑 ====================

-- jj 退出插入模式（替代 <Esc>）
map("i", "jj", "<esc>", { desc = "退出插入模式" })

-- H/L 快速跳转到行首非空字符 / 行尾
map({ "n", "v" }, "H", "^", { desc = "行首非空字符" })
map({ "n", "v" }, "L", "$", { desc = "行尾" })

-- leader + p 可视模式粘贴不覆盖剪贴板
map("x", "<leader>p", '"_dP', { desc = "粘贴不覆盖剪贴板" })

-- 删除不进剪贴板用原生黑洞寄存器语法："_daw / "_dd / 可视模式 "_d

-- ==================== 选择与全选 ====================

-- leader + a 全选（原生 <C-a>/<C-x> 数字递增保持不变）
map("n", "<leader>a", "ggVG", { desc = "全选" })

-- ==================== 窗口管理 ====================

-- 分屏操作
map("n", "<leader>-", "<C-W>s", { desc = "水平分屏" })
map("n", "<leader>|", "<C-W>v", { desc = "垂直分屏" })

-- 关闭窗口
map("n", "<leader>wd", "<C-W>c", { desc = "关闭当前窗口" })
map("n", "<leader>wo", "<C-W>o", { desc = "关闭其他窗口" })

-- ==================== 标签页操作 ====================

map("n", "<leader><tab>l",    "<cmd>tablast<cr>",   { desc = "最后一个标签页" })
map("n", "<leader><tab>f",    "<cmd>tabfirst<cr>",  { desc = "第一个标签页" })
map("n", "<leader><tab><tab>","<cmd>tabnew<cr>",     { desc = "新建标签页" })
map("n", "<leader><tab>]",    "<cmd>tabnext<cr>",    { desc = "下一个标签页" })
map("n", "<leader><tab>d",    "<cmd>tabclose<cr>",   { desc = "关闭标签页" })
map("n", "<leader><tab>[",    "<cmd>tabprevious<cr>",{ desc = "上一个标签页" })

-- ==================== 光标与滚动 ====================

-- Q 重复上次宏（替代 Ex 模式）
map("n", "Q", "@qj", { desc = "重复上次录制的宏" })

-- J 合并行时保持光标位置
map("n", "J", "mzJ`z", { desc = "合并行并保持光标" })

-- Ctrl+d/u 翻半页后光标居中
map("n", "<C-d>", "<C-d>zz", { desc = "向下翻半页并居中" })
map("n", "<C-u>", "<C-u>zz", { desc = "向上翻半页并居中" })

-- n/N 搜索跳转 + hlslens 刷新计数（保留原居中/展开行为，支持数字前缀）
map("n", "n", function()
  pcall(function()
    vim.cmd(("normal! %dnzzzv"):format(vim.v.count1))
  end)
  require("hlslens").start()
end, { desc = "下一个搜索结果并居中" })
map("n", "N", function()
  pcall(function()
    vim.cmd(("normal! %dNzzzv"):format(vim.v.count1))
  end)
  require("hlslens").start()
end, { desc = "上一个搜索结果并居中" })

-- ==================== 注释辅助 ====================

-- gco/gcO 在下/上方新开一行并切换注释（需要注释插件支持 gcc）
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>",
    { desc = "下方新开一行并注释" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>",
    { desc = "上方新开一行并注释" })

-- ==================== 插件管理 ====================

-- 打开 Lazy 插件管理器
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy 插件管理器" })

-- ==================== 缓冲区切换（方括号风格） ====================

map("n", "[b", "<cmd>bprevious<cr>", { desc = "上一个缓冲区" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "下一个缓冲区" })

-- ==================== Toggle 系列（临时切换设置） ====================

-- 切换行号显示
map("n", "<leader>ul", function()
  vim.wo.number = not vim.wo.number
end, { desc = "切换行号" })

-- 切换相对行号
map("n", "<leader>uL", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "切换相对行号" })

-- 切换自动换行
map("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify("wrap: " .. (vim.wo.wrap and "开" or "关"))
end, { desc = "切换自动换行" })

-- 切换拼写检查
map("n", "<leader>us", function()
  vim.wo.spell = not vim.wo.spell
  vim.notify("spell: " .. (vim.wo.spell and "开" or "关"))
end, { desc = "切换拼写检查" })

-- 切换搜索高亮
map("n", "<leader>uh", function()
  vim.o.hlsearch = not vim.o.hlsearch
  vim.notify("hlsearch: " .. (vim.o.hlsearch and "开" or "关"))
end, { desc = "切换搜索高亮" })

-- 切换自动缩进
map("n", "<leader>uI", function()
  vim.bo.indentexpr = (vim.bo.indentexpr == "" and "v:lua.require'nvim-treesitter'.indentexpr()" or "")
  vim.notify("indent: " .. (vim.bo.indentexpr ~= "" and "开" or "关"))
end, { desc = "切换自动缩进" })

-- 切换拼写和 wrap 的组合提示
map("n", "<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  vim.notify("诊断: " .. (vim.diagnostic.is_enabled() and "开" or "关"))
end, { desc = "切换诊断显示" })

-- ==================== Git 集成（lazygit） ====================

-- <leader>gg 已由 toggleterm.lua 接管（打开 lazygit，自动定位到当前文件的 git 根）

-- 新建文件
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "新建文件" })

-- ==================== UI / 信息显示 ====================

-- 显示光标位置的高亮组信息
map("n", "<leader>ui", vim.show_pos, { desc = "显示光标处高亮信息" })

-- 检查 Neovim 健康状态
map("n", "<leader>ch", "<cmd>checkhealth<cr>", { desc = "检查健康状态" })

-- ==================== 配置文件操作 ====================

-- 快速打开 Neovim 配置入口文件
map("n", "<leader>fC", function()
  vim.cmd("edit " .. vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "打开 Neovim 配置文件" })

-- 重新加载当前 Lua 文件用原生命令：:source %
