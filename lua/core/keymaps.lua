function Map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

-- clear search highlight
Map("n", "<leader>h", ":nohlsearch<CR>")

-- buffer navigation
Map("n", "<leader>bn", ":bn<CR>")
Map("n", "<leader>bd", ":bd<CR>")

-- move lines (normal mode)
Map("n", "<leader>j", ":m .+1<CR>")
Map("n", "<leader>k", ":m .-2<CR>")

-- move lines (visual mode)
Map("v", "J", ":m '>+1<CR>gv=gv")
Map("v", "K", ":m '<-2<CR>gv=gv")

-- terminal navigation
Map("t", "<C-h>", "<cmd>wincmd h<CR>")
Map("t", "<C-j>", "<cmd>wincmd j<CR>")
Map("t", "<C-k>", "<cmd>wincmd k<CR>")
Map("t", "<C-l>", "<cmd>wincmd l<CR>")
Map("t", "<Esc>", "<C-\\><C-n>")

-- resize windows
Map("n", "<C-Up>", ":resize -2<CR>")
Map("n", "<C-Down>", ":resize +2<CR>")
Map("n", "<C-Left>", ":vertical resize -2<CR>")
Map("n", "<C-Right>", ":vertical resize +2<CR>")

-- window navigation
Map("n", "<C-h>", "<C-w>h")
Map("n", "<C-j>", "<C-w>j")
Map("n", "<C-k>", "<C-w>k")
Map("n", "<C-l>", "<C-w>l")

-- FZF
local fzf = require("fzf-lua")
Map("n", "<leader>b", fzf.buffers)
Map("n", "<leader>f", fzf.files)
Map("n", "<leader>g", fzf.live_grep)
Map("n", "<leader>t", fzf.tabs)
Map("n", "<leader>l", fzf.blines)

-- diagnostics
Map("n", "<leader>o", vim.diagnostic.open_float)
Map("n", "[d", vim.diagnostic.goto_prev)
Map("n", "]d", vim.diagnostic.goto_next)
Map("n", "<leader>q", vim.diagnostic.setloclist)

-------------------------------------------------------
-- DAP (EXECUÇÃO - nvim-dap)
-------------------------------------------------------
local dap = require("dap")

Map("n", "<leader>db", dap.toggle_breakpoint)
Map("n", "<leader>dc", dap.continue)
Map("n", "<leader>di", dap.step_into)
Map("n", "<leader>do", dap.step_over)

-------------------------------------------------------
-- DAP VIEW (UI - nvim-dap-view) SEM CONFLITO
-------------------------------------------------------
local dap_view = require("dap-view.actions")

-- namespace separado para evitar colisão com DAP
Map("n", "<leader>du", dap_view.toggle)
Map("n", "<leader>duo", dap_view.open)
Map("n", "<leader>duc", dap_view.close)

-------------------------------------------------------
-- debug helper
-------------------------------------------------------
function P(opts)
    print(vim.inspect(opts))
end

-------------------------------------------------------
-- LSP attach
-------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

        local opts = { buffer = ev.buf }

        Map("n", "gD", vim.lsp.buf.declaration, opts)
        Map("n", "gd", vim.lsp.buf.definition, opts)
        Map("n", "K", vim.lsp.buf.hover, opts)
        Map("n", "gi", vim.lsp.buf.implementation, opts)
        Map("n", "<leader>H", vim.lsp.buf.signature_help, opts)

        Map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
        Map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)

        Map("n", "<leader>wl", function()
            P(vim.lsp.buf.list_workspace_folders())
        end, opts)

        Map("n", "<leader>D", vim.lsp.buf.type_definition, opts)
        Map("n", "<leader>rn", vim.lsp.buf.rename, opts)
        Map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
        Map("n", "gr", vim.lsp.buf.references, opts)

        Map("n", "F", function()
            vim.lsp.buf.format({ async = true })
        end, opts)
    end,
})
