local utils = require("core.utils")
local map = utils.map

-- ============================================================================
-- Editor
-- ============================================================================

map("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlight" })

map("n", "<leader>bn", ":bn<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", ":bd<CR>", { desc = "Delete buffer" })

map("n", "<leader>j", ":m .+1<CR>", { desc = "Move line down" })
map("n", "<leader>k", ":m .-2<CR>", { desc = "Move line up" })

map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })

map("v", "<", "<gv", { desc = "Unindent and keep selection" })
map("v", ">", ">gv", { desc = "Indent and keep selection" })

map("x", "p", [["_dP]], { desc = "Paste without overwriting yank register" })

map("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down and center cursor" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up and center cursor" })

map("n", "n", "nzzzv", { desc = "Next search result centered" })
map("n", "N", "Nzzzv", { desc = "Previous search result centered" })

map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

-- ============================================================================
-- Terminal
-- ============================================================================

map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

map("t", "<C-h>", "<cmd>wincmd h<CR>", { desc = "Terminal: focus left window" })
map("t", "<C-j>", "<cmd>wincmd j<CR>", { desc = "Terminal: focus lower window" })
map("t", "<C-k>", "<cmd>wincmd k<CR>", { desc = "Terminal: focus upper window" })
map("t", "<C-l>", "<cmd>wincmd l<CR>", { desc = "Terminal: focus right window" })

-- ============================================================================
-- Window Management
-- ============================================================================

map("n", "<C-Up>", ":resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Down>", ":resize +2<CR>", { desc = "Increase window height" })

map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- ============================================================================
-- FZF
-- ============================================================================

local fzf = require("fzf-lua")

map("n", "<leader>b", fzf.buffers, { desc = "Find buffers" })
map("n", "<leader>f", fzf.files, { desc = "Find files" })
map("n", "<leader>g", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader>t", fzf.tabs, { desc = "List tabs" })
map("n", "<leader>l", fzf.blines, { desc = "Search current buffer" })

-- ============================================================================
-- Diagnostics
-- ============================================================================

map("n", "<leader>o", vim.diagnostic.open_float, { desc = "Show diagnostics" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to location list" })

-- ============================================================================
-- DAP
-- ============================================================================

local dap = require("dap")

map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
map("n", "<leader>dc", dap.continue, { desc = "Continue debugging" })
map("n", "<leader>di", dap.step_into, { desc = "Step into" })
map("n", "<leader>do", dap.step_over, { desc = "Step over" })

-- ============================================================================
-- DAP View
-- ============================================================================

local dap_view = require("dap-view.actions")

map("n", "<leader>du", dap_view.toggle, { desc = "Toggle DAP view" })
map("n", "<leader>duo", dap_view.open, { desc = "Open DAP view" })
map("n", "<leader>duc", dap_view.close, { desc = "Close DAP view" })

-------------------------------------------------------
-- LSP attach
-------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

        local opts = { buffer = ev.buf }

        map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))

        map("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))

        map("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))

        map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "List references" }))

        map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))

        map("n", "<leader>H", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))

        map("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))

        map(
            { "n", "v" },
            "<leader>ca",
            vim.lsp.buf.code_action,
            vim.tbl_extend("force", opts, { desc = "Code actions" })
        )

        map(
            "n",
            "<leader>D",
            vim.lsp.buf.type_definition,
            vim.tbl_extend("force", opts, { desc = "Go to type definition" })
        )

        map(
            "n",
            "<leader>wa",
            vim.lsp.buf.add_workspace_folder,
            vim.tbl_extend("force", opts, { desc = "Add workspace folder" })
        )

        map(
            "n",
            "<leader>wr",
            vim.lsp.buf.remove_workspace_folder,
            vim.tbl_extend("force", opts, { desc = "Remove workspace folder" })
        )

        map("n", "<leader>wl", function()
            vim.print(vim.lsp.buf.list_workspace_folders())
        end, vim.tbl_extend("force", opts, { desc = "List workspace folders" }))

        map("n", "F", function()
            vim.lsp.buf.format({ async = true })
        end, vim.tbl_extend("force", opts, { desc = "Format buffer" }))
    end,
})
