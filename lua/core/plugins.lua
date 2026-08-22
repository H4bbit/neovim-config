local function bootstrap_pckr()
	local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"

	if not (vim.uv or vim.loop).fs_stat(pckr_path) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/lewis6991/pckr.nvim",
			pckr_path,
		})
	end

	vim.opt.rtp:prepend(pckr_path)
end

bootstrap_pckr()

require("pckr").add({
	-- UI & Aparência
	{
		"catppuccin/nvim",
		config = function()
			vim.cmd.colorscheme("catppuccin")
		end,
	},
	"norcalli/nvim-colorizer.lua",
	{
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("ibl").setup()
		end,
	},
	"nvim-lualine/lualine.nvim",
	-- Navegação, Busca e Utilidades
	"ibhagwan/fzf-lua",
	"hrsh7th/cmp-cmdline",
	"nvim-lua/plenary.nvim",
	"folke/trouble.nvim",
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},
	{
		"NeogitOrg/neogit",
		requires = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
		},
		config = function()
			require("neogit").setup()
		end,
	},
	{
		"stevearc/oil.nvim",
		config = function()
			require("oil").setup()
		end,
	},
	{
		"benomahony/oil-git.nvim",
		requires = { "stevearc/oil.nvim" },
	},
	{
		"stevearc/overseer.nvim",
	},
	-- LSP, Autocomplete e Snippets
	"neovim/nvim-lspconfig", -- MANTIDO: Fornece as "receitas" para o vim.lsp.enable()
	"hrsh7th/nvim-cmp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-nvim-lsp",
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",
	"rafamadriz/friendly-snippets",
	"arkav/lualine-lsp-progress",
	-- Linguagens Específicas
	"vim-crystal/vim-crystal",
	"rust-lang/rust.vim",
	{
		"mrcjkb/rustaceanvim",
		lazy = false,
	},

	-- Debugging (DAP)
	"mfussenegger/nvim-dap",
	{
		"igorlfs/nvim-dap-view",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			require("dap-view").setup({
				winbar = {
					controls = { enabled = true, position = "left" },
					sections = { "console", "scopes", "breakpoints", "threads", "repl", "watches" },
				},
			})
		end,
	},
})
