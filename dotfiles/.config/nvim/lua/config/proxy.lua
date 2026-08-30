-- GitHub 直链下载统一改走镜像. 镜像域名换这里一处, 别处不用动.
--
-- 装四条钩子: vim.system / vim.fn.system / vim.fn.systemlist / vim.fn.jobstart.
-- 覆盖 nvim 里发起下载的两种写法:
--   table 形式  vim.system({ "curl", url })     —— 命令 + 参数
--   string 形式 vim.fn.system("curl " .. url)  —— 整条命令文本
-- 两条路径共用同一条规则: curl / wget 命令里出现的 GitHub URL 一律换成镜像地址,
-- 其它命令原样透传, 不影响普通 shell 调用.
-- 钩子幂等: 本文件多次 require 只会装一次.
--
-- 匹配 host: github.com / api.github.com / raw.githubusercontent.com /
-- codeload.github.com / avatars.githubusercontent.com /
-- desktop.githubusercontent.com / gist.githubusercontent.com /
-- objects.githubusercontent.com (gh-proxy.org 实测都支持).
--
-- 作用域对照:
--   这四条子进程钩子   ── nvim 的子进程调用
--   ~/.config/git/config 的 url.*.insteadOf
--                        ── 裸 git clone/fetch 走的 URL 改写
--   ~/.config/mise/conf.d/mirrors.toml 的 [settings.url_replacements]
--                        ── 经 mise HTTP 客户端的下载 (aqua / ubi / github / 自更新)
-- 三处换镜像时要同改 (见 conf.d/mirrors.toml 顶注).
--
-- 覆盖不到的: 起终端 (termopen) 和直接调 libuv spawn 的代码 —— 那两条路拿不到
-- 命令文本, 只能由调用方自己把 URL 写成镜像地址.

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

-- 下载命令前可能出现的包装词; 判断命令身份时跳过它们.
local COMMAND_WRAPPERS = { "command", "env", "exec", "nohup", "sudo", "time" }

-- URL 词元: https? 开头, 字符集取 RFC 3986 的 unreserved + reserved, 不含空白与
-- 引号, 免得把 shell 的引号和分隔符卷进 URL.
local URL_PATTERN = "https?://[%w%-%._~:/?#@!$&'*+%%=]+"

-- URL 的 host 是否属于 GitHub 系.
local function is_github_url(url)
  local host = url:match("^https?://([^/]+)")
  return host ~= nil and vim.tbl_contains(GITHUB_HOSTS, host)
end

-- 给 GitHub URL 加镜像前缀, 其它 URL 原样返回.
local function proxy_url(url)
  if is_github_url(url) then
    return M.PROXY_PREFIX .. url
  end
  return url
end

-- 命令里第一个真正的命令词: 跳过环境变量赋值与包装词.
local function command_word(tokens)
  for _, token in ipairs(tokens) do
    if type(token) ~= "string" then
      return nil
    end
    local bare = token:gsub("^[\"']", ""):gsub("[\"']$", "")
    local is_assignment = bare:match("^[%w_]+=") ~= nil
    if not is_assignment and not vim.tbl_contains(COMMAND_WRAPPERS, bare) then
      return bare
    end
  end
  return nil
end

-- 这条命令是不是下载命令 (curl / wget).
local function is_download(tokens)
  local word = command_word(tokens)
  return word == "curl" or word == "wget"
end

-- 把一段文本里的所有 GitHub URL 换成镜像地址.
local function proxy_urls(text)
  local rewritten = text:gsub(URL_PATTERN, proxy_url)
  return rewritten
end

-- 入口: 按参数形态分派 —— string 是整条命令, table 是 argv.
local function rewrite(cmd)
  if type(cmd) == "string" then
    if not is_download(vim.split(cmd, "%s+", { trimempty = true })) then
      return cmd
    end
    return proxy_urls(cmd)
  end

  if type(cmd) ~= "table" then
    return cmd
  end

  if type(cmd[1]) == "table" then
    -- jobstart 的多命令形式: 每个元素是一条独立命令.
    local out = vim.list_extend({}, cmd)
    for i, sub in ipairs(out) do
      out[i] = rewrite(sub)
    end
    return out
  end

  if not is_download(cmd) then
    return cmd
  end
  local out = vim.list_extend({}, cmd)
  for i, arg in ipairs(out) do
    if type(arg) == "string" then
      out[i] = proxy_urls(arg)
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

  -- jobstart 的命令可以是字符串或 argv, 两种形态都走同一个 rewrite.
  local raw_fn_jobstart = vim.fn.jobstart
  vim.fn.jobstart = function(cmd, ...)
    return raw_fn_jobstart(rewrite(cmd), ...)
  end
end

install()

return M
