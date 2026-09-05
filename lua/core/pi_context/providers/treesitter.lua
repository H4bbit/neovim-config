-- lua/core/pi_context/providers/treesitter.lua
-- Provider Tree-sitter side-effect free para pi_context
-- Usa queries/captures extensíveis, não node:type():match
-- Reutiliza helpers de core/treesitter.lua quando disponível

local M = {}

-- Tabela extensível: lang -> query string com captures @structural
-- Começa pequeno: linguagens efetivamente usadas na config (lsp.lua)
-- Novas linguagens: adicionar entrada sem tocar lógica do provider
local structural_queries = {
  lua = [[
    (function_declaration) @structural
  ]],
  python = [[
    (function_definition) @structural
    (class_definition) @structural
  ]],
  javascript = [[
    (function_declaration) @structural
    (method_definition) @structural
    (class_declaration) @structural
    (arrow_function) @structural
    (function) @structural
  ]],
  typescript = [[
    (function_declaration) @structural
    (method_definition) @structural
    (class_declaration) @structural
    (arrow_function) @structural
    (function) @structural
  ]],
  -- jsx/tsx usam mesmo parser de javascript/typescript
  javascriptreact = [[
    (function_declaration) @structural
    (method_definition) @structural
    (class_declaration) @structural
  ]],
  typescriptreact = [[
    (function_declaration) @structural
    (method_definition) @structural
    (class_declaration) @structural
  ]],
  rust = [[
    (function_item) @structural
    (impl_item) @structural
    (struct_item) @structural
    (enum_item) @structural
  ]],
  c = [[
    (function_definition) @structural
    (struct_specifier) @structural
    (class_specifier) @structural
  ]],
  cpp = [[
    (function_definition) @structural
    (struct_specifier) @structural
    (class_specifier) @structural
  ]],
  elm = [[
    (value_declaration) @structural
    (type_declaration) @structural
  ]],
}

-- Helper para obter lang a partir do filetype (usa API nativa 0.12.5)
local function get_lang_for_buf(buf)
  local ft = vim.bo[buf].filetype or ""
  if ft == "" then return nil end
  local ok, lang = pcall(vim.treesitter.language.get_lang, ft)
  if ok and lang and lang ~= "" then return lang end
  return ft
end

-- Retorna {type, range, text, lang, node} ou nil
function M.get(buf, cursor)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return nil end
  if not cursor or not cursor.line then return nil end
  -- verifica Tree-sitter disponível
  if not vim.treesitter then return nil end

  local lang = get_lang_for_buf(buf)
  if not lang then return nil end

  local query_str = structural_queries[lang]
  if not query_str then
    -- fallback: tenta query genérica se ft == lang, senão nil (deixa snippet)
    return nil
  end

  -- tenta obter parser (reusa helper de core/treesitter.lua se disponível)
  local parser
  do
    local ok, helper = pcall(require, "core.treesitter")
    if ok and helper and helper.get_parser then
      parser = helper.get_parser(buf)
    else
      local ok2, p = pcall(vim.treesitter.get_parser, buf, lang)
      if ok2 then parser = p end
    end
  end
  if not parser then return nil end

  -- parse síncrono, side-effect free (não altera highlight)
  pcall(parser.parse, parser)

  local ok_query, query = pcall(vim.treesitter.query.parse, lang, query_str)
  if not ok_query or not query then return nil end

  local tree = parser:parse()[1]
  if not tree then return nil end
  local root = tree:root()
  if not root then return nil end

  local row = cursor.line - 1
  local col = cursor.col0 or 0

  local best_node = nil
  local best_size = nil
  local best_capture = nil

  -- itera todas as captures @structural e filtra as que contêm o cursor
  -- escolhe a menor (mais interna) para prioridade em estruturas aninhadas
  for id, node in query:iter_captures(root, buf, 0, -1) do
    -- node:range() 0-index
    if vim.treesitter.is_in_node_range(node, row, col) then
      local sr, sc, er, ec = node:range()
      -- tamanho aproximado para comparar (linhas*1000 + cols)
      local size = (er - sr) * 1000 + (ec - sc)
      if not best_node or size < best_size then
        best_node = node
        best_size = size
        best_capture = query.captures[id]
      end
    end
  end

  if not best_node then return nil end

  -- texto completo via Tree-sitter (preserva UTF-8, sem reconstrução manual)
  local ok_text, text = pcall(vim.treesitter.get_node_text, best_node, buf)
  if not ok_text or not text or text == "" then
    -- fallback via linhas
    local sr, sc, er, ec = best_node:range()
    local lines = vim.api.nvim_buf_get_lines(buf, sr, er + 1, false)
    text = table.concat(lines, "\n")
  end
  if text == "" then return nil end

  local sr, sc, er, ec = best_node:range()
  -- range no formato já usado por pi_context: "start-end" (1-indexed linhas)
  local range = sr + 1 == er + 1 and tostring(sr + 1) or string.format("%d-%d", sr + 1, er + 1)

  -- tipo: nome da captura (@structural -> "structural") ou node:type() como fallback específico
  local typ = best_capture or best_node:type()
  -- normaliza: se captura for "structural", usa node:type() para ser mais específico
  if typ == "structural" then typ = best_node:type() end

  return {
    type = typ,
    range = range,
    text = text,
    lang = lang,
    filetype = vim.bo[buf].filetype,
    node = best_node,
    sr = sr, sc = sc, er = er, ec = ec,
  }
end

-- expõe queries para extensão sem modificar provider
M.queries = structural_queries

return M
