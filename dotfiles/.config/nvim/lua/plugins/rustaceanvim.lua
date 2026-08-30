return {
	"mrcjkb/rustaceanvim",
	version = "^5",
	lazy = false, -- filetype plugin，不需要 setup
	-- 通过 vim.g.rustaceanvim 配置
	init = function()
		vim.g.rustaceanvim = {
			server = {
				-- 关键：不让 ftplugin 在 FileType rust 里同步启动 LSP，
				-- 改由下方 config() 的 FileType autocmd + vim.schedule 异步启动，
				-- 消除"进入 Rust 文件时同步启动 rust-analyzer 造成卡顿"
				auto_attach = false,

				-- root_dir：rustaceanvim 默认会同步跑 `cargo metadata --no-deps`
				-- （vim.system(...):wait()，约 20-40ms）。这里换成纯文件系统向上
				-- 查找 Cargo.toml / rust-project.json，跳过 cargo 子进程，耗时 ~0ms。
				-- 注意：单 crate 项目（如 fsmon）结果与默认完全一致；
				-- 多 crate workspace 时返回的是最近的成员 crate 目录
				-- （rust-analyzer 通常仍会自行发现真实 workspace，一般无碍）。
				root_dir = function(file_name)
					local dir = vim.fs.dirname(file_name)
					local found = vim.fs.find({ "Cargo.toml", "rust-project.json" }, {
						upward = true,
						path = dir,
					})
					return #found > 0 and vim.fs.dirname(found[1]) or nil
				end,

				settings = {
					["rust-analyzer"] = {
						checkOnSave = true,
						check = { command = "clippy" },
						inlayHints = {
							chainingHints = true,
							typeHints = true,
							parameterHints = true,
						},
					},
				},
			},
		}
	end,
	config = function()
		-- 异步启动 LSP：文件已打开、首帧渲染完成后再启动 rust-analyzer，
		-- 编辑不再被同步的 LSP 初始化（cargo metadata + 客户端建立）阻塞
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "rust",
			callback = function(args)
				local bufnr = args.buf
				vim.schedule(function()
					if not vim.api.nvim_buf_is_valid(bufnr) then
						return
					end
					require("rustaceanvim.lsp").start(bufnr)
				end)
			end,
		})
	end,
}
