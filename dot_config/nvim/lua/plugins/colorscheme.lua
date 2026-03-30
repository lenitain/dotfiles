-- ~/.config/nvim/lua/plugins/colorscheme.lua
return {
  {
    "neanias/everforest-nvim",
    lazy = false, -- 启动时立即加载
    priority = 1000, -- 确保在其他插件前加载
    config = function()
      vim.g.everforest_background = "medium"
      vim.g.everforest_better_performance = 1
      vim.cmd.colorscheme("everforest")
    end,
  },
}
