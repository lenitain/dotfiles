return {
	"folke/flash.nvim",
	-- VeryLazy：启动早期加载，保证 / ? 搜索叠加 flash 标签始终生效
	-- （否则 flash 只在按 S/r/R 时才被懒加载，搜索集成不会自动激活）
	event = "VeryLazy",
	opts = {
		-- 写死：/ ? 搜索时叠加 flash 跳转标签，默认开启（<C-s> 已让位给"处处保存"，不再做切换）
		modes = {
			search = {
				enabled = false,
				-- 跳转/回车后保留 hlsearch 高亮，保持原生搜索习惯（flash 默认会清掉高亮）
				jump = { nohlsearch = false },
			},
		},
	},
	keys = {
		-- 主跳转用大写 S：避开 mini.surround 的 s 前缀（sa/sd/cs…），按键立即触发无延迟。
		-- 小写 s 让给环绕插件当前缀；原 S 的 Treesitter 选择已移除，需要时可另配键。
		{
			"S",
			mode = { "n", "x", "o" },
			function()
				require("flash").jump()
			end,
			desc = "Flash",
		},
		{
			"r",
			mode = "o",
			function()
				require("flash").remote()
			end,
			desc = "Remote Flash",
		},
		{
			"R",
			mode = { "o", "x" },
			function()
				require("flash").treesitter_search()
			end,
			desc = "Treesitter Search",
		},
	},
}
