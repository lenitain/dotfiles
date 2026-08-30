return {
  "nvim-pack/nvim-spectre",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = "Spectre",
  keys = {
    { "<leader>rr", function() require("spectre").open() end, desc = "Replace in Files (Spectre)" },
    { "<leader>sw", function() require("spectre").open_visual({ select_word = true }) end, desc = "Search Word" },
  },
}
