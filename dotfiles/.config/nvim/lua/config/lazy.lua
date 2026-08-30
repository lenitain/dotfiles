-- 0. 子进程（curl/wget）对 github.com 的直链下载统一改走 gh-proxy 镜像
--    覆盖 treesitter 解析器 tarball 等插件自带的网络下载（本机直连大文件会卡死）
local raw_system = vim.system
local GITHUB_PREFIX = "https://github.com/"
vim.system = function(cmd, opts, on_exit)
  if type(cmd) == "table" and (cmd[1] == "curl" or cmd[1] == "wget") then
    for i, arg in ipairs(cmd) do
      if type(arg) == "string" and arg:sub(1, #GITHUB_PREFIX) == GITHUB_PREFIX then
        cmd[i] = "https://gh-proxy.com/" .. arg
      end
    end
  end
  return raw_system(cmd, opts, on_exit)
end

-- 1. 安装 lazy.nvim（使用代理）
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://gh-proxy.com/https://github.com/folke/lazy.nvim.git",
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
    url_format = "https://gh-proxy.com/https://github.com/%s.git",
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
