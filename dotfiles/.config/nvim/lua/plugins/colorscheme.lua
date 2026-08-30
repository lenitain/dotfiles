-- ~/.config/nvim/lua/plugins/colorscheme.lua
--
-- 配色基准：**sainnhe 原版 everforest 的渲染结果**（dark + medium + 上游默认选项）。
-- 校验方式：把原版 colors/everforest.vim + autoload/everforest.vim 挂到临时 rtp 里
-- headless 渲染一遍，导出「全部高亮组 → 解析后的最终取值」，再和本机的同名组做 diff。
-- 因此本文件只保留两类内容：
--   1) 上游默认选项（background = medium、ui_contrast = low）；
--   2) 移植版 (neanias/everforest-nvim) 与原版不一致的组 —— 逐组钉回原版取值。
-- 不再按 ~/.palette/everforest.md 的 Usages 列做二次映射：那份表的字面在多处与上游
-- 实现不符（Properties→fg vs 实现 Blue、Hint→green vs 实现 Purple、Status Line
-- 背景 bg1/bg0 vs 实现 bg2/bg1、Concealed Text→grey0 vs @conceal→Grey 等），
-- 照它逐条"钉死"反而会偏离 everforest 实际的样子。
return {

  -- 注意：neanias/everforest-nvim 是纯 Lua 移植版，**不读任何 vim.g.everforest_\* 全局变量**
  -- （colors/everforest.lua 只有 `require("everforest").load()`，配置只能走 setup()）。
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local everforest = require("everforest")
      everforest.setup {
        -- 上游默认：background = "medium"（autoload/everforest.vim:17）
        background = "medium",
        -- 上游默认：diagnostic_virtual_text = "grey"（autoload/everforest.vim:34）——
        -- 诊断虚影文字一律 grey1，而不是按级别染色（移植版默认 "coloured"，
        -- 会让 VirtualText* / LspCodeLens* 变成红黄蓝紫）。
        diagnostic_virtual_text = "grey",
        -- ui_contrast 也用上游默认 "low"（autoload/everforest.vim:25）：
        -- low 下 LineNr / LineNrAbove / LineNrBelow / Conceal / FoldColumn = bg5(#56635F)、
        -- CursorLineNr = grey1(#859289)，这就是真实 everforest 的样子。
        -- 若想让行号更亮（LineNr=grey0、CursorLineNr=grey2）就改成 "high"，
        -- 但那样需要额外补一行（移植版丢了 FoldColumn 的 ui_contrast 分支）：
        --   hl.FoldColumn.fg = palette.grey0   -- 上游 colors/everforest.vim:69-71
        on_highlights = function(hl, palette)
          -- ===== A. 移植版与原版不一致的组（钉回原版）=====
          -- 上游 TSConstant→Fg（colors/everforest.vim:590），移植版→Constant(aqua)：
          -- 影响 @constant / @constant.regex 等（表里也是 fg）。
          hl.TSConstant = { fg = palette.fg }
          -- 上游 TSSymbol→Fg（:633），移植版→Aqua：影响 @symbol / @string.special.symbol。
          hl.TSSymbol = { fg = palette.fg }
          -- 上游 TSStrike→Grey（:628），移植版只给 strikethrough 不给前景：
          -- 影响 @strike / @markup.strike / @text.strike。
          hl.TSStrike = { fg = palette.grey1, strikethrough = true }
          -- 上游 FloatTitle 用 fg（:192），移植版用 grey1；背景/bold 两者一致，只改 fg。
          hl.FloatTitle.fg = palette.fg
          -- 上游 PmenuKind/PmenuExtra（:184-185）移植版完全没定义：
          --   PmenuKind  = green on bg2
          --   PmenuExtra = grey2 on bg2
          hl.PmenuKind = { fg = palette.green, bg = palette.bg2 }
          hl.PmenuExtra = { fg = palette.grey2, bg = palette.bg2 }
          -- 上游 CurrentWord 默认是 "grey background"（autoload/everforest.vim:29 → bg2），
          -- 移植版只给 bold。LspReference* 也链到它。
          hl.CurrentWord = { bg = palette.bg2 }
          -- 上游给 Cursor 用显式的 bg0-on-fg（:92；移植版是 reverse，视觉等价），
          -- lCursor / TermCursor 同理（:92）。都按上游钉死。
          hl.Cursor = { fg = palette.bg0, bg = palette.fg }
          hl.lCursor = { fg = palette.bg0, bg = palette.fg }
          hl.TermCursor = { fg = palette.bg0, bg = palette.fg }
          -- 上游诊断下划线只给波浪线着色（sp），文字保留语法色；移植版把文字也染色了。
          hl.DiagnosticUnderlineError = { undercurl = true, sp = palette.red }
          hl.DiagnosticUnderlineWarn = { undercurl = true, sp = palette.yellow }
          hl.DiagnosticUnderlineInfo = { undercurl = true, sp = palette.blue }
          hl.DiagnosticUnderlineHint = { undercurl = true, sp = palette.purple }
          hl.DiagnosticUnderlineOk = { undercurl = true, sp = palette.green }
          -- 上游未定义这几个名字，会落到 nvim 自带默认（Special/Structure 等）而不是
          -- everforest 的设计；按上游对应组（TSConstant/TSStringSpecial/TSURI/TSNote）补上。
          hl["@constant.regex"] = { fg = palette.fg }
          hl["@punctuation.bracket.regex"] = { fg = palette.fg }
          hl["@string.special.uri"] = { fg = palette.blue, underline = true } -- 上游 TSURI :645
          hl["@markup.note"] = { fg = palette.bg0, bg = palette.green, bold = true } -- 上游 TSNote :578/:705
          -- 有意保留的一条"超出上游"：nvim-treesitter 已把 url 组名从 @string.special.uri
          -- 改成 @string.special.url，而上游只映射了旧名（:737），新名会掉到 nvim 默认的
          -- 纯下划线。这里两者都按 TSURI（蓝 + 下划线）处理。
          hl["@string.special.url"] = { fg = palette.blue, underline = true }
          -- 上游已定义但移植版漏掉的两个 TSX 组（上游 :2572 / :2575）。
          hl["@keyword.import.tsx"] = { fg = palette.purple }
          hl["@punctuation.special.tsx"] = { fg = palette.orange }
          -- ===== B. 已知例外（与上游渲染结果不同，都是有原因的）=====
          -- 1) 上游尚未跟进的新组名（上游只映射了旧名，新名会掉回通用组）：
          --      @keyword.import.go  → 上游只映射 @include.go，新名渲染成 red；
          --                            这里保留 goTSInclude=purple（上游自己的专门组）。
          --      @keyword.modifier   → 上游只映射 @type.qualifier，新名渲染成 red；
          --                            这里保留 TSTypeQualifier=orange。
          --      @string.special.url → 见上，保留 TSURI。
          --    想要"与上游逐 bit 相同"就把这三个组也钉成上游渲染值（red/red/纯下划线）。
          -- 2) 上游疑似疏漏：TSStrike→Grey（:628）没有 strikethrough，而组名就是"删除线"；
          --    这里用 grey1 + strikethrough。想严格一致就去掉上面 hl.TSStrike 的样式。
          -- 3) 语义 token 层（@lsp.*）：你的配置关闭了 semantic tokens
          --    （lua/plugins/lspconfig.lua:119），这些组不会渲染，未做逐一对齐。
          -- 4) @variable.member.yaml：上游只映射旧名 @field.yaml，新名渲染成蓝；这里
          --    由主题给绿。yaml 查询两个名字都不发（键走 @property），实际不渲染。
        end,
      }
      vim.cmd.colorscheme("everforest")
    end,
  },
}
