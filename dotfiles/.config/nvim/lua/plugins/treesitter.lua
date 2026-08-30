return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    -- 语言列表：添加新语言只需在这里加一项
    local languages = {
      "rust", "c", "cpp", "python",
      "javascript", "typescript", "tsx",
      "html", "css", "json", "yaml", "toml",
      "markdown", "markdown_inline",
      "zig", "go", "typst",
      "lua", "luadoc", "luap", "vim", "vimdoc",
      "bash", "diff", "regex", "query", "jsdoc", "xml",
    }

    require("nvim-treesitter").setup {
      install_dir = vim.fn.stdpath("data") .. "/site",
    }

    require("nvim-treesitter").install(languages)

    -- 高亮 + 缩进
    vim.api.nvim_create_autocmd("FileType", {
      pattern = languages,
      callback = function()
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
