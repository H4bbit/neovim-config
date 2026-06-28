local opt = vim.opt

-- Editor
opt.number = true
opt.relativenumber = true
opt.cursorline = true

opt.wrap = false
opt.mouse = "i"

opt.autowrite = true
opt.autoread = true
opt.showcmd = true

-- Indentação
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

opt.backspace = { "indent", "eol", "start" }

-- Completion
opt.completeopt = "menuone,noselect"

-- Aparência
opt.termguicolors = true

-- Leaders
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Core
require("core.plugins")

require("core.lsp")
require("core.dap")
require("core.treesitter")
require("core.none_ls")
require("core.rust")

require("core.fzf")
require("core.trouble")
require("core.lualine")

require("core.keymaps")

-- Plugins sem módulo próprio
require("colorizer").setup({})
