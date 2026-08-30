-- GitHub 直链下载统一改走镜像. 镜像域名换这里一处, 别处不用动.
--
-- 装三条钩子: vim.system / vim.fn.system / vim.fn.systemlist. 只对首参数为
-- curl/wget 的 table 形式 cmd 起作用, 其它原样透传, 不影响普通 shell 调用.
-- 钩子幂等: 本文件多次 require 只会装一次.
--
-- 匹配 host: github.com / api.github.com / raw.githubusercontent.com /
-- codeload.github.com / avatars.githubusercontent.com /
-- desktop.githubusercontent.com / gist.githubusercontent.com /
-- objects.githubusercontent.com (gh-proxy.org 实测都支持).
--
-- 作用域对照:
--   这三条子进程钩子   ── nvim 的 vim.fn.system / vim.system 调起的子进程
--   ~/.config/git/config 的 url.*.insteadOf
--                        ── 裸 git clone/fetch 走的 URL 改写
--   ~/.config/mise/conf.d/mirrors.toml 的 [settings.url_replacements]
--                        ── 经 mise HTTP 客户端的下载 (aqua / ubi / github / 自更新)
-- 三处换镜像时要同改 (见 conf.d/mirrors.toml 顶注).

local M = {}

-- 镜像域名, 换镜像时改这一行.
M.PROXY_PREFIX = "https://gh-proxy.org/"

-- git clone URL 用的标准前缀 (lazy.nvim url_format 会拼 "%s.git").
M.GITHUB_PREFIX = "https://github.com/"

-- 经 curl / wget 直拉时, 这些 host 一律走镜像.
local GITHUB_HOSTS = {
  "github.com",
  "api.github.com",
  "raw.githubusercontent.com",
  "codeload.github.com",
  "avatars.githubusercontent.com",
  "desktop.githubusercontent.com",
  "gist.githubusercontent.com",
  "objects.githubusercontent.com",
}

local function is_github_url(arg)
  if type(arg) ~= "string" then return false end
  local host = arg:match("^https?://([^/]+)/")
  if not host then return false end
  for _, h in ipairs(GITHUB_HOSTS) do
    if host == h then return true end
  end
  return false
end

local function rewrite(cmd)
  if type(cmd) ~= "table" then return cmd end
  if cmd[1] ~= "curl" and cmd[1] ~= "wget" then return cmd end
  local out = vim.list_extend({}, cmd)
  for i, arg in ipairs(out) do
    if is_github_url(arg) then
      out[i] = M.PROXY_PREFIX .. arg
    end
  end
  return out
end

local installed = false
local function install()
  if installed then return end
  installed = true

  local raw_system = vim.system
  vim.system = function(cmd, opts, on_exit)
    return raw_system(rewrite(cmd), opts, on_exit)
  end

  local raw_fn_system = vim.fn.system
  vim.fn.system = function(cmd, ...)
    return raw_fn_system(rewrite(cmd), ...)
  end

  local raw_fn_systemlist = vim.fn.systemlist
  vim.fn.systemlist = function(cmd, ...)
    return raw_fn_systemlist(rewrite(cmd), ...)
  end
end

install()

return M
