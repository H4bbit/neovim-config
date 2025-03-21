--pckr version
local function bootstrap_pckr()
  local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"

  if not (vim.uv or vim.loop).fs_stat(pckr_path) then
    vim.fn.system({
      'git',
      'clone',
      "--filter=blob:none",
      'https://github.com/lewis6991/pckr.nvim',
      pckr_path
    })
  end

  vim.opt.rtp:prepend(pckr_path)
end

bootstrap_pckr()

require('pckr').add{
    {
		"nvim-treesitter/nvim-treesitter",
		run = function()
			local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
			ts_update()
		end,
	},
    {
        "kiddos/gemini.nvim",
        config = function()
            require('gemini').setup({
                    hints = {
                        enabled = true,
                        insert_result_key = '<M-l>',
                    },
                    completion = {
                        enabled = true,
                        insert_result_key = '<M-l>',
                    }
            })
        end,

    },
    "norcalli/nvim-colorizer.lua",
    "gelguy/wilder.nvim",
    "ibhagwan/fzf-lua",
    "romgrk/fzy-lua-native",
    "nvim-lua/plenary.nvim",
    "nvimtools/none-ls.nvim", 
    "folke/trouble.nvim",
    "neovim/nvim-lspconfig",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
    {"catppuccin/nvim", config = function()
        vim.cmd.colorscheme "catppuccin"
    end,},
    "nvim-tree/nvim-web-devicons",
    "arkav/lualine-lsp-progress",
    "nvim-lualine/lualine.nvim",
    "lukas-reineke/indent-blankline.nvim",
    {"lewis6991/gitsigns.nvim",config = function()
        require('gitsigns').setup()
    end},
    "rust-lang/rust.vim",
    "simrat39/rust-tools.nvim",
                    
}
