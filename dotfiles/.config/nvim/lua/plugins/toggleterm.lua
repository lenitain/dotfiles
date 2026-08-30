return {
  "akinsho/toggleterm.nvim",
  version = "*",
  event = "VeryLazy",
  opts = {
    highlights = {
      -- 浮窗边框跟随主题 FloatBorder（灰色），与 yazi 等统一，不再强制白色 Normal
      FloatBorder = { link = "FloatBorder" },
    },
    -- 终端窗口大小
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      end
    end,
    -- 打开终端时光标在插入模式
    start_in_insert = true,
    -- 终端插入模式下按键映射
    insert_mappings = false,
    -- 普通模式下按键映射
    terminal_mappings = false,
    -- 终端窗口位置
    direction = "float",
    -- 浮动窗口配置
    float_opts = {
      border = "rounded", -- 圆角边框
      -- 注意：width/height 是"绝对列/行数"，不是比例！用函数自适应，窗口 resize 时自动跟随。
      -- 左右铺满：总列数 - 左右边框各 1
      width = function(_)
        return vim.o.columns - 2
      end,
      -- 上下让出系统行再铺满：
      --   showtabline>0 → 顶部让 1 行给标签栏
      --   cmdheight       → 底部让 1 行给命令行
      --   laststatus>0    → 底部再让 1 行给全局状态栏（lualine）
      --   最后再给上下边框各留 1
      height = function(_)
        local top = vim.o.showtabline > 0 and 1 or 0
        local bottom = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
        return vim.o.lines - top - bottom - 2
      end,
      winblend = 0,
    },
    -- 关闭终端时隐藏而非销毁
    close_on_exit = true,
    -- 终端 shell
    shell = vim.o.shell,
  },
  keys = {
    { "<leader>Tf", "<cmd>ToggleTerm direction=float<cr>", desc = "切换终端（浮动）" },
    { "<leader>Th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "切换终端（水平分割）" },
    { "<leader>Tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "切换终端（垂直分割）" },
    { "<C-_>", "<cmd>ToggleTerm<cr>", desc = "切换终端", mode = { "n", "t" } },
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)

    -- 在终端模式下使用 Ctrl+hjkl 切换窗口
    function _G.set_terminal_keymaps()
      local map = vim.keymap.set
      -- buffer = 0：仅对当前（toggleterm）终端缓冲区生效，绝不污染其他终端（如 fzf-lua 的 fzf 终端）
      map("t", "<C-h>", [[<C-\><C-n><C-W>h]], { buffer = 0, desc = "终端→左侧窗口" })
      map("t", "<C-j>", [[<C-\><C-n><C-W>j]], { buffer = 0, desc = "终端→下方窗口" })
      map("t", "<C-k>", [[<C-\><C-n><C-W>k]], { buffer = 0, desc = "终端→上方窗口" })
      map("t", "<C-l>", [[<C-\><C-n><C-W>l]], { buffer = 0, desc = "终端→右侧窗口" })
      map("t", "<C-\\>", [[<C-\><C-n>]], { buffer = 0, desc = "退出终端插入模式" })
    end

    -- 自动命令：打开终端时设置按键映射
    -- 只在真正的 toggleterm 终端里启用（buffer 名含 #toggleterm#）；
    -- fzf-lua 的 fzf 终端也走 termopen 触发本 autocmd，但名字不含该标记，应跳过，
    -- 否则 Ctrl+hjkl 会被"跳窗口"截走，导致 fzf 列表无法移动。
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*",
      callback = function(event)
        if vim.fn.bufname(event.buf):find("toggleterm") then
          set_terminal_keymaps()
        end
      end,
    })

    -- 集成 lazygit
    local Terminal = require("toggleterm.terminal").Terminal
    local lazygit = Terminal:new({
      cmd = "lazygit",
      dir = "git_dir",
      direction = "float",
      float_opts = {
        border = "rounded",
      },
      on_open = function(term)
        vim.cmd("startinsert!")
        -- 在 lazygit 终端中按 q 关闭
        vim.keymap.set("n", "q", function()
          term:close()
        end, { buffer = term.bufnr, silent = true })
      end,
      on_close = function()
        vim.cmd("startinsert!")
      end,
    })

    function _LAZYGIT_TOGGLE()
      lazygit:toggle()
    end

    -- lazygit 快捷键
    vim.keymap.set("n", "<leader>gg", _LAZYGIT_TOGGLE, { desc = "打开 lazygit" })
  end,
}
