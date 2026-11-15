-- ~/.config/nvim/lua/plugins/lualine.lua
return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      -- 用主题自带的 lualine 配色：移植版 lua/lualine/themes/everforest.lua 与上游
      -- sainnhe 的 lua/lualine/themes/everforest.lua **内容完全一致**（逐行对过），
      -- 所以这里直接用 auto，不做任何二次定制。
      theme = "auto",
      -- 其他 lualine 配置...
    },
    sections = {
      -- 左侧：默认是 branch + diff + diagnostics，这里去掉 branch（分支名已靠其他方式查看）
      lualine_b = { "diff", "diagnostics" },
      -- 中间状态栏显示文件完整路径
      -- path = 3 绝对路径，home 缩写为 ~ | path = 2 绝对路径 | path = 1 相对路径 | path = 0 仅文件名
      lualine_c = {
        {
          "filename",
          path = 3,
          -- 未保存/只读标记用高亮色显示（颜色在下方 config 里定义）
          symbols = {
            modified = "%#LualineModified#●",
            readonly = "%#LualineReadonly#[-]",
            unnamed = "[No Name]",
            newfile = "[New]",
          },
        },
      },
      -- 右侧：encoding + filetype
      -- 去掉了默认的 fileformat（unix/dos/mac 换行图标，就是那个企鹅）
      lualine_x = { "encoding", "filetype" },
      -- 默认的 progress（Top/Bot/百分比）换成行/总行:列
      -- %L 是 Vim 原生 statusline 的总行数；%3l、%-2c 的宽度对齐模仿自带的 location
      lualine_y = {},
      lualine_z = { "%3l/%L:%-2c" },
    },
  },
  config = function(_, opts)
    -- 先 setup，让 lualine 生成各段的背景色
    require("lualine").setup(opts)
    -- 取某高亮组的某个颜色属性，带兜底
    local function get(name, what, fallback)
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
      if ok and hl and hl[what] then
        return hl[what]
      end
      return fallback
    end
    -- 未保存圆点：绿色前景 + 继承状态栏段背景，避免出现独立高亮块
    -- 背景取自文件名所在的 lualine_c_normal，这样圆点融入状态栏、只有颜色是绿色
    vim.api.nvim_set_hl(0, "LualineModified", {
      fg = get("DiagnosticOk", "fg", "#a7c080"),
      bg = get("lualine_c_normal", "bg"),
      bold = true,
    })
    vim.api.nvim_set_hl(0, "LualineReadonly", {
      fg = get("Comment", "fg", "#7a7a7a"),
      bg = get("lualine_c_normal", "bg"),
    })
  end,
}
