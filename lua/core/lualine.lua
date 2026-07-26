require("lualine").setup({
	options = {
		theme = "catppuccin",
		globalstatus = true,
	},

	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = {},
		lualine_x = { "lsp_progress" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},

	winbar = {
		lualine_a = {
			{ "filetype", icon_only = true },
		},
		lualine_b = {
			{ "filename", path = 1 },
		},
		lualine_c = {},
		lualine_x = {
			"diagnostics",
		},
		lualine_y = {},
		lualine_z = {},
	},

	inactive_winbar = {
		lualine_a = {
			{ "filetype", icon_only = true },
		},
		lualine_b = {
			{ "filename", path = 1 },
		},
	},
})
