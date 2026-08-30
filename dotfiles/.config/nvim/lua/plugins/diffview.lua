return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
    { "<leader>gfh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview File History" },
    { "<leader>gfH", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview Current File History" },
    { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
  },
  opts = {
    enhanced_diff_hl = true,
    -- 单文件历史默认用 first-parent；这里改为 combined 以展示合并提交的完整改动
    file_history_panel = {
      log_options = {
        git = { single_file = { diff_merges = "combined" } },
      },
    },
  },
}
