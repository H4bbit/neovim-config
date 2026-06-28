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
    "lukas-reineke/indent-blankline.nvim",
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

    -- LSP, Autocomplete e Snippets
    "neovim/nvim-lspconfig", -- MANTIDO: Fornece as "receitas" para o vim.lsp.enable()
    "nvimtools/none-ls.nvim",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",

    -- Linguagens Específicas
    "vim-crystal/vim-crystal",
    "rust-lang/rust.vim",
    {
        "mrcjkb/rustaceanvim",
        lazy = false,
        config = function()
            vim.g.rustaceanvim = {
                server = {
                    on_attach = function(client, bufnr)
                    end,
                    default_settings = {
                        ['rust-analyzer'] = {
                            checkOnSave = true,
                            cargo = {
                                allFeatures = true,
                                -- TODO: target explicito apenas em builds no contexto do ndk
                                -- target = "aarch64-linux-android",
                            },
                            check = {
                                command = "clippy",
                                extraArgs = { "--", "-W", "clippy::pedantic" },
                            },
                        },
                    },
                },
            }
        end,
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
                    sections = { "console", "scopes", "breakpoints", "threads", "repl", "watches" }
                },
            })
        end,
        keys = {
            { "<F7>", "<cmd>DapViewToggle<CR>", desc = "Toggle DAP View" },
        },
    },
})
