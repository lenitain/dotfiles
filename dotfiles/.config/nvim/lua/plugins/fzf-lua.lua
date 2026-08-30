return {
  "ibhagwan/fzf-lua",
  -- 不锁版本，跟随 main 最新提交（作者只维护最新版）
  -- optional for icon support
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "FzfLua",
  event = "VeryLazy",
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
    { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags" },
    { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
    { "<leader>:", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
    { "<leader>fc", "<cmd>FzfLua colorschemes<cr>", desc = "Colorschemes" },
    { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document Symbols" },
    { "<leader>fS", "<cmd>FzfLua lsp_workspace_symbols<cr>", desc = "Workspace Symbols" },
    { "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git Commits" },
    { "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git Status" },
    { "<leader>gb", "<cmd>FzfLua git_branches<cr>", desc = "Git Branches" },
  },
  opts = {
    -- Global settings
    fzf_opts = {
      ["--layout"] = "reverse",
      ["--info"] = "inline",
      ["--marker"] = "+",
    },
    fzf_colors = {
      true,
      bg = "-1",
      gutter = "-1",
    },
    -- UI options
    winopts = {
      height = 0.85,
      width = 0.80,
      row = 0.35,
      col = 0.50,
      border = "rounded",
      preview = {
        layout = "vertical",
        vertical = "down:50%",
        horizontal = "right:50%",
        scrollbar = "float",
        scrollchars = { "┃", "" },
      },
    },
    -- Keymaps inside fzf
    keymap = {
      fzf = {
        ["ctrl-q"] = "select-all+accept",
        ["ctrl-u"] = "half-page-up",
        ["ctrl-d"] = "half-page-down",
      },
    },
    -- Actions on selection
    -- 用函数引用而非字符串别名：fzf-lua 的 hide profile 要求 action 必须是函数，
    -- 字符串别名会触发断言（hide.lua:66）导致选择器起不来
    actions = {
      files = {
        ["enter"] = function(...) return require("fzf-lua").actions.file_edit(...) end,
        ["ctrl-s"] = function(...) return require("fzf-lua").actions.file_split(...) end,
        ["ctrl-v"] = function(...) return require("fzf-lua").actions.file_vsplit(...) end,
        ["ctrl-t"] = function(...) return require("fzf-lua").actions.file_tabedit(...) end,
        ["alt-q"] = function(...) return require("fzf-lua").actions.file_sel_to_qf(...) end,
      },
    },
    -- Previewers
    previewers = {
      cat = {
        cmd = "cat",
        args = "-n",
      },
      bat = {
        cmd = "bat",
        args = "--color=always --style=numbers,changes",
        theme = "ansi", -- bat theme
      },
      head = {
        cmd = "head",
        args = nil,
      },
      git_diff = {
        cmd_deleted = "git diff --color HEAD --",
        cmd_modified = "git diff --color HEAD",
        cmd_untracked = "git diff --color --no-index /dev/null",
      },
      man = {
        cmd = "man -c %s | col -bx",
      },
      builtin = {
        syntax = true,
        syntax_limit_l = 0,
        syntax_limit_b = 1024 * 1024, -- 1MB
        limit_b = 1024 * 1024 * 10, -- 10MB
        -- 关闭 fzf 预览里的 treesitter-context：它依赖 fzf-lua 与 nvim-treesitter-context
        -- 两侧版本恰好对齐，否则会因 API 版本不匹配报错；正常编辑不受影响
        treesitter = { enabled = false },
      },
    },
    -- File finder options
    files = {
      prompt = "Files❯ ",
      multiprocess = true,
      file_icons = true,
      color_icons = true,
      find_opts = [[-type f -not -path '*/\.git/*' -not -path '*/node_modules/*' -not -path '*/\.next/*']],
      fd_opts = [[--color=never --type f --hidden --follow --exclude .git --exclude node_modules --exclude .next]],
    },
    -- Grep options
    grep = {
      prompt = "Rg❯ ",
      multiprocess = true,
      file_icons = true,
      color_icons = true,
      rg_opts = "--color=always --smart-case --hidden --glob '!.git' --glob '!node_modules' --glob '!.next'",
    },
    -- Buffer options
    buffers = {
      prompt = "Buffers❯ ",
      file_icons = true,
      color_icons = true,
      -- 必须显式关掉：默认 true 会把当前缓冲区当标题行（--header-lines 1），
      -- 导致 fzf 指针/选中错位
      sort_lastused = false,
      show_unloaded = true,
      actions = {
        ["ctrl-d"] = function(...) require("fzf-lua").actions.buf_del(...) end,
      },
    },
    -- LSP options
    lsp = {
      prompt = "LSP❯ ",
      file_icons = true,
      color_icons = true,
      git_status = true,
      severity = "hint",
      icons = {
        ["Error"] = { icon = "E", color = "red" },
        ["Warn"] = { icon = "W", color = "yellow" },
        ["Info"] = { icon = "I", color = "blue" },
        ["Hint"] = { icon = "H", color = "green" },
      },
    },
    -- Git options
    git = {
      status = {
        prompt = "GitStatus❯ ",
        cmd = "git status -su",
        file_icons = true,
        color_icons = true,
        preview_pager = "delta --width=$FZF_PREVIEW_COLUMNS",
      },
      commits = {
        prompt = "Commits❯ ",
        cmd = "git log --oneline --color",
        preview = "git show --stat --color {1}",
      },
      branches = {
        prompt = "Branches❯ ",
        cmd = "git branch --all --color",
        preview = "git log --graph --pretty=oneline --abbrev-commit --color {1}",
      },
    },
    -- Colorscheme options
    colorschemes = {
      prompt = "Colorschemes❯ ",
      live_preview = true,
      actions = {
        ["enter"] = function(selected)
          local colorscheme = selected[1]
          vim.cmd("colorscheme " .. colorscheme)
        end,
      },
    },
  },
  config = function(_, opts)
    require("fzf-lua").setup(opts)
    require("fzf-lua").register_ui_select() -- 接管 vim.ui.select（原 dressing.nvim 的职责）
  end,
}