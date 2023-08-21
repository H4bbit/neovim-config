--local symbols = {unix = ''}
require 'lualine'.setup {
    sections = {
        lualine_x = { 'filetype' },
        lualine_c = {
            'lsp_progress'
        }
    }
}
