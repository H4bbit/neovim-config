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

opt.inccommand = "split"

opt.splitbelow = true
opt.splitright = true

opt.ignorecase = true
opt.smartcase = true

opt.swapfile = false
opt.backup = false

-- Indentação
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

opt.backspace = { "indent", "eol", "start" }

-- Completion
opt.completeopt = "menuone,noselect,fuzzy,nosort"

-- Aparência
opt.termguicolors = true
opt.colorcolumn = "0"
opt.signcolumn = "yes"
vim.o.cmdheight = 0

-- Leaders
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Core
require("core.plugins")

require("core.treesitter")
require("core.lsp")
require("core.dap")
require("core.rust")

require("core.fzf")
require("core.trouble")
require("core.lualine")

require("core.pi")
require("core.keymaps")

-- Plugins sem módulo próprio
require("colorizer").setup({})
require("vim._core.ui2").enable({})
