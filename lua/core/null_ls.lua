local null_ls = require("null-ls")

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({

	-- you can reuse a shared lspconfig on_attach callback here
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					-- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
					-- on later neovim version, you should use
					vim.lsp.buf.format({ async = false }) --instead
					--vim.lsp.buf.formatting_sync()
				end,
			})
		end
	end,

	sources = {
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.diagnostics.flake8.with({
			extra_args = { "--max-line-length", "88" },
		}),
		null_ls.builtins.diagnostics.mypy,
		null_ls.builtins.formatting.black,
		null_ls.builtins.diagnostics.ruff,
		null_ls.builtins.completion.spell,
	},
})
