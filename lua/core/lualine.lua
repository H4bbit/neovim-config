local winbar = require("core.winbar")

winbar.setup()

local filetype = { "filetype", icon_only = true }
local filename = { "filename", path = 1 }

require("lualine").setup({
	options = {
		theme = "catppuccin",
		globalstatus = true,
	},

	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { "overseer" },
		lualine_x = { "lsp_progress" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},

	winbar = {
		lualine_a = { filetype },
		lualine_b = { filename },
		lualine_c = {
			{ winbar.context },
		},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},

	inactive_winbar = {
		lualine_a = { filetype },
		lualine_b = { filename },
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},
})
