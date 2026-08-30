return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local wk = require("which-key")
    wk.setup({
      win = {
        border = "rounded",
      },
    })
    wk.add({
      { "<leader>b", group = "buffer" },
      { "<leader>m", group = "markdown" },
      { "<leader>f", group = "file" },
      { "<leader>g", group = "git" },
      { "<leader>s", group = "search" },
      { "<leader>u", group = "ui" },
      { "<leader>w", group = "windows" },
      { "<leader>x", group = "diagnostics" },
      { "<leader>d", group = "debug" },
      { "<leader>t", group = "test" },
      { "<leader>c", group = "code" },
      { "<leader>r", group = "replace" },
      { "<leader>T", group = "terminal" },
    })
  end,
}
