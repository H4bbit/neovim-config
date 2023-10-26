local configs = require("nvim-treesitter.configs")

configs.setup({
	ensure_installed = { "lua", "vim", "luadoc", "vimdoc", "query" },

	auto_install = true,

	highlight = {
		enable = true,
	},
	disable = function(lang, buf)
		local max_filesize = 100 * 1024 -- 100 KB
		local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
		if ok and stats and stats.size > max_filesize then
			return true
		end
	end,
	indent = {
		enable = true,
	},
	incremental_selection = {
		enable = true,
		keymaps = {
						init_selection = "<CR>",
						node_incremental = "<CR>",
            			node_decremental = "<BS>",
                        scope_incremental = "<TAB>",
		},
	},
})
