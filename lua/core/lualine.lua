--local symbols = {unix = ''}
require 'lualine'.setup {
    sections = {
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {
            'lsp_progress'
        },
        lualine_d = { 'progress' },
        lualine_a = { 'lsp_status' },
        lualine_x = { 'filetype' },
        lualine_y = { 'filename' },
        lualine_z = { 'location' },
    }
}
