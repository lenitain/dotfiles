-- 0. 镜像钩子统一在 config.proxy, 这里只需要 require, 后续不再各自拼前缀
local proxy = require("config.proxy")

-- 1. 安装 lazy.nvim (使用代理)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    proxy.PROXY_PREFIX .. "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. 插件清单
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },

  -- 3. 其他配置
  git = {
    -- 与 config.proxy.PROXY_PREFIX / .GITHUB_PREFIX 同源; 换镜像改 proxy.lua 即可
    url_format = proxy.PROXY_PREFIX .. proxy.GITHUB_PREFIX .. "%s.git",
  },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
