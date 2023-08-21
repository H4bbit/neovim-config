require 'nvim-web-devicons'.setup {}
require("trouble").setup {
    icons = true,
    use_diagnostic_signs = true,
}


local signs = {
    Error = " ",
    Warn = " ",
    Hint = " ",
    Info = " ",
}

for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end
