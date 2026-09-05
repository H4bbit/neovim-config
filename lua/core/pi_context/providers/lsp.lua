-- lua/core/pi_context/providers/lsp.lua
-- Provider LSP side-effect free para pi_context
-- Enriquecimento semântico via textDocument/documentSymbol
-- Não substitui Tree-sitter; retorna metadado do símbolo enclosing

local M = {}

-- timeout síncrono (ms) – curto para não bloquear M.get()
M.timeout_ms = 600

local function in_range(range, row, col)
  if not range or not range.start or not range["end"] then return false end
  local s = range.start
  local e = range["end"]
  -- LSP: start inclusive, end exclusive; row/col 0-index
  if row < s.line or row > e.line then return false end
  if row == s.line and col < s.character then return false end
  if row == e.line and col >= e.character then
    -- on end line, character at/after end => outside (exclusive)
    -- exceção: se range é de linha única e col == e.character, fora
    return false
  end
  -- linha intermediária já dentro
  return true
end

local function range_to_str(range)
  if not range or not range.start or not range["end"] then return "" end
  local sl = range.start.line + 1
  local el = range["end"].line + 1
  if sl == el then return tostring(sl) end
  return string.format("%d-%d", sl, el)
end

function M.get(buf, cursor)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return nil end
  if not cursor or not cursor.line then return nil end
  if not vim.lsp then return nil end

  -- verifica clientes LSP com suporte a documentSymbol (API moderna 0.12)
  local clients = nil
  do
    local ok, res = pcall(vim.lsp.get_clients, { bufnr = buf, method = "textDocument/documentSymbol" })
    if ok then clients = res end
  end
  if not clients or #clients == 0 then return nil end

  -- filtra por supports_method se houver, para respeitar capacidades por buffer
  local has_support = false
  for _, c in ipairs(clients) do
    local ok, sup = pcall(function() return c:supports_method("textDocument/documentSymbol", buf) end)
    if ok and sup then has_support = true; break end
    -- fallback: se método não existir, assume suporte já filtrado por get_clients
    if not ok then has_support = true; break end
  end
  if not has_support then return nil end

  local params = nil
  do
    local ok, p = pcall(vim.lsp.util.make_text_document_params, buf)
    if ok then params = p end
  end
  if not params then return nil end

  local results = nil
  do
    local ok, res = pcall(vim.lsp.buf_request_sync, buf, "textDocument/documentSymbol", params, M.timeout_ms)
    if ok then results = res end
  end
  if not results then return nil end

  local row = cursor.line - 1
  local col = cursor.col0 or 0

  local best = nil
  local best_size = nil
  local best_range = nil

  local function size_of(range)
    if not range then return math.huge end
    local s = range.start
    local e = range["end"]
    return (e.line - s.line) * 1000 + (e.character - s.character)
  end

  local function consider(sym)
    local range = sym.range or (sym.location and sym.location.range)
    if not range then return end
    if not in_range(range, row, col) then return end
    local sz = size_of(range)
    if not best or sz < best_size then
      best = sym
      best_range = range
      best_size = sz
    end
  end

  local function visit(symbols)
    if not symbols or type(symbols) ~= "table" then return end
    for _, sym in ipairs(symbols) do
      if type(sym) == "table" then
        consider(sym)
        if sym.children then visit(sym.children) end
      end
    end
  end

  for _, resp in pairs(results) do
    if resp and resp.result and type(resp.result) == "table" and #resp.result > 0 then
      -- resp.result pode ser DocumentSymbol[] ou SymbolInformation[]
      visit(resp.result)
    end
  end

  if not best then return nil end

  local range_obj = best_range or best.range or (best.location and best.location.range)
  local range_str = range_to_str(range_obj)

  local kind = best.kind
  local kind_name = nil
  if kind and vim.lsp.protocol and vim.lsp.protocol.SymbolKind then
    kind_name = vim.lsp.protocol.SymbolKind[kind]
  end
  if type(kind_name) ~= "string" then kind_name = kind_name and tostring(kind_name) or (kind and tostring(kind) or "") end

  local name = best.name or ""
  local detail = best.detail or ""
  -- SymbolInformation usa containerName; DocumentSymbol não tem
  local container = best.containerName or ""

  -- normaliza detail/container vazios
  if type(detail) ~= "string" then detail = "" end
  if type(container) ~= "string" then container = "" end
  if type(name) ~= "string" then name = tostring(name) end

  if name == "" then return nil end

  local sr, sc, er, ec
  if range_obj then
    sr = range_obj.start.line
    sc = range_obj.start.character
    er = range_obj["end"].line
    ec = range_obj["end"].character
  end

  return {
    name = name,
    kind = kind,
    kind_name = kind_name,
    range = range_str,
    detail = detail,
    container = container,
    sr = sr, sc = sc, er = er, ec = ec,
    raw = best,
  }
end

return M
