function Map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

--clear text selected
Map("n", "<leader>h", ":nohlsearch<CR>")

-- buffer navigation
--Map("n", "<TAB>", ":bn<CR>")
--Map("n", "<S-TAB>", ":bp<CR>")
Map("n", "<leader>d", ":bd<CR>")

--normal mode navigation
Map("n", "<leader>j", ":m .+1<CR>")
Map("n", "<leader>k", ":m .-2<CR>")

-- visual mode navigation
Map("v", "J", ":m '>+1<CR>gv=gv")
Map("v", "K", ":m '<-2<CR>gv=gv")

-- terminal mode navigation
Map("t", "<C-h>", "<cmd>wincmd h<CR>")
Map("t", "<C-j>", "<cmd>wincmd j<CR>")
Map("t", "<C-k>", "<cmd>wincmd k<CR>")
Map("t", "<C-l>", "<cmd>wincmd l<CR>")

-- resize window
Map("n", "<C-Up>", ":resize -2<CR>")
Map("n", "<C-Down>", ":resize +2<CR>")
Map("n", "<C-Left>", ":vertical resize -2<CR>")
Map("n", "<C-Right>", ":vertical resize +2<CR>")

-- multi window navigation
Map("n", "<C-h>", "<C-w>h")
Map("n", "<C-j>", "<C-w>j")
Map("n", "<C-k>", "<C-w>k")
Map("n", "<C-l>", "<C-w>l")

--  FZF
local fzf = require("fzf-lua")
Map("n", "<leader>b", fzf.buffers)
Map("n", "<leader>f", fzf.files)
Map("n", "<leader>g", fzf.live_grep)
Map("n", "<leader>t", fzf.tabs)
Map("n", "<leader>l", fzf.blines)

--diagnostics
Map("n", "<leader>o", vim.diagnostic.open_float)
Map("n", "[d", vim.diagnostic.goto_prev)
Map("n", "]d", vim.diagnostic.goto_next)
Map("n", "<leader>q", vim.diagnostic.setloclist)

function P(opts)
	print(vim.inspect(opts))
end

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
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
