return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    -- 新版 API：setup 只更新配置，不再自动注册按键（旧版 keymaps/enable 字段已移除）
    require("nvim-treesitter-textobjects").setup {
      select = {
        lookahead = true,
      },
      move = {
        set_jumps = true,
      },
    }

    local select = require("nvim-treesitter-textobjects.select")
    local move = require("nvim-treesitter-textobjects.move")
    local q = "textobjects"

    -- 文本对象选择（保留原快捷键）
    vim.keymap.set({ "x", "o" }, "af", function() select.select_textobject("@function.outer", q) end, { desc = "Function (a)" })
    vim.keymap.set({ "x", "o" }, "if", function() select.select_textobject("@function.inner", q) end, { desc = "Function (i)" })
    vim.keymap.set({ "x", "o" }, "ac", function() select.select_textobject("@class.outer", q) end, { desc = "Class (a)" })
    vim.keymap.set({ "x", "o" }, "ic", function() select.select_textobject("@class.inner", q) end, { desc = "Class (i)" })
    vim.keymap.set({ "x", "o" }, "aa", function() select.select_textobject("@parameter.outer", q) end, { desc = "Parameter (a)" })
    vim.keymap.set({ "x", "o" }, "ia", function() select.select_textobject("@parameter.inner", q) end, { desc = "Parameter (i)" })

    -- 跳转
    vim.keymap.set("n", "]f", function() move.goto_next_start("@function.outer", q) end, { desc = "Next Function Start" })
    vim.keymap.set("n", "]F", function() move.goto_next_end("@function.outer", q) end, { desc = "Next Function End" })
    vim.keymap.set("n", "[f", function() move.goto_previous_start("@function.outer", q) end, { desc = "Prev Function Start" })
    vim.keymap.set("n", "[F", function() move.goto_previous_end("@function.outer", q) end, { desc = "Prev Function End" })
    vim.keymap.set("n", "]c", function() move.goto_next_start("@class.outer", q) end, { desc = "Next Class Start" })
    vim.keymap.set("n", "]C", function() move.goto_next_end("@class.outer", q) end, { desc = "Next Class End" })
    vim.keymap.set("n", "[c", function() move.goto_previous_start("@class.outer", q) end, { desc = "Prev Class Start" })
    vim.keymap.set("n", "[C", function() move.goto_previous_end("@class.outer", q) end, { desc = "Prev Class End" })
  end,
}
