return {
  "saghen/blink.cmp",
  -- optional: provides snippets for the snippet source
  dependencies = { "rafamadriz/friendly-snippets" },
  -- use a release tag to download pre-built binaries
  version = "1.*",
  -- 借道 gh-proxy 镜像预下载模糊匹配库（GitHub 直链大文件在本机会卡死）
  build = function(plugin)
    local tag = vim.trim(vim.fn.system({ "git", "describe", "--tags", "--exact-match" }))
    if vim.v.shell_error ~= 0 or tag == "" then return end
    local rel = plugin.dir .. "/target/release/"
    local ok, ver = pcall(vim.fn.readfile, rel .. "version")
    if ok and ver[1] == tag and vim.uv.fs_stat(rel .. "libblink_cmp_fuzzy.so") then return end
    local url = "https://gh-proxy.com/https://github.com/saghen/blink.cmp/releases/download/" .. tag
    vim.fn.mkdir(rel, "p")
    vim.fn.system({ "wget", "-qT", "60", "-O", rel .. "libblink_cmp_fuzzy.so", url .. "/x86_64-unknown-linux-gnu.so" })
    assert(vim.v.shell_error == 0, "libblink_cmp_fuzzy.so 下载失败")
    vim.fn.system({ "wget", "-qT", "60", "-O", rel .. "libblink_cmp_fuzzy.so.sha256", url .. "/x86_64-unknown-linux-gnu.so.sha256" })
    local f = io.open(rel .. "version", "wb")
    f:write(tag)
    f:close()
  end,

  ---@module "blink.cmp"
  ---@type blink.cmp.Config
  opts = {
    -- 补全行为沿用上游默认，且命令区与编辑区完全一致：
    --   菜单随输入自动弹出并预选第一项（仅高亮+ghost 行内预览，不写入文本），
    --   方向键/C-n/C-p/Tab/S-Tab 切换，<C-y> 才真正填入；
    --   Enter 恒为原生行为（编辑区换行、命令区直接执行命令）
    keymap = {
      -- default preset 的 Tab 只管片段跳转：菜单开着时会在编辑区插入字面制表符、
      -- 在命令区被过滤后唤出原生 wildmenu。显式加上候选切换，两区统一由候选框接管
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
      documentation = { auto_show = false, window = { border = "rounded" } },
      -- Ghost text to preview completion
      ghost_text = { enabled = true },
      -- 移动候选只更新高亮与 ghost 预览，不写文本；<C-y> 才填入，
      -- 避免污染撤销历史/命令行文本
      list = {
        selection = { auto_insert = false },
      },
      -- Menu appearance
      menu = {
        border = "rounded",
        draw = {
          columns = {
            { "label", "label_description", gap = 1 },
            { "kind_icon", "kind", gap = 1 },
          },
        },
      },
    },

    -- Default list of providers
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead: https://github.com/Saghen/blink.cmp/blob/main/lua/blink/cmp/fuzzy/lua.lua
    fuzzy = {
      implementation = "prefer_rust_with_warning",
      prebuilt_binaries = {
        -- 兜底：直链下载限时 30s，超时回退 lua 实现而非永久卡死补全
        extra_curl_args = { "--max-time", "30" },
      },
    },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true, window = { border = "rounded" } },

    -- Command-line (: ) 补全与编辑区行为完全一致：
    --   inherit 继承编辑区同一套键位（default preset），selection 沿用默认的预选+预插入
    cmdline = {
      keymap = { preset = "inherit" },
      completion = {
        trigger = {
          -- 空格等分隔符不隐藏菜单，保持与编辑区一致的持续弹出体验
          show_on_blocked_trigger_characters = {},
          show_on_x_blocked_trigger_characters = {},
        },
        menu = { auto_show = true },
        -- cmdline 不继承全局 selection，需同样关闭预插入
        list = {
          selection = { auto_insert = false },
        },
      },
    },
  },
  opts_extend = { "sources.default" },
}