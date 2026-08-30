-- Markdown 浏览器实时预览（纯 Lua，无 Node 依赖；公式/图表等前端库运行时走 CDN）
return {
  "selimacerbas/markdown-preview.nvim",
  dependencies = { "selimacerbas/live-server.nvim" },
  cmd = { "MarkdownPreview", "MarkdownPreviewRefresh", "MarkdownPreviewStop" },
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreview<cr>", desc = "Markdown 预览" },
  },
  opts = {},
}
