require("nvim-web-devicons").setup({})

-- Setup do Trouble V3 (as opções padrão já são suficientes na maioria dos casos)
require("trouble").setup({})

-- Definição moderna de ícones de diagnóstico (Neovim >= 0.10)
vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN]  = " ",
            [vim.diagnostic.severity.INFO]  = " ",
            [vim.diagnostic.severity.HINT]  = " ",
        },
    },
})
