-- =========================================================================
-- Configuração Nativa do Tree-sitter (Neovim >= 0.12)
-- =========================================================================
-- Registra um handler falso para o predicado is-not? evitando crash com queries upstream
vim.treesitter.query.add_predicate("is-not?", function()
	return true
end, { force = true })

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

-- 2. Identação
-- O Neovim >= 0.10 já utiliza queries do Tree-sitter internamente para
-- os arquivos de runtime de indentação padrão. Apenas garanta que o smartindent esteja ligado.
vim.opt.smartindent = true

-- 3. Seleção Incremental Nativa
-- Como não temos mais o plugin, implementamos a lógica de seleção de nós com a API nativa
local TS_Select = {}
TS_Select.node_stack = {}

function TS_Select.inc()
	local mode = vim.fn.mode()
	local buf = vim.api.nvim_get_current_buf()

	if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
		-- Inicia a seleção (init_selection)
		local node = vim.treesitter.get_node()
		if not node then
			return
		end
		TS_Select.node_stack = { node }
		TS_Select.apply_selection(node)
	else
		-- Incrementa a seleção (node_incremental)
		local current_node = TS_Select.node_stack[#TS_Select.node_stack]
		if not current_node then
			return
		end
		local parent = current_node:parent()
		if parent then
			table.insert(TS_Select.node_stack, parent)
			TS_Select.apply_selection(parent)
		end
	end
end

function TS_Select.dec()
	local mode = vim.fn.mode()
	if (mode ~= "v" and mode ~= "V" and mode ~= "\22") or #TS_Select.node_stack <= 1 then
		return
	end
	-- Decrementa a seleção (node_decremental)
	table.remove(TS_Select.node_stack)
	local prev_node = TS_Select.node_stack[#TS_Select.node_stack]
	TS_Select.apply_selection(prev_node)
end

function TS_Select.apply_selection(node)
	local sr, sc, er, ec = node:range()
	-- Sai do modo visual temporariamente para redefinir a seleção
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

	vim.schedule(function()
		vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
		vim.cmd("normal! v")
		if ec == 0 then
			vim.api.nvim_win_set_cursor(0, { er, vim.fn.col({ er, "$" }) - 1 })
		else
			vim.api.nvim_win_set_cursor(0, { er + 1, ec - 1 })
		end
	end)
end

-- Mapeamentos de Seleção Incremental
vim.keymap.set({ "n", "x" }, "<leader>si", TS_Select.inc, { desc = "TS: Iniciar/Incrementar Seleção" })
vim.keymap.set("x", "<leader>sd", TS_Select.dec, { desc = "TS: Decrementar Seleção" })
