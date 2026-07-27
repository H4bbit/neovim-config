local utils = require("core.utils")
local fzf = require("fzf-lua")
local dap = require("dap")
local dap_view = require("dap-view.actions")

local map = utils.map
local lsp_opts = utils.lsp_opts
local diagnostic = vim.diagnostic
local cmd = vim.cmd
local buf = vim.lsp.buf
-- ============================================================================
-- Editor
-- ============================================================================

map("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlight" })

map("n", "<leader>bn", cmd.bnext, { desc = "Next buffer" })
map("n", "<leader>bd", cmd.bdelete, { desc = "Delete buffer" })

map("n", "<leader>j", "<cmd>m .+1<CR>", { desc = "Move line down" })
map("n", "<leader>k", "<cmd>m .-2<CR>", { desc = "Move line up" })

map("v", "J", "<cmd>m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
map("v", "K", "<cmd>m '<-2<CR>gv=gv", { desc = "Move selected lines up" })

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

map("n", "<C-Up>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Down>", "<cmd>resize +2<CR>", { desc = "Increase window height" })

map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- ============================================================================
-- FZF
-- ============================================================================

map("n", "<leader>b", fzf.buffers, { desc = "Find buffers" })
map("n", "<leader>f", fzf.files, { desc = "Find files" })
map("n", "<leader>g", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader>t", fzf.tabs, { desc = "List tabs" })
map("n", "<leader>l", fzf.blines, { desc = "Search current buffer" })

-- ============================================================================
-- Trouble
-- ============================================================================

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Diagnostics (Trouble)" })

map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Buffer diagnostics (Trouble)" })

map("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<CR>", { desc = "Symbols (Trouble)" })

map(
	"n",
	"<leader>cl",
	"<cmd>Trouble lsp toggle focus=false win.position=right<CR>",
	{ desc = "LSP references (Trouble)" }
)

map("n", "<leader>xL", "<cmd>Trouble loclist toggle<CR>", { desc = "Location list (Trouble)" })

map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<CR>", { desc = "Quickfix list (Trouble)" })
-- ============================================================================
-- Diagnostics
-- ============================================================================

map("n", "<leader>o", diagnostic.open_float, { desc = "Show diagnostics" })
map("n", "[d", function()
	diagnostic.jump({
		count = -1,
		float = true,
	})
end, {
	desc = "Previous diagnostic",
})

map("n", "]d", function()
	diagnostic.jump({
		count = 1,
		float = true,
	})
end, {
	desc = "Next diagnostic",
})
-- ============================================================================
-- DAP
-- ============================================================================

map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
map("n", "<leader>dc", dap.continue, { desc = "Continue debugging" })
map("n", "<leader>di", dap.step_into, { desc = "Step into" })
map("n", "<leader>do", dap.step_over, { desc = "Step over" })

-- ============================================================================
-- DAP View
-- ============================================================================

map("n", "<leader>du", dap_view.toggle, { desc = "Toggle DAP view" })
map("n", "<leader>duo", dap_view.open, { desc = "Open DAP view" })
map("n", "<leader>duc", dap_view.close, { desc = "Close DAP view" })

-------------------------------------------------------
-- LSP attach
-------------------------------------------------------

utils.autocmd("LspAttach", {
	group = utils.augroup("UserLspConfig"),
	callback = function(ev)
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		local opts = { buffer = ev.buf }

		local function lmap(mode, lhs, rhs, desc)
			map(mode, lhs, rhs, lsp_opts(opts, desc))
		end

		lmap("n", "gd", buf.definition, "Go to definition")
		lmap("n", "gD", buf.declaration, "Go to declaration")
		lmap("n", "gi", buf.implementation, "Go to implementation")
		lmap("n", "gr", buf.references, "List references")
		lmap("n", "K", buf.hover, "Hover documentation")

		lmap("n", "<leader>H", buf.signature_help, "Signature help")

		lmap("n", "<leader>rn", buf.rename, "Rename symbol")

		lmap({ "n", "v" }, "<leader>ca", buf.code_action, "Code actions")
		lmap("n", "<leader>D", buf.type_definition, "Go to type definition")
		lmap("n", "<leader>wa", buf.add_workspace_folder, "Add workspace folder")
		lmap("n", "<leader>wr", buf.remove_workspace_folder, "Remove workspace folder")

		lmap("n", "<leader>wl", function()
			vim.print(buf.list_workspace_folders())
		end, "List workspace folders")

		lmap("n", "F", function()
			buf.format({ async = true })
		end, "Format buffer")
	end,
})
