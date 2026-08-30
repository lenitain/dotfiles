-- 搜索计数：只显示当前匹配的 [当前/总数]，如 [3/10]
-- - 只给当前匹配加计数（nearest_only），去掉其它匹配上的 [3n 5] 方向指示
-- - override_lens 只渲染 [3/10]，无方向箭头
-- - 计数文本使用无背景样式（HlSearchLensNear 不再链接 CurSearch，去掉"选中"底色）
return {
  "kevinhwang91/nvim-hlslens",
  event = "VeryLazy",
  opts = {
    -- 只显示当前匹配的计数，忽略其它匹配
    nearest_only = true,
    -- 自定义渲染：只输出 [3/10]
    override_lens = function(render, posList, nearest, idx)
      if not nearest then
        return
      end
      local lnum, col = unpack(posList[idx])
      local text = ("[%d/%d]"):format(idx, #posList)
      render.setVirt(0, lnum - 1, col - 1, {
        { " ", "Ignore" },
        { text, "HlSearchLensNear" },
      }, true)
    end,
  },
  config = function(_, opts)
    -- 计数 [3/10]：从主题取蓝色（everforest 中 Identifier = palette.blue = #7fbbb3），
    -- 无背景、无样式，纯文字颜色；link 方式保证换主题/变体时自动跟随
    vim.api.nvim_set_hl(0, "HlSearchLensNear", { link = "Identifier" })
    require("hlslens").setup(opts)
  end,
}
