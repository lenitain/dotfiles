-- ~/.config/nvim/lua/plugins/colorscheme.lua
return {

  -- 主题：Everforest
  -- 注意：neanias/everforest-nvim 是纯 Lua 移植版，**不读任何 vim.g.everforest_\* 全局变量**
  -- （colors/everforest.lua 只有 `require("everforest").load()`，配置只能走 setup()）。
  -- 之前的 vim.g.everforest_background / vim.g.everforest_better_performance 全是死代码，
  -- 前者"看起来生效"只是因为 medium 恰好就是默认值，后者在这个移植版里根本不存在。
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local everforest = require("everforest")
      everforest.setup {
        background = "medium",
        -- "low" 是 sainnhe 原版与移植版的共同默认；改成 "high" 是按
        -- ~/.palette/everforest.md 的语义对齐（行号/隐藏文字用 grey0，
        -- CursorLineNr 用 grey2），bg5 在官方表里标注 "_Not currently used_"。
        -- 这是偏好选择，不是修 bug。
        ui_contrast = "high",
        -- 下面按 ~/.palette/everforest.md 的语义表对齐；注意上游
        -- colors/everforest.vim 的实现与表本身不一致，移植版是照抄实现的。
        on_highlights = function(hl, palette)
          -- 表里状态栏激活态 bg1、非激活态 bg0；transparent_background_level = 2
          -- 时主题本意是透明，此时不覆盖。状态栏平时由 lualine 自带的 everforest
          -- 主题绘制，这两个组只在没有 lualine 的场合可见。
          if everforest.config.transparent_background_level ~= 2 then
            hl.StatusLine.bg = palette.bg1
            hl.StatusLineNC.bg = palette.bg0
          end
          -- WinBar 不动：上游给 WinBar 就是 bg2（表里 bg2 也标了 Window Toolbar
          -- Background），且本配置未启用 winbar。
          -- FoldColumn 的 ui_contrast 判断在移植版里丢了、恒为 bg5（上游 high 时是
          -- grey0），这里单独修正；只改 fg，保留主题的 sign_column_background 背景逻辑。
          hl.FoldColumn.fg = palette.grey0
        end,
      }
      vim.cmd.colorscheme("everforest")
    end,
  },
}
