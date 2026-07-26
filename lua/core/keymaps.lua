function Map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }

	if opts then
		options = vim.tbl_extend("force", options, opts)
	end

	vim.keymap.set(mode, lhs, rhs, options)
end

-- ============================================================================
-- Editor
-- ============================================================================

Map("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlight" })

Map("n", "<leader>bn", ":bn<CR>", { desc = "Next buffer" })
Map("n", "<leader>bd", ":bd<CR>", { desc = "Delete buffer" })

Map("n", "<leader>j", ":m .+1<CR>", { desc = "Move line down" })
Map("n", "<leader>k", ":m .-2<CR>", { desc = "Move line up" })

Map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
Map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })

Map("v", "<", "<gv", { desc = "Unindent and keep selection" })
Map("v", ">", ">gv", { desc = "Indent and keep selection" })

Map("x", "p", [["_dP]], { desc = "Paste without overwriting yank register" })

Map("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

Map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down and center cursor" })
Map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up and center cursor" })

Map("n", "n", "nzzzv", { desc = "Next search result centered" })
Map("n", "N", "Nzzzv", { desc = "Previous search result centered" })

Map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

-- ============================================================================
-- Terminal
-- ============================================================================

Map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

Map("t", "<C-h>", "<cmd>wincmd h<CR>", { desc = "Terminal: focus left window" })
Map("t", "<C-j>", "<cmd>wincmd j<CR>", { desc = "Terminal: focus lower window" })
Map("t", "<C-k>", "<cmd>wincmd k<CR>", { desc = "Terminal: focus upper window" })
Map("t", "<C-l>", "<cmd>wincmd l<CR>", { desc = "Terminal: focus right window" })

-- ============================================================================
-- Window Management
-- ============================================================================

Map("n", "<C-Up>", ":resize -2<CR>", { desc = "Decrease window height" })
Map("n", "<C-Down>", ":resize +2<CR>", { desc = "Increase window height" })

Map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
Map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

Map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
Map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
Map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
Map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- ============================================================================
-- FZF
-- ============================================================================

local fzf = require("fzf-lua")

Map("n", "<leader>b", fzf.buffers, { desc = "Find buffers" })
Map("n", "<leader>f", fzf.files, { desc = "Find files" })
Map("n", "<leader>g", fzf.live_grep, { desc = "Live grep" })
Map("n", "<leader>t", fzf.tabs, { desc = "List tabs" })
Map("n", "<leader>l", fzf.blines, { desc = "Search current buffer" })

-- ============================================================================
-- Diagnostics
-- ============================================================================

Map("n", "<leader>o", vim.diagnostic.open_float, { desc = "Show diagnostics" })
Map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
Map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
Map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to location list" })

-- ============================================================================
-- DAP
-- ============================================================================

local dap = require("dap")

Map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
Map("n", "<leader>dc", dap.continue, { desc = "Continue debugging" })
Map("n", "<leader>di", dap.step_into, { desc = "Step into" })
Map("n", "<leader>do", dap.step_over, { desc = "Step over" })

-- ============================================================================
-- DAP View
-- ============================================================================

local dap_view = require("dap-view.actions")

Map("n", "<leader>du", dap_view.toggle, { desc = "Toggle DAP view" })
Map("n", "<leader>duo", dap_view.open, { desc = "Open DAP view" })
Map("n", "<leader>duc", dap_view.close, { desc = "Close DAP view" })
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

		Map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))

		Map("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))

		Map("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))

		Map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "List references" }))

		Map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))

		Map("n", "<leader>H", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))

		Map("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))

		Map(
			{ "n", "v" },
			"<leader>ca",
			vim.lsp.buf.code_action,
			vim.tbl_extend("force", opts, { desc = "Code actions" })
		)

		Map(
			"n",
			"<leader>D",
			vim.lsp.buf.type_definition,
			vim.tbl_extend("force", opts, { desc = "Go to type definition" })
		)

		Map(
			"n",
			"<leader>wa",
			vim.lsp.buf.add_workspace_folder,
			vim.tbl_extend("force", opts, { desc = "Add workspace folder" })
		)

		Map(
			"n",
			"<leader>wr",
			vim.lsp.buf.remove_workspace_folder,
			vim.tbl_extend("force", opts, { desc = "Remove workspace folder" })
		)

		Map("n", "<leader>wl", function()
			P(vim.lsp.buf.list_workspace_folders())
		end, vim.tbl_extend("force", opts, { desc = "List workspace folders" }))

		Map("n", "F", function()
			vim.lsp.buf.format({ async = true })
		end, vim.tbl_extend("force", opts, { desc = "Format buffer" }))
	end,
})
