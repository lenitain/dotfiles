-- ~/.config/nvim/lua/plugins/colorscheme.lua
return {

  -- 主题：Everforest
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.everforest_background = "medium"
      vim.g.everforest_better_performance = 1
      vim.cmd.colorscheme("everforest")
    end,
  },
}
