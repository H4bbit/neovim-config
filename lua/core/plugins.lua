local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
		vim.cmd([[packadd packer.nvim]])
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

return require("packer").startup(function(use)
	use("wbthomason/packer.nvim")

	use({
		"nvim-treesitter/nvim-treesitter",
		run = function()
			local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
			ts_update()
		end,
	})
	use("norcalli/nvim-colorizer.lua")
	--WILDMENU INPROVED
	use("gelguy/wilder.nvim")

	--FZF
	use("ibhagwan/fzf-lua")
	use("romgrk/fzy-lua-native")

	use("nvim-lua/plenary.nvim")
	use("jose-elias-alvarez/null-ls.nvim")
	--DIAGNOSTICS AND DEFINITIOMS
	use("folke/trouble.nvim")

	-- LSP AND SNIPPETS
	use("neovim/nvim-lspconfig")
	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-nvim-lsp")
	use("L3MON4D3/LuaSnip")
	use("saadparwaiz1/cmp_luasnip")
	use("rafamadriz/friendly-snippets")

	-- THEME
	use({ "catppuccin/nvim", as = "catppuccin" })
	-- LUALINE AND ICONS
	use("nvim-tree/nvim-web-devicons")
	use("arkav/lualine-lsp-progress")
	use("nvim-lualine/lualine.nvim")
	--IDNENT GUIDE
	use("lukas-reineke/indent-blankline.nvim")
	-- rust plugins
	use("rust-lang/rust.vim")
	use("simrat39/rust-tools.nvim")

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if packer_bootstrap then
		require("packer").sync()
	end
end)
