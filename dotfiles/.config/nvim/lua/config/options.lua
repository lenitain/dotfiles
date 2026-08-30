-- ============================================
-- Neovim 选项配置（从 LazyVim 迁移）
-- ============================================

-- --------------------------------------------
-- 领导键设置
-- --------------------------------------------
vim.g.mapleader = " "           -- 全局领导键设为空格
vim.g.maplocalleader = "\\"     -- 本地领导键设为反斜杠

-- --------------------------------------------
-- 编辑器行为
-- --------------------------------------------
vim.opt.clipboard = "unnamedplus"  -- 剪切板：与系统剪切板同步
-- SSH 远程时用 OSC 52 把剪切板内容转发回本地终端
if vim.env.SSH_CONNECTION then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end
vim.opt.mouse = "a"                -- 启用鼠标支持（所有模式）
vim.opt.confirm = true             -- 退出时若有未保存更改，提示确认
vim.opt.autowrite = true           -- 自动保存：切换缓冲区/丢失焦点时自动写入
vim.opt.undofile = true            -- 撤销持久化：保存撤销历史到文件
vim.opt.undolevels = 10000         -- 最大撤销次数
vim.opt.updatetime = 200           -- 更快的更新时间（影响 CursorHold 等事件）
vim.opt.timeoutlen = 300           -- 按键超时时间（毫秒），影响 which-key 弹出速度

-- --------------------------------------------
-- 缩进与制表符
-- --------------------------------------------
vim.opt.expandtab = true       -- 将 Tab 转为空格
vim.opt.shiftwidth = 2         -- 自动缩进宽度
vim.opt.tabstop = 2            -- Tab 显示宽度
vim.opt.shiftround = true      -- 缩进对齐到 shiftwidth 的整数倍
vim.opt.smartindent = true     -- 智能缩进（新行自动对齐）
vim.opt.virtualedit = "block"    -- 可视模式下允许光标超出文本

-- --------------------------------------------
-- 行号与光标
-- --------------------------------------------
vim.opt.number = true              -- 显示行号
vim.opt.relativenumber = true      -- 显示相对行号
vim.opt.cursorline = true          -- 高亮当前行
vim.opt.signcolumn = "yes"         -- 始终显示符号列（避免文本左右跳动）
vim.opt.guicursor = "n-v-c:block-Cursor,i-ci:ver1-Cursor,v:hor20-Cursor"  -- 普通模式块状，插入模式竖线，可视模式下划线

-- --------------------------------------------
-- 搜索行为
-- --------------------------------------------
vim.opt.inccommand = "nosplit"  -- 增量替换预览（不打开新窗口）
vim.opt.grepformat = "%f:%l:%c:%m"  -- grep 输出格式
vim.opt.grepprg = "rg --vimgrep"  -- 使用 ripgrep 作为 grep 程序
vim.opt.ignorecase = true      -- 搜索时忽略大小写
vim.opt.smartcase = true       -- 若搜索词包含大写，则切换为大小写敏感
vim.opt.hlsearch = true        -- 高亮搜索匹配项
vim.opt.incsearch = true       -- 增量搜索（边输入边搜索）

-- --------------------------------------------
-- 界面显示
-- --------------------------------------------
vim.opt.wrap = false             -- 禁用自动换行（长行不换行，需水平滚动）
vim.opt.termguicolors = true   -- 启用真彩色支持
vim.opt.showmode = false       -- 不显示模式提示（状态栏已有显示）
vim.opt.shortmess:append("I")  -- 禁用启动 intro 画面（NVIM logo + 帮助信息）
vim.opt.showcmd = false        -- 不显示命令（减少噪音）
vim.opt.cmdheight = 0          -- 隐藏底部命令行保留行（按 : 或有输入提示时临时浮出）
vim.opt.ruler = false          -- 不显示光标位置（状态栏已有显示）
vim.opt.laststatus = 3         -- 全局状态栏（单一状态栏横跨所有窗口）
vim.opt.scrolloff = 8          -- 光标距顶部/底部至少保留 8 行
vim.opt.sidescrolloff = 8      -- 光标距左右边缘至少保留 8 列
vim.opt.pumheight = 10         -- 弹出菜单最大显示 10 行
vim.opt.pumblend = 0          -- 弹出菜单透明度
vim.opt.winblend = 0          -- 浮动窗口透明度
vim.opt.conceallevel = 3       -- 隐藏标记文本（如 markdown 中的链接语法）
vim.opt.list = true            -- 显示不可见字符
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }  -- 不可见字符的显示符号
vim.opt.fillchars = {          -- 窗口分隔符样式
  foldopen = "─",
  foldclose = "+",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
vim.opt.smoothscroll = true    -- 平滑滚动（Neovim 0.10+）
vim.opt.winborder = "rounded"   -- 统一所有浮窗边框为圆角

-- --------------------------------------------
-- 折叠设置
-- --------------------------------------------
vim.opt.foldlevel = 99             -- 默认展开所有折叠
vim.opt.foldlevelstart = 99        -- 打开文件时折叠级别
vim.opt.foldcolumn = "0"          -- 关闭折叠列（auto:1 时 markdown 标题层级会以数字显示）
vim.opt.foldmethod = "expr"        -- 使用表达式折叠
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"  -- 基于 Treesitter 的折叠表达式
vim.opt.foldtext = ""          -- 使用默认折叠文本（Neovim 0.10+）

-- --------------------------------------------
-- 窗口与分割
-- --------------------------------------------
vim.opt.splitbelow = true      -- 新窗口默认在下方打开
vim.opt.splitright = true      -- 新窗口默认在右侧打开
vim.opt.splitkeep = "screen"   -- 分割窗口时保持屏幕稳定

-- --------------------------------------------
-- 补全与弹出菜单
-- --------------------------------------------
vim.opt.completeopt = "menu,menuone,noselect"  -- 补全选项：显示菜单、单选项也显示、不自动选择
-- formatexpr 由 conform.nvim 加载时设置（见 lua/plugins/formatting.lua）
vim.opt.formatoptions = "jcroqlnt"  -- 格式化选项
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }  -- 会话保存选项
vim.opt.spelllang = { "en", "cjk" }  -- 拼写检查语言（英文 + 中日韩）
vim.opt.wildmode = "longest:full,full"         -- 命令行补全模式：最长匹配+完整循环

-- --------------------------------------------
-- 撤销持久化（LazyVim 风格）
-- --------------------------------------------
local undodir = vim.fn.stdpath("state") .. "/undo"  -- 撤销文件存储路径
if not vim.uv.fs_stat(undodir) then
  vim.fn.mkdir(undodir, "p")  -- 目录不存在则创建
end
vim.opt.undodir = undodir      -- 设置撤销目录

-- --------------------------------------------
-- 杂项
-- --------------------------------------------
vim.g.markdown_recommended_style = 0  -- 禁用 markdown ftplugin 的默认样式改动

-- mise shims + go/bin 补入 PATH（确保 LSP/DAP/formatter/linter 可被发现）
local extra_paths = {
  vim.fn.expand("~/.local/share/mise/shims"),
  vim.fn.expand("~/go/bin"),
  vim.fn.expand("~/.moon/bin"),
  vim.fn.expand("~/.ghcup/bin"),
}
for _, p in ipairs(extra_paths) do
  if vim.uv.fs_stat(p) and not string.find(vim.env.PATH, p, 1, true) then
    vim.env.PATH = p .. ":" .. vim.env.PATH
  end
end

-- 内置插件禁用由 lazy.nvim performance.rtp.disabled_plugins 统一处理（见 config/lazy.lua），
-- 此处不再重复设置 vim.g.loaded_*
