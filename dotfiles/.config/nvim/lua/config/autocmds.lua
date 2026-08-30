-- 自动命令配置

local api = vim.api
local aug = api.nvim_create_augroup("UserConfig", { clear = true })

-- 1. 文件检查：当文件被外部修改时自动重新加载
api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = aug,
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- 2. 高亮复制：复制文本时短暂高亮显示复制区域
api.nvim_create_autocmd("TextYankPost", {
  group = aug,
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- 3. 窗口调整：当 Neovim 窗口大小改变时自动调整布局，然后恢复当前 tab
api.nvim_create_autocmd("VimResized", {
  group = aug,
  callback = function()
    local current = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current)
  end,
})

-- 4. 恢复光标位置：打开文件时恢复上次光标位置
api.nvim_create_autocmd("BufReadPost", {
  group = aug,
  callback = function(event)
    -- 排除 gitcommit 等需要从头编辑的文件
    local excluded = { gitcommit = true }
    local ft = vim.bo[event.buf].filetype
    if excluded[ft] then
      return
    end
    -- 防重复标记
    if vim.b[event.buf].user_cursor_restored then
      return
    end
    vim.b[event.buf].user_cursor_restored = true
    local mark = api.nvim_buf_get_mark(event.buf, '"')
    local lcount = api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 5. 快速退出：在帮助、快速修复等窗口中按 q 退出
api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = {
    "help",
    "man",
    "qf",
    "lspinfo",
    "toggleterm",
    "spectre_panel",
    "PlenaryTestPopup",
    "startuptime",
    "tsplayground",
    "neotest-output",
    "checkhealth",
    "neotest-summary",
    "neotest-output-panel",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- 6. 文本文件设置：对文本文件进行特殊设置
api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = { "gitcommit", "markdown", "text", "plaintex" },
  callback = function()
    vim.opt_local.spell = true
  end,
})

-- 7. markdown/JSON 文件设置：不隐藏任何字符
api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = { "markdown", "markdown_inline", "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- 8. 自动创建目录：保存文件时自动创建不存在的目录
api.nvim_create_autocmd("BufWritePre", {
  group = aug,
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
