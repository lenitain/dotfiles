return {
  "julienvincent/hunk.nvim",
  -- 主要作为 jj 的 diff-editor 使用，因此按命令懒加载
  cmd = { "HunkDiffView", "HunkDiffEditor" },
  dependencies = {
    "MunifTanjim/nui.nvim",
    -- 文件树图标（可选依赖，这里显式声明以保证 require 时已在 rtp 中）
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    ui = {
      tree = {
        -- 目录展示方式：nested（逐层展开）/ flat（完整路径）/ compact（合并单链目录）
        mode = "compact",
        -- 0 < width <= 1 为编辑器宽度占比，> 1 为列数
        width = 35,
        -- 文件树以浮窗显示，而不是固定左侧分栏
        use_float = false,
      },
      -- vertical = 左右对比（垂直分屏）；horizontal = 上下对比
      layout = "vertical",
      -- 退出前二次确认，避免误按 q 丢弃已选内容
      confirm_before_quit = false,
    },
  },
}
