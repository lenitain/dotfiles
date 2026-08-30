return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    local eslint = vim.fn.executable("eslint_d") == 1 and { "eslint_d" } or {}
    lint.linters_by_ft = {
      -- rust/python 不在此配置：clippy 由 rustaceanvim checkOnSave 提供，
      -- ruff 由 LSP ruff server 提供，这里再配会出双份诊断
      javascript = eslint, typescript = eslint,
      javascriptreact = eslint, typescriptreact = eslint,
      -- lua: lua_ls 诊断已覆盖 luacheck，不重复配置
      go = vim.fn.executable("golangci-lint") == 1 and { "golangcilint" } or {},
      sh = vim.fn.executable("shellcheck") == 1 and { "shellcheck" } or {},
      bash = vim.fn.executable("shellcheck") == 1 and { "shellcheck" } or {},
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    -- 用 <leader>xl 而非 <leader>ll：<leader>l 已被 Lazy 占用（叶子键），
    -- 若再给 <leader>l 加子键（ll），which-key 会把 l 当成分组前缀，遮蔽 Lazy。
    -- xl 归入 x（诊断）组，linting 正好属于诊断。
    vim.keymap.set("n", "<leader>xl", function()
      lint.try_lint()
    end, { desc = "Trigger linting" })
  end,
}
