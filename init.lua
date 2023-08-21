local opt = vim.opt

opt.completeopt = "menuone,noselect"
opt.backspace = "2"

--vim.opt.syntax        = "enable"
opt.number = true
opt.autowrite = true
opt.autoread = true
opt.showcmd = true

opt.cursorline = true

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

vim.wo.relativenumber = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd([[set nowrap]])

vim.cmd([[set mouse=i]])

vim.cmd([[colorscheme catppuccin]])

require("core.plugins")
require("core.fzf")
require("core.keymaps")
require("core.wilder")
require("core.lsp")
require("core.treesitter")
require("core.trouble")
require("core.lualine")
require("core.null_ls")
require("core.rust")

require("colorizer").setup({})
