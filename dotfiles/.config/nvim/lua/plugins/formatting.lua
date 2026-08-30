return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true, lsp_fallback = true }) end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua             = { "stylua" },
      python          = { "ruff_format" },
      rust            = { "rustfmt" },
      typst           = { "tinymist" },
      c               = { "clang-format" },
      cpp             = { "clang-format" },
      -- zig: zls 提供 LSP formatting (zig fmt 不支持 stdin)
      go              = { "gofumpt", "gofmt" },
      -- 以下用第一个可用的：prettierd 优先，其次 prettier
      javascript      = { "prettierd", "prettier", stop_after_first = true },
      typescript      = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      css             = { "prettierd", "prettier", stop_after_first = true },
      html            = { "prettierd", "prettier", stop_after_first = true },
      json            = { "prettierd", "prettier", stop_after_first = true },
      yaml            = { "prettierd", "prettier", stop_after_first = true },
      markdown        = { "prettierd", "prettier", stop_after_first = true },
    },
    format_on_save = function(bufnr)
      -- 退出命令（:q/:wq/ZZ）触发的隐式保存不格式化：格式化只跟随显式 :w，
      -- 避免多文件会话退出时逐个同步格式化造成长时间卡顿（rust 社区惯例）
      if vim.g.skip_format_on_write then return nil end
      return {
        -- 预热后 prettierd 走热路径约 100ms；1500ms 仅作守护进程异常时的保险丝
        timeout_ms = 1500,
        lsp_fallback = true,
      }
    end,
    -- 未安装的 formatter 静默跳过，不弹警告（如 stylua）
    notify_no_formatters = false,
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

    -- 纯退出命令（:q/:qa 及一切缩写）触发的隐式保存不格式化，避免多文件会话
    -- 退出时逐个同步格式化造成卡顿；带写入意图的 :w/:wq/:x 照常格式化。
    -- 用 nvim_parse_cmd 把所敲命令解析成规范名再判断，天然覆盖各种缩写与修饰前缀
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      callback = function()
        if vim.fn.getcmdtype() ~= ":" then return end
        local ok, parsed = pcall(vim.api.nvim_parse_cmd, vim.fn.getcmdline(), {})
        if ok and (parsed.cmd == "quit" or parsed.cmd == "qall") then
          vim.g.skip_format_on_write = true
          vim.defer_fn(function() vim.g.skip_format_on_write = nil end, 0)
        end
      end,
    })

    -- 打开 prettierd 覆盖的文件类型时，后台预热其守护进程，
    -- 使首次保存即走热路径（约 100ms），避免冷启动超时
    local prettierd_warmed = false
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {
        "javascript", "typescript", "javascriptreact", "typescriptreact",
        "css", "html", "json", "yaml", "markdown",
      },
      callback = function()
        if prettierd_warmed or vim.fn.executable("prettierd") == 0 then return end
        prettierd_warmed = true
        vim.system({ "prettierd", "--version" })
      end,
    })
  end,
}
