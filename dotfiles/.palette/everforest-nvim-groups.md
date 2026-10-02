# Everforest for Neovim — resolved highlight groups

一次性核对生成的快照（2026-10-02），**不要手工编辑**；需要更新时按文末「生成方法」重跑一遍。

```
generated : 2026-10-02 19:27 CST
nvim      : NVIM v0.12.5
theme     : neanias/everforest-nvim @ a0e9edc57   (config: lua/plugins/colorscheme.lua)
treesitter: nvim-treesitter @ 728e031f6
reference : sainnhe/everforest master@2026-10-02  (colors/everforest.vim sha256:77c27d92c190b9dc…)
```

基准是 **sainnhe 原版的渲染结果**（dark + medium + 上游默认选项）。注意：上游 README 的
Usages 列（= everforest.md 里那张表）在多处与实现不符 —— Properties 实际是 Blue、诊断 Hint
实际是 purple、TS `@conceal` 实际是 grey1、状态栏背景实际是 bg2/bg1；本表一律以实现为准。
表里的值 = 本机配置实际渲染出的值；与上游的差异只有文末列出的那几条有意例外。

styles 列只列非默认属性（bold / italic / underline / undercurl / strikethrough / reverse）。
TS 一节的 `emitted` 标记该捕获名是否真的出现在你已装语言的查询里（只影响排查，不影响取色）。

## 1. Core UI

| group | fg | bg | styles |
|---|---|---|---|
| `Added` | #a7c080 | - |  |
| `Aqua` | #83c092 | - |  |
| `AquaBold` | #83c092 | - | bold |
| `AquaItalic` | #83c092 | - |  |
| `AquaSign` | #83c092 | - |  |
| `Blue` | #7fbbb3 | - |  |
| `BlueBold` | #7fbbb3 | - | bold |
| `BlueItalic` | #7fbbb3 | - |  |
| `BlueSign` | #7fbbb3 | - |  |
| `Boolean` | #d699b6 | - |  |
| `Changed` | #7fbbb3 | - |  |
| `Character` | #a7c080 | - |  |
| `ColorColumn` | - | #343f44 |  |
| `Comment` | #859289 | - | italic |
| `Conceal` | #56635f | - |  |
| `Conditional` | #e67e80 | - |  |
| `Constant` | #83c092 | - |  |
| `CurSearch` | #2d353b | #e67e80 |  |
| `CurrentWord` | - | #3d484d |  |
| `Cursor` | #2d353b | #d3c6aa |  |
| `CursorColumn` | - | #343f44 |  |
| `CursorLine` | - | #343f44 |  |
| `CursorLineNr` | #859289 | - |  |
| `Debug` | #e69875 | - |  |
| `Define` | #d699b6 | - |  |
| `Delimiter` | #d3c6aa | - |  |
| `DiagnosticError` | #e67e80 | - |  |
| `DiagnosticHint` | #d699b6 | - |  |
| `DiagnosticInfo` | #7fbbb3 | - |  |
| `DiagnosticOk` | #a7c080 | - |  |
| `DiagnosticSignError` | #e67e80 | - |  |
| `DiagnosticSignHint` | #d699b6 | - |  |
| `DiagnosticSignInfo` | #7fbbb3 | - |  |
| `DiagnosticSignOk` | #a7c080 | - |  |
| `DiagnosticSignWarn` | #dbbc7f | - |  |
| `DiagnosticUnderlineError` | - | - | undercurl |
| `DiagnosticUnderlineHint` | - | - | undercurl |
| `DiagnosticUnderlineInfo` | - | - | undercurl |
| `DiagnosticUnderlineOk` | - | - | undercurl |
| `DiagnosticUnderlineWarn` | - | - | undercurl |
| `DiagnosticVirtualTextError` | #859289 | - |  |
| `DiagnosticVirtualTextHint` | #859289 | - |  |
| `DiagnosticVirtualTextInfo` | #859289 | - |  |
| `DiagnosticVirtualTextOk` | #859289 | - |  |
| `DiagnosticVirtualTextWarn` | #859289 | - |  |
| `DiagnosticWarn` | #dbbc7f | - |  |
| `DiffAdd` | - | #425047 |  |
| `DiffChange` | - | #3a515d |  |
| `DiffDelete` | - | #514045 |  |
| `DiffText` | #2d353b | #7fbbb3 |  |
| `Directory` | #a7c080 | - |  |
| `EndOfBuffer` | #4f585e | - |  |
| `Error` | #e67e80 | - |  |
| `ErrorFloat` | #e67e80 | - |  |
| `ErrorMsg` | #e67e80 | - | bold,underline |
| `ErrorText` | - | - | undercurl |
| `Exception` | #e67e80 | - |  |
| `Fg` | #d3c6aa | - |  |
| `Float` | #d699b6 | - |  |
| `FloatBorder` | #859289 | #3d484d |  |
| `FloatFooter` | #d3c6aa | #4f585e | bold |
| `FloatTitle` | #d3c6aa | #4f585e | bold |
| `FoldColumn` | #56635f | - |  |
| `Folded` | #859289 | #343f44 |  |
| `Function` | #a7c080 | - |  |
| `Green` | #a7c080 | - |  |
| `GreenBold` | #a7c080 | - | bold |
| `GreenItalic` | #a7c080 | - |  |
| `GreenSign` | #a7c080 | - |  |
| `Grey` | #859289 | - |  |
| `HintFloat` | #d699b6 | - |  |
| `HintText` | - | - | undercurl |
| `Identifier` | #7fbbb3 | - |  |
| `Ignore` | #859289 | - |  |
| `IncSearch` | #2d353b | #e67e80 |  |
| `Include` | #d699b6 | - |  |
| `InfoFloat` | #7fbbb3 | - |  |
| `InfoText` | - | - | undercurl |
| `Keyword` | #e67e80 | - |  |
| `Label` | #e69875 | - |  |
| `LineNr` | #56635f | - |  |
| `LineNrAbove` | #56635f | - |  |
| `LineNrBelow` | #56635f | - |  |
| `LspCodeLens` | #859289 | - |  |
| `LspCodeLensSeparator` | #859289 | - |  |
| `LspInlayHint` | #56635f | - |  |
| `LspReferenceRead` | - | #3d484d |  |
| `LspReferenceText` | - | #3d484d |  |
| `LspReferenceWrite` | - | #3d484d |  |
| `LspSignatureActiveParameter` | #2d353b | #a7c080 |  |
| `Macro` | #83c092 | - |  |
| `MatchParen` | - | #4f585e |  |
| `ModeMsg` | #d3c6aa | - | bold |
| `MoreMsg` | #dbbc7f | - | bold |
| `MsgArea` | - | - |  |
| `MsgSeparator` | #859289 | #3d484d |  |
| `NonText` | #4f585e | - |  |
| `Normal` | #d3c6aa | #2d353b |  |
| `NormalFloat` | #d3c6aa | #3d484d |  |
| `NormalNC` | #d3c6aa | #2d353b |  |
| `Number` | #d699b6 | - |  |
| `OkFloat` | #a7c080 | - |  |
| `Operator` | #e69875 | - |  |
| `Orange` | #e69875 | - |  |
| `OrangeBold` | #e69875 | - | bold |
| `OrangeItalic` | #e69875 | - |  |
| `OrangeSign` | #e69875 | - |  |
| `Pmenu` | #d3c6aa | #3d484d |  |
| `PmenuExtra` | #9da9a0 | #3d484d |  |
| `PmenuKind` | #a7c080 | #3d484d |  |
| `PmenuMatch` | - | - | bold |
| `PmenuMatchSel` | - | - | bold |
| `PmenuSbar` | - | #3d484d |  |
| `PmenuSel` | #2d353b | #a7c080 |  |
| `PmenuThumb` | - | #7a8478 |  |
| `PreCondit` | #d699b6 | - |  |
| `PreProc` | #d699b6 | - |  |
| `Purple` | #d699b6 | - |  |
| `PurpleBold` | #d699b6 | - | bold |
| `PurpleItalic` | #d699b6 | - |  |
| `PurpleSign` | #d699b6 | - |  |
| `Question` | #dbbc7f | - |  |
| `QuickFixLine` | #d699b6 | - | bold |
| `Red` | #e67e80 | - |  |
| `RedBold` | #e67e80 | - | bold |
| `RedItalic` | #e67e80 | - |  |
| `RedSign` | #e67e80 | - |  |
| `Removed` | #e67e80 | - |  |
| `Repeat` | #e67e80 | - |  |
| `Search` | #2d353b | #a7c080 |  |
| `SignColumn` | #d3c6aa | - |  |
| `Special` | #dbbc7f | - |  |
| `SpecialChar` | #dbbc7f | - |  |
| `SpecialComment` | #859289 | - | italic |
| `SpecialKey` | #dbbc7f | - |  |
| `SpellBad` | - | - | undercurl |
| `SpellCap` | - | - | undercurl |
| `SpellLocal` | - | - | undercurl |
| `SpellRare` | - | - | undercurl |
| `Statement` | #e67e80 | - |  |
| `StatusLine` | #859289 | #3d484d |  |
| `StatusLineNC` | #859289 | #343f44 |  |
| `StatusLineTerm` | #859289 | #343f44 |  |
| `StatusLineTermNC` | #859289 | #2d353b |  |
| `StorageClass` | #e69875 | - |  |
| `String` | #a7c080 | - |  |
| `Structure` | #e69875 | - |  |
| `TabLine` | #9da9a0 | #475258 |  |
| `TabLineFill` | #859289 | #343f44 |  |
| `TabLineSel` | #2d353b | #a7c080 |  |
| `Tag` | #e69875 | - |  |
| `TermCursor` | #2d353b | #d3c6aa |  |
| `TermCursorNC` | #2d353b | #d3c6aa |  |
| `Terminal` | #d3c6aa | #2d353b |  |
| `Title` | #e69875 | - | bold |
| `Todo` | #2d353b | #7fbbb3 | bold |
| `Type` | #dbbc7f | - |  |
| `Typedef` | #e67e80 | - |  |
| `Underlined` | - | - | underline |
| `VertSplit` | #4f585e | - |  |
| `VirtualTextError` | #859289 | - |  |
| `VirtualTextHint` | #859289 | - |  |
| `VirtualTextInfo` | #859289 | - |  |
| `VirtualTextOk` | #859289 | - |  |
| `VirtualTextWarning` | #859289 | - |  |
| `Visual` | - | #543a48 |  |
| `VisualNOS` | - | #543a48 |  |
| `WarningFloat` | #dbbc7f | - |  |
| `WarningMsg` | #dbbc7f | - | bold |
| `WarningText` | - | - | undercurl |
| `Whitespace` | #4f585e | - |  |
| `WildMenu` | #2d353b | #a7c080 |  |
| `WinBar` | #859289 | #3d484d | bold |
| `WinBarNC` | #859289 | #343f44 |  |
| `WinSeparator` | #4f585e | - |  |
| `Yellow` | #dbbc7f | - |  |
| `YellowBold` | #dbbc7f | - | bold |
| `YellowItalic` | #dbbc7f | - |  |
| `YellowSign` | #dbbc7f | - |  |
| `diffAdded` | #a7c080 | - |  |
| `diffChanged` | #7fbbb3 | - |  |
| `diffRemoved` | #e67e80 | - |  |
| `healthError` | #e67e80 | - |  |
| `healthSuccess` | #a7c080 | - |  |
| `healthWarning` | #dbbc7f | - |  |
| `lCursor` | #2d353b | #d3c6aa |  |

## 2. Treesitter captures（含语言特化组）

| group | fg | bg | styles | emitted |
|---|---|---|---|---|
| `@annotation` | #d699b6 | - |  | - |
| `@attribute` | #d699b6 | - |  | yes |
| `@attribute.builtin` | #dbbc7f | - |  | yes |
| `@boolean` | #d699b6 | - |  | yes |
| `@boolean.yaml` | #e69875 | - |  | yes |
| `@character` | #83c092 | - |  | yes |
| `@character.special` | #dbbc7f | - |  | yes |
| `@comment` | #859289 | - | italic | yes |
| `@comment.error` | #2d353b | #e67e80 | bold | yes |
| `@comment.note` | #2d353b | #a7c080 | bold | yes |
| `@comment.todo` | #2d353b | #7fbbb3 | bold | - |
| `@comment.warning` | #2d353b | #dbbc7f | bold | yes |
| `@conceal` | #859289 | - |  | yes |
| `@conditional` | #e67e80 | - |  | - |
| `@constant` | #d3c6aa | - |  | yes |
| `@constant.builtin` | #d699b6 | - |  | yes |
| `@constant.builtin.go` | #83c092 | - |  | yes |
| `@constant.builtin.yaml` | #e69875 | - |  | yes |
| `@constant.macro` | #d699b6 | - |  | yes |
| `@constant.regex` | #d3c6aa | - |  | yes |
| `@constructor` | #a7c080 | - |  | yes |
| `@constructor.lua` | #d3c6aa | - |  | yes |
| `@constructor.tsx` | #dbbc7f | - |  | yes |
| `@debug` | #e69875 | - |  | - |
| `@define` | #d699b6 | - |  | - |
| `@diff.delta` | #7fbbb3 | - |  | yes |
| `@diff.minus` | #e67e80 | - |  | yes |
| `@diff.plus` | #a7c080 | - |  | yes |
| `@error` | #e67e80 | - |  | yes |
| `@exception` | #e67e80 | - |  | - |
| `@field` | #7fbbb3 | - |  | yes |
| `@field.yaml` | #a7c080 | - |  | yes |
| `@float` | #d699b6 | - |  | - |
| `@function` | #a7c080 | - |  | yes |
| `@function.builtin` | #a7c080 | - |  | yes |
| `@function.call` | #a7c080 | - |  | yes |
| `@function.macro` | #a7c080 | - |  | yes |
| `@function.method` | #a7c080 | - |  | yes |
| `@function.method.call` | #a7c080 | - |  | yes |
| `@include` | #e67e80 | - |  | - |
| `@include.go` | #d699b6 | - |  | - |
| `@include.javascript` | #d699b6 | - |  | - |
| `@include.typescript` | #d699b6 | - |  | - |
| `@keyword` | #e67e80 | - |  | yes |
| `@keyword.conditional` | #e67e80 | - |  | yes |
| `@keyword.debug` | #e69875 | - |  | yes |
| `@keyword.directive` | #d699b6 | - |  | yes |
| `@keyword.directive.define` | #d699b6 | - |  | yes |
| `@keyword.exception` | #e67e80 | - |  | yes |
| `@keyword.function` | #e67e80 | - |  | yes |
| `@keyword.import` | #e67e80 | - |  | yes |
| `@keyword.import.go` | #d699b6 | - |  | yes |
| `@keyword.import.javascript` | #d699b6 | - |  | yes |
| `@keyword.import.tsx` | #d699b6 | - |  | yes |
| `@keyword.import.typescript` | #d699b6 | - |  | yes |
| `@keyword.modifier` | #e69875 | - |  | yes |
| `@keyword.operator` | #e69875 | - |  | yes |
| `@keyword.repeat` | #e67e80 | - |  | yes |
| `@keyword.return` | #e67e80 | - |  | yes |
| `@keyword.storage` | #e69875 | - |  | - |
| `@label` | #e69875 | - |  | yes |
| `@label.json` | #a7c080 | - |  | yes |
| `@markup` | #dbbc7f | - |  | - |
| `@markup.emphasis` | - | - | italic | - |
| `@markup.environment` | #83c092 | - |  | - |
| `@markup.environment.name` | #dbbc7f | - |  | - |
| `@markup.heading` | #e69875 | - | bold | yes |
| `@markup.heading.1.delimiter.vimdoc` | #2d353b | #2d353b |  | - |
| `@markup.heading.1.markdown` | #e67e80 | - | bold | yes |
| `@markup.heading.1.marker.markdown` | #859289 | - |  | - |
| `@markup.heading.2.delimiter.vimdoc` | #2d353b | #2d353b | underline | - |
| `@markup.heading.2.markdown` | #e69875 | - | bold | yes |
| `@markup.heading.2.marker.markdown` | #859289 | - |  | - |
| `@markup.heading.3.markdown` | #dbbc7f | - | bold | yes |
| `@markup.heading.3.marker.markdown` | #859289 | - |  | - |
| `@markup.heading.4.markdown` | #a7c080 | - | bold | yes |
| `@markup.heading.4.marker.markdown` | #859289 | - |  | - |
| `@markup.heading.5.markdown` | #7fbbb3 | - | bold | yes |
| `@markup.heading.5.marker.markdown` | #859289 | - |  | - |
| `@markup.heading.6.markdown` | #d699b6 | - | bold | yes |
| `@markup.heading.6.marker.markdown` | #859289 | - |  | - |
| `@markup.italic` | - | - | italic | yes |
| `@markup.link` | #83c092 | - |  | yes |
| `@markup.link.label` | #dbbc7f | - |  | yes |
| `@markup.link.url` | #7fbbb3 | - | underline | yes |
| `@markup.list` | #7fbbb3 | - |  | yes |
| `@markup.list.checked` | #a7c080 | - |  | yes |
| `@markup.list.unchecked` | #859289 | - |  | yes |
| `@markup.math` | #7fbbb3 | - |  | yes |
| `@markup.note` | #2d353b | #a7c080 | bold | - |
| `@markup.quote` | #859289 | - |  | yes |
| `@markup.raw` | #a7c080 | - |  | yes |
| `@markup.strike` | #859289 | - | strikethrough | - |
| `@markup.strikethrough` | - | - | strikethrough | yes |
| `@markup.strong` | - | - | bold | yes |
| `@markup.underline` | - | - | underline | yes |
| `@math` | #7fbbb3 | - |  | - |
| `@method` | #a7c080 | - |  | yes |
| `@method.call` | #a7c080 | - |  | - |
| `@module` | #dbbc7f | - |  | yes |
| `@module.builtin` | #dbbc7f | - |  | yes |
| `@module.go` | #d3c6aa | - |  | yes |
| `@namespace` | #dbbc7f | - |  | yes |
| `@namespace.go` | #d3c6aa | - |  | yes |
| `@none` | #d3c6aa | - |  | yes |
| `@number` | #d699b6 | - |  | yes |
| `@number.float` | #d699b6 | - |  | yes |
| `@operator` | #e69875 | - |  | yes |
| `@parameter` | #d3c6aa | - |  | - |
| `@parameter.reference` | #d3c6aa | - |  | - |
| `@preproc` | #d699b6 | - |  | - |
| `@property` | #7fbbb3 | - |  | yes |
| `@property.toml` | #a7c080 | - |  | yes |
| `@punctuation` | #d3c6aa | - |  | - |
| `@punctuation.bracket` | #d3c6aa | - |  | yes |
| `@punctuation.bracket.regex` | #d3c6aa | - |  | yes |
| `@punctuation.delimiter` | #859289 | - |  | yes |
| `@punctuation.special` | #7fbbb3 | - |  | yes |
| `@punctuation.special.tsx` | #e69875 | - |  | yes |
| `@punctuation.special.typescript` | #e69875 | - |  | yes |
| `@repeat` | #e67e80 | - |  | - |
| `@storageclass` | #e69875 | - |  | - |
| `@storageclass.lifetime` | #e69875 | - |  | - |
| `@strike` | #859289 | - | strikethrough | - |
| `@string` | #83c092 | - |  | yes |
| `@string.escape` | #a7c080 | - |  | yes |
| `@string.escape.json` | #dbbc7f | - |  | yes |
| `@string.escape.yaml` | #dbbc7f | - |  | yes |
| `@string.json` | #d3c6aa | - |  | yes |
| `@string.regex` | #a7c080 | - |  | yes |
| `@string.regexp` | #a7c080 | - |  | yes |
| `@string.special` | #dbbc7f | - |  | yes |
| `@string.special.symbol` | #d3c6aa | - |  | - |
| `@string.special.uri` | #7fbbb3 | - | underline | - |
| `@string.special.url` | #7fbbb3 | - | underline | yes |
| `@string.toml` | #d3c6aa | - |  | yes |
| `@string.yaml` | #d3c6aa | - |  | yes |
| `@symbol` | #d3c6aa | - |  | - |
| `@tag` | #e69875 | - |  | yes |
| `@tag.attribute` | #a7c080 | - |  | yes |
| `@tag.builtin` | #dbbc7f | - |  | yes |
| `@tag.delimiter` | #a7c080 | - |  | yes |
| `@text` | #a7c080 | - |  | - |
| `@text.danger` | #2d353b | #e67e80 | bold | - |
| `@text.diff.add` | #a7c080 | - |  | - |
| `@text.diff.delete` | #e67e80 | - |  | - |
| `@text.emphasis` | - | - | italic | - |
| `@text.environment` | #83c092 | - |  | - |
| `@text.environment.name` | #dbbc7f | - |  | - |
| `@text.gitcommit` | #d3c6aa | - |  | - |
| `@text.html` | #d3c6aa | - |  | - |
| `@text.literal` | #a7c080 | - |  | - |
| `@text.math` | #7fbbb3 | - |  | - |
| `@text.note` | #2d353b | #a7c080 | bold | - |
| `@text.reference` | #83c092 | - |  | - |
| `@text.strike` | #859289 | - | strikethrough | - |
| `@text.strong` | - | - | bold | - |
| `@text.title` | #e69875 | - | bold | - |
| `@text.todo` | #2d353b | #7fbbb3 | bold | - |
| `@text.todo.checked` | #a7c080 | - |  | - |
| `@text.todo.unchecked` | #859289 | - |  | - |
| `@text.underline` | - | - | underline | - |
| `@text.uri` | #7fbbb3 | - | underline | - |
| `@text.warning` | #2d353b | #dbbc7f | bold | - |
| `@todo` | #2d353b | #7fbbb3 | bold | - |
| `@type` | #dbbc7f | - |  | yes |
| `@type.builtin` | #dbbc7f | - |  | yes |
| `@type.definition` | #dbbc7f | - |  | yes |
| `@type.qualifier` | #e69875 | - |  | - |
| `@uri` | #7fbbb3 | - | underline | - |
| `@variable` | #d3c6aa | - |  | yes |
| `@variable.builtin` | #d699b6 | - |  | yes |
| `@variable.member` | #7fbbb3 | - |  | yes |
| `@variable.member.yaml` | #a7c080 | - |  | yes |
| `@variable.parameter` | #d3c6aa | - |  | yes |
| `@variable.parameter.builtin` | #dbbc7f | - |  | yes |

## 3. 已装插件的高亮组

| group | fg | bg | styles |
|---|---|---|---|
| `BlinkCmpKindArray` | #83c092 | - |  |
| `BlinkCmpKindBoolean` | #83c092 | - |  |
| `BlinkCmpKindClass` | #dbbc7f | - |  |
| `BlinkCmpKindColor` | #83c092 | - |  |
| `BlinkCmpKindConstant` | #7fbbb3 | - |  |
| `BlinkCmpKindConstructor` | #a7c080 | - |  |
| `BlinkCmpKindDefault` | #83c092 | - |  |
| `BlinkCmpKindEnum` | #dbbc7f | - |  |
| `BlinkCmpKindEnumMember` | #d699b6 | - |  |
| `BlinkCmpKindEvent` | #e69875 | - |  |
| `BlinkCmpKindField` | #a7c080 | - |  |
| `BlinkCmpKindFile` | #a7c080 | - |  |
| `BlinkCmpKindFolder` | #83c092 | - |  |
| `BlinkCmpKindFunction` | #a7c080 | - |  |
| `BlinkCmpKindInterface` | #dbbc7f | - |  |
| `BlinkCmpKindKey` | #e67e80 | - |  |
| `BlinkCmpKindKeyword` | #e67e80 | - |  |
| `BlinkCmpKindMethod` | #a7c080 | - |  |
| `BlinkCmpKindModule` | #dbbc7f | - |  |
| `BlinkCmpKindNamespace` | #d699b6 | - |  |
| `BlinkCmpKindNull` | #83c092 | - |  |
| `BlinkCmpKindNumber` | #83c092 | - |  |
| `BlinkCmpKindObject` | #83c092 | - |  |
| `BlinkCmpKindOperator` | #e69875 | - |  |
| `BlinkCmpKindPackage` | #d699b6 | - |  |
| `BlinkCmpKindProperty` | #7fbbb3 | - |  |
| `BlinkCmpKindReference` | #83c092 | - |  |
| `BlinkCmpKindSnippet` | #83c092 | - |  |
| `BlinkCmpKindString` | #83c092 | - |  |
| `BlinkCmpKindStruct` | #dbbc7f | - |  |
| `BlinkCmpKindText` | #d3c6aa | - |  |
| `BlinkCmpKindTypeParameter` | #dbbc7f | - |  |
| `BlinkCmpKindUnit` | #d699b6 | - |  |
| `BlinkCmpKindValue` | #d699b6 | - |  |
| `BlinkCmpKindVariable` | #7fbbb3 | - |  |
| `BlinkCmpLabelMatch` | #a7c080 | - | bold |
| `CmpItemAbbr` | #d3c6aa | - |  |
| `CmpItemAbbrDeprecated` | #859289 | - |  |
| `CmpItemAbbrMatch` | #a7c080 | - | bold |
| `CmpItemAbbrMatchFuzzy` | #a7c080 | - | bold |
| `CmpItemKind` | #dbbc7f | - |  |
| `CmpItemKindArray` | #83c092 | - |  |
| `CmpItemKindBoolean` | #83c092 | - |  |
| `CmpItemKindClass` | #dbbc7f | - |  |
| `CmpItemKindColor` | #83c092 | - |  |
| `CmpItemKindConstant` | #7fbbb3 | - |  |
| `CmpItemKindConstructor` | #a7c080 | - |  |
| `CmpItemKindDefault` | #83c092 | - |  |
| `CmpItemKindEnum` | #dbbc7f | - |  |
| `CmpItemKindEnumMember` | #d699b6 | - |  |
| `CmpItemKindEvent` | #e69875 | - |  |
| `CmpItemKindField` | #a7c080 | - |  |
| `CmpItemKindFile` | #a7c080 | - |  |
| `CmpItemKindFolder` | #83c092 | - |  |
| `CmpItemKindFunction` | #a7c080 | - |  |
| `CmpItemKindInterface` | #dbbc7f | - |  |
| `CmpItemKindKey` | #e67e80 | - |  |
| `CmpItemKindKeyword` | #e67e80 | - |  |
| `CmpItemKindMethod` | #a7c080 | - |  |
| `CmpItemKindModule` | #dbbc7f | - |  |
| `CmpItemKindNamespace` | #d699b6 | - |  |
| `CmpItemKindNull` | #83c092 | - |  |
| `CmpItemKindNumber` | #83c092 | - |  |
| `CmpItemKindObject` | #83c092 | - |  |
| `CmpItemKindOperator` | #e69875 | - |  |
| `CmpItemKindPackage` | #d699b6 | - |  |
| `CmpItemKindProperty` | #7fbbb3 | - |  |
| `CmpItemKindReference` | #83c092 | - |  |
| `CmpItemKindSnippet` | #83c092 | - |  |
| `CmpItemKindString` | #83c092 | - |  |
| `CmpItemKindStruct` | #dbbc7f | - |  |
| `CmpItemKindText` | #d3c6aa | - |  |
| `CmpItemKindTypeParameter` | #dbbc7f | - |  |
| `CmpItemKindUnit` | #d699b6 | - |  |
| `CmpItemKindValue` | #d699b6 | - |  |
| `CmpItemKindVariable` | #7fbbb3 | - |  |
| `CmpItemMenu` | #d3c6aa | - |  |
| `DapUIBreakpointsCurrentLine` | #7fbbb3 | - | bold |
| `DapUIBreakpointsInfo` | #a7c080 | - |  |
| `DapUIBreakpointsPath` | #7fbbb3 | - |  |
| `DapUIDecoration` | #7fbbb3 | - |  |
| `DapUIFloatBorder` | #7fbbb3 | - |  |
| `DapUILineNumber` | #7fbbb3 | - |  |
| `DapUIModifiedValue` | #7fbbb3 | - | bold |
| `DapUIPlayPause` | #a7c080 | #3d484d |  |
| `DapUIRestart` | #a7c080 | #3d484d |  |
| `DapUIScope` | #7fbbb3 | - |  |
| `DapUISource` | #d699b6 | - |  |
| `DapUIStepBack` | #7fbbb3 | #3d484d |  |
| `DapUIStepInto` | #7fbbb3 | #3d484d |  |
| `DapUIStepOut` | #7fbbb3 | #3d484d |  |
| `DapUIStepOver` | #7fbbb3 | #3d484d |  |
| `DapUIStop` | #e67e80 | #3d484d |  |
| `DapUIStoppedThread` | #7fbbb3 | - |  |
| `DapUIThread` | #a7c080 | - |  |
| `DapUIType` | #d699b6 | - |  |
| `DapUIUnavailable` | #859289 | #3d484d |  |
| `DapUIWatchesEmpty` | #e67e80 | - |  |
| `DapUIWatchesError` | #e67e80 | - |  |
| `DapUIWatchesValue` | #a7c080 | - |  |
| `DashboardCenter` | #a7c080 | - |  |
| `DashboardFooter` | #e69875 | - |  |
| `DashboardHeader` | #dbbc7f | - |  |
| `DashboardShortcut` | #e67e80 | - |  |
| `FlashBackdrop` | #859289 | - |  |
| `FlashLabel` | #d699b6 | - | bold,italic |
| `FzfLuaBorder` | #859289 | - |  |
| `GitSignsAdd` | #a7c080 | - |  |
| `GitSignsAddLn` | - | #425047 |  |
| `GitSignsAddNr` | #a7c080 | - |  |
| `GitSignsChange` | #7fbbb3 | - |  |
| `GitSignsChangeLn` | - | #3a515d |  |
| `GitSignsChangeNr` | #7fbbb3 | - |  |
| `GitSignsCurrentLineBlame` | #859289 | - |  |
| `GitSignsDelete` | #e67e80 | - |  |
| `GitSignsDeleteLn` | - | #514045 |  |
| `GitSignsDeleteNr` | #e67e80 | - |  |
| `IblIndent` | #4f585e | - |  |
| `IblScope` | #859289 | - |  |
| `IndentBlanklineChar` | #4f585e | - |  |
| `IndentBlanklineContextChar` | #859289 | - |  |
| `IndentBlanklineSpaceChar` | #4f585e | - |  |
| `IndentBlanklineSpaceCharBlankline` | #4f585e | - |  |
| `LualineModified` | #a7c080 | #343f44 | bold |
| `LualineReadonly` | #859289 | #343f44 |  |
| `MiniAnimateCursor` | - | - | reverse |
| `MiniAnimateNormalFloat` | #d3c6aa | #3d484d |  |
| `MiniClueBorder` | #859289 | #3d484d |  |
| `MiniClueDescGroup` | #dbbc7f | - |  |
| `MiniClueDescSingle` | #d3c6aa | #3d484d |  |
| `MiniClueNextKey` | #d699b6 | - |  |
| `MiniClueNextKeyWithPostkeys` | #e67e80 | - |  |
| `MiniClueSeparator` | #7fbbb3 | - |  |
| `MiniClueTitle` | #d3c6aa | #4f585e | bold |
| `MiniCompletionActiveParameter` | #2d353b | #a7c080 |  |
| `MiniCursorword` | - | #3d484d |  |
| `MiniCursorwordCurrent` | - | #3d484d |  |
| `MiniDepsChangeAdded` | #a7c080 | - |  |
| `MiniDepsChangeRemoved` | #e67e80 | - |  |
| `MiniDepsHints` | #d699b6 | - |  |
| `MiniDepsInfo` | #7fbbb3 | - |  |
| `MiniDepsMsgBreaking` | #dbbc7f | - |  |
| `MiniDepsPlaceholder` | #859289 | - | italic |
| `MiniDepsTitle` | #e69875 | - | bold |
| `MiniDepsTitleError` | - | #514045 |  |
| `MiniDepsTitleSame` | - | #3a515d |  |
| `MiniDepsTitleUpdate` | - | #425047 |  |
| `MiniDiffOverAdd` | - | #425047 |  |
| `MiniDiffOverChange` | #2d353b | #7fbbb3 |  |
| `MiniDiffOverContext` | - | #3a515d |  |
| `MiniDiffOverDelete` | - | #514045 |  |
| `MiniDiffSignAdd` | #a7c080 | - |  |
| `MiniDiffSignChange` | #7fbbb3 | - |  |
| `MiniDiffSignDelete` | #e67e80 | - |  |
| `MiniFilesTitle` | #9da9a0 | #4f585e | bold |
| `MiniHipatternsFixme` | #2d353b | #e67e80 | bold |
| `MiniHipatternsHack` | #2d353b | #dbbc7f | bold |
| `MiniHipatternsNote` | #2d353b | #7fbbb3 | bold |
| `MiniHipatternsTodo` | #2d353b | #a7c080 | bold |
| `MiniIconsAzure` | #7fbbb3 | - |  |
| `MiniIconsBlue` | #7fbbb3 | - |  |
| `MiniIconsCyan` | #83c092 | - |  |
| `MiniIconsGreen` | #a7c080 | - |  |
| `MiniIconsGrey` | #9da9a0 | - |  |
| `MiniIconsOrange` | #e69875 | - |  |
| `MiniIconsPurple` | #d699b6 | - |  |
| `MiniIconsRed` | #e67e80 | - |  |
| `MiniIconsYellow` | #dbbc7f | - |  |
| `MiniIndentscopePrefix` | - | - |  |
| `MiniIndentscopeSymbol` | #859289 | - |  |
| `MiniInputAdded` | #a7c080 | #3d484d |  |
| `MiniInputCaret` | #7fbbb3 | #3d484d |  |
| `MiniInputHide` | #dbbc7f | #3d484d | bold |
| `MiniInputHint` | #859289 | #3d484d |  |
| `MiniInputPrompt` | #d3c6aa | #4f585e | bold |
| `MiniInputSpecial` | #e69875 | #3d484d |  |
| `MiniJump` | #2d353b | #a7c080 |  |
| `MiniJump2dDim` | #859289 | - | italic |
| `MiniJump2dSpot` | #e69875 | - | bold |
| `MiniJump2dSpotAhead` | #83c092 | - |  |
| `MiniJump2dSpotUnique` | #dbbc7f | - | bold |
| `MiniMapNormal` | #d3c6aa | #3d484d |  |
| `MiniMapSymbolCount` | #dbbc7f | - |  |
| `MiniMapSymbolLine` | #e69875 | - | bold |
| `MiniMapSymbolView` | #d3c6aa | - |  |
| `MiniNotifyBorder` | #859289 | #3d484d |  |
| `MiniNotifyNormal` | #d3c6aa | #3d484d |  |
| `MiniNotifyTitle` | #d3c6aa | #4f585e | bold |
| `MiniOperatorsExchangeFrom` | #2d353b | #e67e80 |  |
| `MiniPickPrompt` | #d3c6aa | #3d484d |  |
| `MiniPickPromptCaret` | #7fbbb3 | #3d484d |  |
| `MiniPickPromptPrefix` | #e69875 | #3d484d |  |
| `MiniStarterCurrent` | - | - |  |
| `MiniStarterFooter` | #e69875 | - |  |
| `MiniStarterHeader` | #dbbc7f | - |  |
| `MiniStarterInactive` | #859289 | - | italic |
| `MiniStarterItem` | #d3c6aa | #2d353b |  |
| `MiniStarterItemBullet` | #859289 | - |  |
| `MiniStarterItemPrefix` | #dbbc7f | - |  |
| `MiniStarterQuery` | #7fbbb3 | - |  |
| `MiniStarterSection` | #e69875 | - | bold |
| `MiniStatuslineDevinfo` | #9da9a0 | #343f44 |  |
| `MiniStatuslineFileinfo` | #9da9a0 | #343f44 |  |
| `MiniStatuslineFilename` | #859289 | #343f44 |  |
| `MiniStatuslineInactive` | #859289 | - |  |
| `MiniStatuslineModeCommand` | #2d353b | #83c092 | bold |
| `MiniStatuslineModeInsert` | #2d353b | #d3c6aa | bold |
| `MiniStatuslineModeNormal` | #2d353b | #a7c080 | bold |
| `MiniStatuslineModeOther` | #2d353b | #d699b6 | bold |
| `MiniStatuslineModeReplace` | #2d353b | #e69875 | bold |
| `MiniStatuslineModeVisual` | #2d353b | #e67e80 | bold |
| `MiniSurround` | #2d353b | #e67e80 |  |
| `MiniTablineCurrent` | #d3c6aa | #4f585e |  |
| `MiniTablineFill` | #859289 | #343f44 |  |
| `MiniTablineHidden` | #859289 | #3d484d |  |
| `MiniTablineModifiedCurrent` | #7fbbb3 | #4f585e |  |
| `MiniTablineModifiedHidden` | #859289 | #3d484d |  |
| `MiniTablineModifiedVisible` | #7fbbb3 | #3d484d |  |
| `MiniTablineTabpagesection` | #2d353b | #a7c080 | bold |
| `MiniTablineVisible` | #d3c6aa | #3d484d |  |
| `MiniTestEmphasis` | - | - | bold |
| `MiniTestFail` | #e67e80 | - | bold |
| `MiniTestPass` | #a7c080 | - | bold |
| `MiniTrailspace` | - | #e67e80 |  |
| `NeotestAdapterName` | #e69875 | - | bold |
| `NeotestBorder` | #7fbbb3 | - |  |
| `NeotestDir` | #a7c080 | - |  |
| `NeotestExpandMarker` | #56635f | - |  |
| `NeotestFailed` | #e67e80 | - |  |
| `NeotestFile` | #83c092 | - |  |
| `NeotestFocused` | #dbbc7f | - |  |
| `NeotestIndent` | #4f585e | - |  |
| `NeotestMarked` | #e69875 | - |  |
| `NeotestNamespace` | #d699b6 | - |  |
| `NeotestPassed` | #a7c080 | - |  |
| `NeotestRunning` | #dbbc7f | - |  |
| `NeotestSkipped` | #7fbbb3 | - |  |
| `NeotestTarget` | #e67e80 | - |  |
| `NeotestWinSelect` | #7fbbb3 | - |  |
| `TreesitterContext` | #d3c6aa | #3d484d |  |
| `TreesitterContextLineNumber` | #56635f | - |  |
| `TroubleCode` | #859289 | - |  |
| `TroubleSource` | #859289 | - |  |
| `TroubleText` | #d3c6aa | - |  |
| `WhichKey` | #e67e80 | - |  |
| `WhichKeyDesc` | #7fbbb3 | - |  |
| `WhichKeyFloat` | - | #343f44 |  |
| `WhichKeyGroup` | #dbbc7f | - |  |
| `WhichKeySeparator` | #a7c080 | - |  |
| `WhichKeyValue` | #d3c6aa | - |  |
| `WrfmPreview` | #dbbc7f | - |  |

## 与上游的有意例外

| group | 本机 | 上游渲染 | 原因 |
|---|---|---|---|
| `@keyword.import.go` | purple | red | 上游只映射旧名 `@include.go`，新名掉回通用组；保留上游自己的 `goTSInclude`=purple |
| `@keyword.modifier` | orange | red | 上游只映射旧名 `@type.qualifier`；保留 `TSTypeQualifier`=orange |
| `@string.special.url` | blue + underline | 纯下划线 | 上游只映射旧名 `@string.special.uri`（TSURI = blue + underline） |
| `@markup.strike` `@strike` `@text.strike` | grey1 + strikethrough | grey1 | 上游 `TSStrike`→Grey 漏了 strikethrough（组名就是"删除线"） |
| `@variable.member.yaml` | green | blue | 上游只映射旧名 `@field.yaml`；yaml 查询两个名字都不发，实际不渲染 |
| `@lsp.*`（34 个） | — | — | `lua/plugins/lspconfig.lua` 关闭了 semantic tokens，不渲染，未逐一对齐 |

想要与上游逐 bit 相同：删掉 `lua/plugins/colorscheme.lua` 里对应的钉法（红 / 纯下划线 / 无删除线）。

### 上游没有的组 / 插件层取值不同（信息性）

| group | 本机 | 上游 | 说明 |
|---|---|---|---|
| `FlashBackdrop` | #859289|-| | — | 上游没有这个组（移植版/插件自带） |
| `FlashLabel` | #d699b6|-|bold,italic | — | 上游没有这个组（移植版/插件自带） |
| `LualineModified` | #a7c080|#343f44|bold | — | 上游没有这个组（移植版/插件自带） |
| `LualineReadonly` | #859289|#343f44| | — | 上游没有这个组（移植版/插件自带） |
| `MiniDepsHints` | #d699b6|-| | — | 上游没有这个组（移植版/插件自带） |
| `MiniFilesTitle` | #9da9a0|#4f585e|bold | #9da9a0|#4f585e| | 上游有同名组但取值不同（多为未安装的 mini 模块，不渲染） |
| `MiniInputHide` | #dbbc7f|#3d484d|bold | #dbbc7f|#4f585e|bold | 上游有同名组但取值不同（多为未安装的 mini 模块，不渲染） |
| `MiniStatuslineDevinfo` | #9da9a0|#343f44| | #9da9a0|#475258| | 上游有同名组但取值不同（多为未安装的 mini 模块，不渲染） |
| `MiniStatuslineFileinfo` | #9da9a0|#343f44| | #9da9a0|#475258| | 上游有同名组但取值不同（多为未安装的 mini 模块，不渲染） |
| `NeotestBorder` | #7fbbb3|-| | — | 上游没有这个组（移植版/插件自带） |
| `NeotestFocused` | #dbbc7f|-| | — | 上游没有这个组（移植版/插件自带） |
| `NeotestWinSelect` | #7fbbb3|-| | — | 上游没有这个组（移植版/插件自带） |
| `TreesitterContextLineNumber` | #56635f|-| | — | 上游没有这个组（移植版/插件自带） |
| `WhichKeyFloat` | -|#343f44| | — | 上游没有这个组（移植版/插件自带） |
| `WhichKeySeparator` | #a7c080|-| | — | 上游没有这个组（移植版/插件自带） |
| `WhichKeyValue` | #d3c6aa|-| | — | 上游没有这个组（移植版/插件自带） |
| `WrfmPreview` | #dbbc7f|-| | — | 上游没有这个组（移植版/插件自带） |
| `AquaBold` | #83c092|-|bold | — | 上游没有这个组（移植版/插件自带） |
| `BlueBold` | #7fbbb3|-|bold | — | 上游没有这个组（移植版/插件自带） |
| `GreenBold` | #a7c080|-|bold | — | 上游没有这个组（移植版/插件自带） |
| `OrangeBold` | #e69875|-|bold | — | 上游没有这个组（移植版/插件自带） |
| `PurpleBold` | #d699b6|-|bold | — | 上游没有这个组（移植版/插件自带） |
| `RedBold` | #e67e80|-|bold | — | 上游没有这个组（移植版/插件自带） |
| `TermCursorNC` | #2d353b|#d3c6aa| | — | 上游没有这个组（移植版/插件自带） |
| `YellowBold` | #dbbc7f|-|bold | — | 上游没有这个组（移植版/插件自带） |

## 生成方法（供将来复现）

1. 取上游：`sainnhe/everforest` 的 `colors/everforest.vim` 与 `autoload/everforest.vim` 放进一个临时目录，
   记下 `colors/everforest.vim` 的 sha256（即上面的 reference 行）；
2. 渲染上游：`nvim --headless -u NONE --cmd "set rtp+=<临时目录>" --cmd 'set termguicolors background=dark' -c 'colorscheme everforest'`；
   每个组取 `synIDattr(synIDtrans(hlID(name)), "fg#")`、`"bg#"`、`"sp#"` 以及 bold/italic/underline/… 样式
   （`synIDtrans` 会跟随 link，也覆盖 nvim 对 `@capture.lang` 退回通用组的行为）；
3. 用同一份组名清单、同样方式渲染本机配置，逐组比较 fg / bg / sp / 样式四个字段；
4. 差异只应剩下上面「与上游的有意例外」一节列出的那几条。
