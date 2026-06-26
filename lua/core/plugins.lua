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
    {
        "nvim-treesitter/nvim-treesitter",
        run = function()
            local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
            ts_update()
        end,
    },
    --[[
    {
        "milanglacier/minuet-ai.nvim",

        config = function()
            require('minuet').setup {
                provider = 'openai_fim_compatible',

                throttle = 1000,
                debounce = 400,

                provider_options = {
                    openai_fim_compatible = {
                        api_key = 'MISTRAL_API_KEY',

                        model = 'codestral-latest',

                        end_point =
                        'https://api.mistral.ai/v1/fim/completions',

                        stream = false,

                        optional = {
                            max_tokens = 64,
                            stop = { '\n\n' },
                        },
                    },
                },

                virtualtext = {
                    auto_trigger_ft = { '*' },

                    keymap = {
                        accept = '<C-y>',
                        next = '<A-[>',
                        prev = '<A-]>',
                        dismiss = '<C-e>',
                    },
                },
            }
        end,
    },
    --]]
    --[[
    {
        "olimorris/codecompanion.nvim",
        config = function()
            require("codecompanion").setup({
                interactions = {
                    chat = {
                        adapter = "gemini",
                    },
                    inline = {
                        adapter = "gemini",
                    },
                    cmd = {
                        adapter = "gemini",
                    },
                },
            })
        end,
    },
    --]]
    --[[
	{
		"kiddos/gemini.nvim",
		config = function()
			require("gemini").setup({
				hints = {
					enabled = true,
					insert_result_key = "<M-l>",
				},
				completion = {
					enabled = true,
					insert_result_key = "<M-l>",
				},
			})
		end,
	},
    --]]
    "vim-crystal/vim-crystal",
    --    "github/copilot.vim.git",
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
    {
        "catppuccin/nvim",
        config = function()
            vim.cmd.colorscheme("catppuccin")
        end,
    },
    "arkav/lualine-lsp-progress",
    "nvim-lualine/lualine.nvim",
    "lukas-reineke/indent-blankline.nvim",
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end,
    },
    "rust-lang/rust.vim",
    --    "simrat39/rust-tools.nvim",
    --    "mrcjkb/rustaceanvim",
    {
        'mrcjkb/rustaceanvim',
        lazy = false,
        config = function()
            vim.g.rustaceanvim = {
                server = {
                    on_attach = function(client, bufnr)
                    end,
                    -- A utilização de default_settings garante que as configurações do workspace sejam respeitadas
                    default_settings = {
                        ['rust-analyzer'] = {
                            checkOnSave = true,
                            cargo = {
                                allFeatures = true,
                                target = "aarch64-linux-android",
                            },
                            check = {
                                command = "clippy",
                                -- Adiciona a flag de target explicitamente aos argumentos do comando interno
                                extraArgs = { "--", "-W", "clippy::pedantic" },
                            },
                        },
                    },
                },
            }
        end,
    }

})
