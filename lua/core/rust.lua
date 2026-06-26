vim.g.rustaceanvim = {
    server = {
        on_attach = function(_, bufnr)
            local opts = { buffer = bufnr, silent = true }

            vim.keymap.set("n", "<leader>a", function()
                vim.cmd.RustLsp("codeAction")
            end, opts)

            vim.keymap.set("n", "K", function()
                vim.cmd.RustLsp({ "hover", "actions" })
            end, opts)
        end,
    },
}
