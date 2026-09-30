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
        -- 这是按表对齐的偏好选择，不是修 bug。
        ui_contrast = "high",
        -- 语法色不依赖上游取值：官方实现（sainnhe colors/everforest.vim）与其 Lua 移植
        -- 在 TSConstant/TSProperty/TSSymbol 及 JSON/YAML/TOML 等语言特化组上都和
        -- ~/.palette/everforest.md 的表有出入，这里按表的 [_Treesitter_] 条目显式钉死。
        on_highlights = function(hl, palette)
          -- 状态栏：表里激活态 bg1、非激活态 bg0；transparent_background_level = 2
          -- 时主题本意是透明，此时不覆盖。状态栏平时由 lualine 自带的 everforest
          -- 主题绘制，这两个组只在没有 lualine 的场合可见。
          if everforest.config.transparent_background_level ~= 2 then
            hl.StatusLine.bg = palette.bg1
            hl.StatusLineNC.bg = palette.bg0
          end
          -- WinBar 不动：上游给 WinBar 就是 bg2（表里 bg2 也标了 Window Toolbar
          -- Background），且本配置未启用 winbar。
          -- FoldColumn：移植版丢了 ui_contrast 判断（high 时应为 grey0），单独修正；
          -- 只改 fg，保留主题的 sign_column_background 背景逻辑。
          hl.FoldColumn.fg = palette.grey0

          -- 官方表 [_Treesitter_] 语义（分类 → 颜色）：
          --   fg     Constants, Variables, Function Parameters, Properties, Symbol Identifiers
          --   aqua   Strings, Characters
          --   green  Constructors, Function Calls, Built-In Functions, Macro Functions,
          --          String Escapes, Regex Literals, Tag Delimiters, Non-Structured Text
          --   blue   Fields, Special Punctuation, Math Environments
          --   purple Built-In Constants, Built-In Variables, Macro-Defined Constants,
          --          Attributes/Annotations
          --   yellow Types, Modules, Namespaces
          local treesitter = {
            ["@constant"] = palette.fg,
            ["@variable"] = palette.fg,
            ["@parameter"] = palette.fg,
            ["@property"] = palette.fg,
            ["@symbol"] = palette.fg,
            ["@string.special.symbol"] = palette.fg,

            ["@string"] = palette.aqua,
            ["@character"] = palette.aqua,

            ["@function"] = palette.green,
            ["@function.call"] = palette.green,
            ["@function.builtin"] = palette.green,
            ["@function.macro"] = palette.green,
            ["@constructor"] = palette.green,
            ["@string.escape"] = palette.green,
            ["@string.regex"] = palette.green,
            ["@tag.delimiter"] = palette.green,

            ["@field"] = palette.blue,
            ["@punctuation.special"] = palette.blue,
            ["@math"] = palette.blue,

            ["@constant.builtin"] = palette.purple,
            ["@constant.macro"] = palette.purple,
            ["@variable.builtin"] = palette.purple,
            ["@annotation"] = palette.purple,
            ["@attribute"] = palette.purple,

            ["@type"] = palette.yellow,
            ["@type.builtin"] = palette.yellow,
            ["@type.definition"] = palette.yellow,
            ["@module"] = palette.yellow,
            ["@namespace"] = palette.yellow,

            ["@keyword"] = palette.red,
            ["@operator"] = palette.orange,
            ["@keyword.operator"] = palette.orange,
            ["@storageclass"] = palette.orange,
            ["@label"] = palette.orange,
            ["@tag"] = palette.orange,
            ["@type.qualifier"] = palette.orange,
            ["@debug"] = palette.orange,
            ["@punctuation.delimiter"] = palette.grey1,

            ["@boolean"] = palette.purple,
            ["@number"] = palette.purple,
            ["@preproc"] = palette.purple,
          }

          -- 语言特化覆盖：上游给 JSON/YAML/TOML/Go/JS/TS 定义了带语言后缀的高亮组
          -- （@string.json、@module.go、@include.typescript…），nvim 查组时按
          -- @capture.lang 精确匹配、不回退通用组，所以上面的通用表管不到它们，
          -- 必须逐组按表改回来；表未定义的（@tag.attribute、URI、markdown 标题、
          -- @constructor.lua 的表构造花括号等）保持上游/官方实现的选择。
          local lang_overrides = {
            -- Strings -> aqua（上游 json/yaml/toml 特化为 fg）
            ["@string.json"] = palette.aqua,
            ["@string.yaml"] = palette.aqua,
            ["@string.toml"] = palette.aqua,
            -- String Escapes -> green（上游特化为 SpecialChar）
            ["@string.escape.json"] = palette.green,
            ["@string.escape.yaml"] = palette.green,
            -- Fields -> blue
            ["@field.yaml"] = palette.blue,
            ["@variable.member.yaml"] = palette.blue,
            -- Properties -> fg
            ["@property.toml"] = palette.fg,
            -- Booleans / Built-In Constants -> purple（上游 yaml 特化为 orange）
            ["@boolean.yaml"] = palette.purple,
            ["@constant.builtin.yaml"] = palette.purple,
            ["@constant.builtin.go"] = palette.purple,
            -- Inclusion Keywords -> red（上游 go/js/ts 特化为 purple）
            ["@include.go"] = palette.red,
            ["@include.javascript"] = palette.red,
            ["@include.typescript"] = palette.red,
            ["@keyword.import.go"] = palette.red,
            ["@keyword.import.javascript"] = palette.red,
            ["@keyword.import.typescript"] = palette.red,
            -- Modules / Namespaces -> yellow（上游 go 特化为 fg）
            ["@module.go"] = palette.yellow,
            ["@namespace.go"] = palette.yellow,
            -- Special Punctuation -> blue（上游 ts 特化为 operator）
            ["@punctuation.special.typescript"] = palette.blue,
          }

          for group, fg in pairs(treesitter) do
            hl[group] = { fg = fg }
          end
          for group, fg in pairs(lang_overrides) do
            hl[group] = { fg = fg }
          end
        end,
      }
      vim.cmd.colorscheme("everforest")
    end,
  },
}
