-- Markdown 浏览器实时预览（纯 Lua，无 Node 依赖；公式/图表等前端库运行时走 CDN）
-- 原 markdown-preview.nvim 已于 2.0.0 改名为 mdkite.nvim，命令统一为 :MdKite
return {
  "selimacerbas/mdkite.nvim",
  dependencies = { "selimacerbas/kitehost.nvim" },
  cmd = { "MdKite" },
  keys = {
    { "<leader>mp", "<cmd>MdKite start<cr>", desc = "Markdown 预览" },
  },
  opts = {},
}
