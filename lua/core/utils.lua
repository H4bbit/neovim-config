local M = {}

function M.map(mode, lhs, rhs, opts)
    opts = vim.tbl_extend("force", {
        noremap = true,
        silent = true,
    }, opts or {})

    vim.keymap.set(mode, lhs, rhs, opts)
end

function M.lsp_opts(opts, desc)
    return vim.tbl_extend("force", opts, {
        desc = desc,
    })
end

function M.augroup(name)
    return vim.api.nvim_create_augroup(name, { clear = true })
end

function M.autocmd(event, opts)
    return vim.api.nvim_create_autocmd(event, opts)
end

return M
