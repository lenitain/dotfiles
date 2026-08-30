-- yazi.nvim：把终端文件管理器 yazi 嵌进 Neovim
-- 参考文档：https://github.com/mikavilpas/yazi.nvim
-- 说明：yazi 原生三列布局（上级目录 | 当前目录 | 预览），
--       在浮动窗口里浏览，选中文件后按 <C-v>/<C-x>/<C-t> 分屏或标签页打开
-- 已替代 neo-tree，成为唯一的文件浏览器
return {
  "mikavilpas/yazi.nvim",
  version = "*", -- 使用最新稳定版
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  -- 禁用内置 netrw，避免打开目录时出现 netrw 文件列表
  init = function()
    vim.g.loaded_netrwPlugin = 1
    vim.g.loaded_netrw = 1
  end,
  keys = {
    -- 打开 yazi 文件浏览器
    { "<leader>e", "<cmd>Yazi<cr>", desc = "Open yazi（文件浏览器）" },
  },
  opts = {
    -- 用 yazi 替代 netrw：nvim <目录> 直接打开 yazi
    open_for_directories = true,

    -- 浮动窗口 100% 占满屏幕（默认 0.9 四周留 5% 空隙）
    floating_window_scaling_factor = 1,
    -- 圆角边框（single=方角单线 | rounded=圆角 | none=无边框）
    yazi_floating_window_border = "rounded",

    -- 修复：从 yazi 打开的第一个文件可能没有高亮
    -- 原则：正常路径零开销，只在确实缺失时才补救。
    -- 1) vim.schedule 延迟到主循环，避开 yazi 窗口恢复的时序竞态
    -- 2) :edit 正常打开（它会自己触发 BufReadPost/FileType，挂上 treesitter）
    -- 3) 再延迟一帧检查：只有 filetype 为空 / 高亮器没挂上时才补，绝不重复触发全部 autocmd
    open_file_function = function(chosen_file, config, state)
      vim.schedule(function()
        vim.cmd.edit(vim.fn.fnameescape(chosen_file))
        vim.schedule(function()
          if vim.bo.filetype == "" then
            vim.cmd("filetype detect")
          end
          if not vim.treesitter.highlighter.active[0] then
            pcall(vim.treesitter.start, 0) -- 非 treesitter 语言会静默跳过
          end
        end)
      end)
    end,
  },
}
