return {
  { "mattn/vim-moonbit" },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        moonbit_ls = {},
      },
      setup = {
        moonbit_ls = function()
          local lspconfig = require("lspconfig")
          local configs = require("lspconfig.configs")

          if not configs.moonbit_ls then
            configs.moonbit_ls = {
              default_config = {
                cmd = { "moonbit-lsp" },
                filetypes = { "moonbit" },
                root_dir = lspconfig.util.root_pattern("moon.mod.json", ".git"),
              },
            }
          end

          lspconfig.moonbit_ls.setup({})
          return true
        end,
      },
    },
  },
}
