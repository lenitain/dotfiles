return {
	"neovim/nvim-lspconfig",
	event = "BufReadPre",
	config = function()
		-- 让所有 LSP 客户端异步启动：
		-- nvim 的 vim.lsp.enable 自动启动回调里，只有当 config.root_dir 是
		-- 函数时才会把真正的客户端启动 vim.schedule 到事件循环（异步）；
		-- root_dir 为 nil/字符串时是同步启动，会阻塞文件打开的 :e。
		-- 这里给每个服务器配一个"函数式 root_dir"（用 vim.fs.root 查项目根，
		-- 找不到时回退到 cwd），既保留正确的根目录识别，又把进程启动移出
		-- 打开文件的同步路径 —— 首次打开某语言文件不再卡顿。
		local function async_root_dir(markers)
			return function(bufnr, on_dir)
				local root = markers and vim.fs.root(bufnr, markers) or nil
				on_dir(root or vim.uv.cwd())
			end
		end

		-- LSP 服务器列表：{ name, executable, settings?, filetypes?, root_markers? }
		-- 添加新语言只需加一行，没装就静默跳过
		local servers = {
			{
				name = "lua_ls",
				executable = "lua-language-server",
				settings = {
					Lua = { diagnostics = { globals = { "vim" } } },
				},
				root_markers = { ".luarc.json", ".git" },
			},
			{ name = "tinymist", executable = "tinymist", root_markers = { "typst.toml", ".git" } },
			{
				name = "clangd",
				executable = "clangd",
				root_markers = { "compile_commands.json", "compile_flags.txt", "CMakeLists.txt", ".git" },
			},

			-- Zig
			{ name = "zls", executable = "zls", root_markers = { "build.zig", "build.zig.zon", ".git" } },

			-- Go
			{ name = "gopls", executable = "gopls", root_markers = { "go.mod", ".git" } },

			-- Python
			{
				name = "pyright",
				executable = "pyright",
				root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
			},
			{
				name = "ruff",
				executable = "ruff",
				root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
			},

			-- TypeScript / JavaScript
			{
				name = "ts_ls",
				executable = "typescript-language-server",
				settings = (function()
					local inlay_hints = {
						includeInlayParameterNameHints = "all",
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					}
					return {
						typescript = {
							inlayHints = inlay_hints,
							preferences = {
								includeModuleStringForFullImport = true,
								preferTypeOnlyAutoImports = true,
							},
						},
						javascript = { inlayHints = inlay_hints },
					}
				end)(),
				root_markers = { "package.json", "tsconfig.json", ".git" },
			},

			-- HTML / CSS
			{ name = "html", executable = "html-languageserver", root_markers = { "package.json", ".git" } },
			{ name = "cssls", executable = "css-languageserver", root_markers = { "package.json", ".git" } },

			-- Moonbit (不在 lspconfig, 需手动配置 cmd/filetypes)
			{
				name = "moonbit",
				executable = "moon-lsp",
				cmd = { "moon-lsp" },
				filetypes = { "moonbit" },
				root_markers = { "moon.mod.json", ".git" },
			},
		}

		-- 配置并启用存在的 LSP
		local enabled = {}
		for _, s in ipairs(servers) do
			if vim.fn.executable(s.executable) == 1 then
				local config = { settings = s.settings or {} }
				if s.cmd then
					config.cmd = s.cmd
				end
				if s.filetypes then
					config.filetypes = s.filetypes
				end
				config.root_dir = async_root_dir(s.root_markers)
				vim.lsp.config(s.name, config)
				table.insert(enabled, s.name)
			end
		end
		vim.lsp.enable(enabled)

		-- LSP 快捷键
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local bufnr = args.buf
				local map = function(keys, func, desc)
					vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
				end

				-- 通用
				map("gd", vim.lsp.buf.definition, "Goto Definition")
				map("gr", vim.lsp.buf.references, "References")
				map("gI", vim.lsp.buf.implementation, "Goto Implementation")
				map("K", vim.lsp.buf.hover, "Hover Documentation")
				map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
				map("<leader>rn", vim.lsp.buf.rename, "Rename")
				map("gy", vim.lsp.buf.type_definition, "Type Definition")

				-- Inlay hints toggle
				map("<leader>th", function()
					vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }))
				end, "Toggle Inlay Hints")

				-- TS/JS 专用
				local ft = vim.bo[bufnr].filetype
				if ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact" then
					map("<leader>cI", function()
						vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
					end, "Organize Imports")
					map("<leader>cO", function()
						vim.lsp.buf.code_action({ context = { only = { "source.removeUnused" } }, apply = true })
					end, "Remove Unused")
					map("<leader>cF", function()
						vim.lsp.buf.code_action({ context = { only = { "source.fixAll" } }, apply = true })
					end, "Fix All")
					map("<leader>cm", function()
						vim.lsp.buf.code_action({ context = { only = { "source.addMissingImports" } }, apply = true })
					end, "Add Missing Imports")
				end
			end,
		})
	end,
}
