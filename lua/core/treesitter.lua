-- =========================================================================
-- Configuração Tree-sitter (Neovim >= 0.12 + nvim-treesitter@main)
-- =========================================================================
-- O plugin nvim-treesitter (branch main) cuida SÓ de instalar parsers e
-- entregar queries. Highlight/folds/indent precisam ser ativados aqui.

local max_filesize = 100 * 1024 -- 100 KB

-- 1. Proteção contra arquivos gigantes e ativação do highlight
vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("NativeTreesitterSetup", { clear = true }),
	callback = function(args)
		local buf = args.buf
		local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))

		-- Se o arquivo for maior que 100KB, desliga o treesitter
		if ok and stats and stats.size > max_filesize then
			pcall(vim.treesitter.stop, buf)
			return
		end

		-- Inicia o highlight nativo para buffers normais
		-- O Neovim já tenta fazer isso por padrão, mas isso garante
		-- que ocorra de forma explícita e segura.
		pcall(vim.treesitter.start, buf)
	end,
})

-- 2. Indentação
-- Langs COM query de indent no nvim-treesitter@main usam o indentexpr do
-- plugin (experimental, mas é o suportado). Langs SEM query (elm, vim,
-- vimdoc, markdown_inline) caem no fallback smartindent.
local ts_indent_langs = {
	bash = true,
	c = true,
	cpp = true,
	javascript = true,
	json = true,
	lua = true,
	markdown = true,
	python = true,
	query = true,
	rust = true,
	toml = true,
	tsx = true,
	typescript = true,
}

vim.opt.smartindent = true -- fallback para langs sem query de indent

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("TreesitterIndent", { clear = true }),
	callback = function(args)
		local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
		if lang and ts_indent_langs[lang] then
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})

-- 3. Seleção incremental — API nativa (vim.treesitter.select)
-- Cobre o mesmo uso do TS_Select antigo (expandir/encolher seleção por nós)
-- mais navegação entre siblings, sem pilha manual nem feedkeys agendado.
vim.keymap.set({ "n", "x" }, "<leader>si", function()
	vim.treesitter.select("parent")
end, { desc = "TS: Expandir seleção (nó pai)" })
vim.keymap.set("x", "<leader>sd", function()
	vim.treesitter.select("child")
end, { desc = "TS: Encolher seleção (nó filho)" })
vim.keymap.set({ "n", "x" }, "<leader>sn", function()
	vim.treesitter.select("next")
end, { desc = "TS: Selecionar próximo irmão" })
vim.keymap.set({ "n", "x" }, "<leader>sp", function()
	vim.treesitter.select("prev")
end, { desc = "TS: Selecionar irmão anterior" })
