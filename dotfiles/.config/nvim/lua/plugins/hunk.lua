-- 折叠式文件树：真分栏（不是浮窗）。<leader>e 只负责打开并聚焦，
-- 收起由「焦点离开树」自动完成（不做 toggle）。
-- hunk 的 split 模式下 Component.close()/toggle() 只会聚焦、不会隐藏，
-- 所以这里自己管窗口：收起 = 关掉窗口，展开 = 最左边重建竖分屏。
local TREE_WIDTH = 35

local tree_buf    -- 树 buffer（关窗后 buffer 仍在，映射与内容都保留）
local tree_opts   -- hunk 传给 ui.tree.create 的 opts 表：改写其 winid 才能让
                  -- hunk 内部的 Component.focus()/toggle() 继续指向有效窗口
local tree_cursor -- 收起前的树内光标，展开时还原
local armed = false -- 启动阶段 hunk 自己会切窗口，此时不许自动收起

local function tree_win()
  local win = tree_opts and tree_opts.winid
  if win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == tree_buf then
    return win
  end
end

local function other_win()
  local win = tree_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= win then
      return w
    end
  end
end

-- 树收起后剩余两栏均分，展开后树固定 35 列、其余均分
local function equalize()
  local win = tree_win()
  local others = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= win then
      table.insert(others, w)
    end
  end

  local width = math.floor((vim.o.columns - (win and TREE_WIDTH or 0)) / #others)
  for _, w in ipairs(others) do
    vim.api.nvim_win_set_width(w, width)
  end
  if win then
    vim.api.nvim_win_set_width(win, TREE_WIDTH)
  end
end

local function expand()
  if tree_win() then
    vim.api.nvim_set_current_win(tree_win())
    return
  end

  vim.cmd("topleft vertical split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, tree_buf)
  vim.api.nvim_set_option_value("winfixwidth", true, { win = win })
  tree_opts.winid = win
  equalize()

  if tree_cursor then
    vim.api.nvim_win_set_cursor(win, tree_cursor)
  end
  vim.api.nvim_set_current_win(win)
end

local function collapse()
  local win = tree_win()
  if not win then
    return
  end

  tree_cursor = vim.api.nvim_win_get_cursor(win)
  -- 指向一个仍存活的窗口，避免 hunk 内部 focus() 落到已关闭的窗口上
  tree_opts.winid = other_win() or win
  vim.api.nvim_win_hide(win)
  equalize()
end

-- hunk 会在 tree.create 之后才给 buffer 装自己的 <leader>e（只会聚焦原窗口），
-- 所以推迟到下一轮事件循环再覆盖，改用能重建窗口的 expand()
local function bind_tree_key(buf)
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.keymap.set("n", "<leader>e", expand, {
        buffer = buf,
        nowait = true,
        desc = "打开并聚焦 hunk 文件树",
      })
    end
  end)
end

return {
  "julienvincent/hunk.nvim",
  -- 主要作为 jj 的 diff-editor 使用，因此按命令懒加载
  cmd = { "HunkDiffView", "HunkDiffEditor" },
  dependencies = {
    "MunifTanjim/nui.nvim",
    -- 文件树图标（可选依赖，这里显式声明以保证 require 时已在 rtp 中）
    "nvim-tree/nvim-web-devicons",
  },
  init = function()
    -- 焦点一离开树（切到 diff 窗格、去选文本、换窗口）就收起
    vim.api.nvim_create_autocmd("WinEnter", {
      group = vim.api.nvim_create_augroup("HunkTreeCollapse", { clear = true }),
      callback = function()
        if not armed then
          return
        end
        -- 不能在 WinEnter 里同步关窗；而且 hunk 的 preview 会先短暂切到 diff
        -- 窗口再把焦点还给树（l 预览），所以要等这一轮事件结束后再确认焦点
        vim.schedule(function()
          local win = tree_win()
          if armed and win and vim.api.nvim_get_current_win() ~= win then
            collapse()
          end
        end)
      end,
    })
  end,
  opts = {
    ui = {
      tree = {
        -- 目录展示方式：nested（逐层展开）/ flat（完整路径）/ compact（合并单链目录）
        mode = "compact",
        width = TREE_WIDTH,
        -- 固定分栏；展开与自动收起由本文件接管
        use_float = false,
      },
      -- vertical = 左右对比（垂直分屏）；horizontal = 上下对比
      layout = "vertical",
      -- 退出前二次确认，避免误按 q 丢弃已选内容
      confirm_before_quit = false,
    },
    hooks = {
      on_tree_mount = function(context)
        tree_buf = context.buf
        tree_opts = context.opts
        tree_cursor = nil
        armed = false

        bind_tree_key(context.buf)

        -- 启动保持展开（初始界面就有文件树）；等 hunk 自己的布局动作
        -- 都结束后再启用"焦点离开即收起"
        vim.schedule(function()
          armed = true
        end)
      end,
      on_diff_mount = function(context)
        bind_tree_key(context.buf)
      end,
    },
  },
}
