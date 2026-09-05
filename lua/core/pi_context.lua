-- lua/core/pi_context.lua - captura mínima de contexto do Neovim
-- API: M.get(bufnr?), M.format(ctx, opts?)
-- Não depende de core.pi

local M = {}

-- Janela de contexto ao redor do cursor quando não há seleção (5 antes + 5 depois)
-- Configurável: M.context_lines = 5 (ou número)
M.context_lines = 5

-- Helpers internos
local function rel_path(path)
  if path == "" or path == nil then return "[No Name]" end
  local rel = vim.fn.fnamemodify(path, ":~:.")
  if rel == "" then return path end
  return rel
end

local function get_cursor()
  local ok, cur = pcall(vim.api.nvim_win_get_cursor, 0)
  if not ok or not cur then return { line = 1, col = 1, col0 = 0 } end
  -- cur = {line 1-indexed, col 0-indexed byte}
  return { line = cur[1], col = cur[2] + 1, col0 = cur[2] }
end

-- Retorna seleção atual se existir, ou nil
-- Só captura quando há seleção visual ATIVA (v/V/block).
-- Não reutiliza visualmode() nem marcas '< / '> de seleções antigas.
-- Trata charwise (v), linewise (V) e blockwise (<C-v> = \22) e UTF-8 via getregion.
local function get_selection(buf, opts)
  local cur_mode = vim.fn.mode()
  local has_range = opts and opts.range == 2 and opts.count and opts.count ~= -1
  -- has_range indica :Pi chamado como :'<,'>Pi (range explícito)
  if has_range then
    -- seleção via range explícito: usa marcas '< e '> + visualmode
    local vmode = vim.fn.visualmode()
    if vmode == "" or vmode == nil then vmode = "v" end
    local s = vim.fn.getpos("'<")
    local e = vim.fn.getpos("'>")
    if not s or not e or s[2] == 0 or e[2] == 0 then return nil end
    -- verifica se marcas são válidas e pertencem ao buffer
    local buf_id = buf or vim.api.nvim_get_current_buf()
    -- se marks foram setadas via range, s/e já refletem line1/line2 mas com col de marks
    -- Usa getregion com vmode (preserva linewise/blockwise)
    local ok, lines = pcall(vim.fn.getregion, s, e, { type = vmode })
    if not ok or not lines or #lines == 0 or (#lines == 1 and lines[1] == "") then return nil end
    local s_line, s_col = s[2], s[3]
    local e_line, e_col = e[2], e[3]
    local range, mode_name = nil, vmode
    if vmode == "V" then
      if s_line == e_line then range = string.format("%d", s_line) else range = string.format("%d-%d", math.min(s_line,e_line), math.max(s_line,e_line)) end
    elseif vmode == "\22" or vmode == "\x16" then
      range = string.format("%d:%d-%d:%d", s_line, s_col, e_line, e_col); mode_name = "block"
    else
      range = string.format("%d:%d-%d:%d", s_line, s_col, e_line, e_col); mode_name = "v"
    end
    return { mode = mode_name, raw_mode = vmode, range = range, lines = lines, text = table.concat(lines, "\n"), s = { line = s_line, col = s_col }, e = { line = e_line, col = e_col } }
  end

  if cur_mode == "" or cur_mode == nil then return nil end
  local b = cur_mode:byte(1)
  local first = cur_mode:sub(1,1)
  local is_visual = first == "v" or first == "V" or b == 22
  if not is_visual then return nil end

  local vmode = first
  if b == 22 then vmode = "\22" end

  local s = vim.fn.getpos("v")
  local e = vim.fn.getpos(".")
  if not s or not e then return nil end
  if s[2] == 0 or e[2] == 0 then return nil end

  -- Usa getregion que já lida com linewise/blockwise/charwise corretamente
  -- type: "v" charwise, "V" linewise, "\22" blockwise
  local ok, lines = pcall(vim.fn.getregion, s, e, { type = vmode })
  if not ok or not lines then
    -- fallback para nvim_buf_get_text (só charwise/linewise)
    return nil
  end
  if #lines == 0 then return nil end
  -- getregion pode retornar {""} para seleção vazia
  if #lines == 1 and lines[1] == "" then return nil end

  -- Normaliza range para display 1-based
  -- s = [bufnum, lnum, col, off], e = [bufnum, lnum, col, off]
  -- col já é 1-based byte do vim.fn.getpos
  local s_line, s_col = s[2], s[3]
  local e_line, e_col = e[2], e[3]
  -- Para linewise, col é irrelevante, mostrar só linhas
  local range
  local mode_name = vmode
  if vmode == "V" then
    -- linewise: range L1-L2
    if s_line == e_line then range = string.format("%d", s_line)
    else range = string.format("%d-%d", math.min(s_line,e_line), math.max(s_line,e_line)) end
  elseif vmode == "\22" or vmode == "\x16" then
    -- blockwise: l1:c1 - l2:c2
    range = string.format("%d:%d-%d:%d", s_line, s_col, e_line, e_col)
    mode_name = "block"
  else
    -- charwise "v"
    range = string.format("%d:%d-%d:%d", s_line, s_col, e_line, e_col)
    mode_name = "v"
  end

  return {
    mode = mode_name,
    raw_mode = vmode,
    range = range,
    lines = lines,
    text = table.concat(lines, "\n"),
    s = { line = s_line, col = s_col },
    e = { line = e_line, col = e_col },
  }
end

function M.get(bufnr, opts)
  -- compat: permite M.get(opts) quando bufnr omitido e opts é tabela com range
  if type(bufnr) == "table" and opts == nil then opts = bufnr; bufnr = nil end
  local buf = bufnr
  if buf == nil or buf == 0 then buf = vim.api.nvim_get_current_buf() end
  if type(buf) == "table" then buf = vim.api.nvim_get_current_buf(); opts = bufnr end
  if not vim.api.nvim_buf_is_valid(buf) then return nil end

  local path = vim.api.nvim_buf_get_name(buf)
  local display = rel_path(path)
  local ft = vim.bo[buf].filetype or ""
  local cursor = get_cursor()
  local sel = get_selection(buf, opts)

  -- contexto estrutural Tree-sitter (prioridade 2): só quando não há seleção
  local structural = nil
  if not sel then
    local ok_p, provider = pcall(require, "core.pi_context.providers.treesitter")
    if ok_p and provider and provider.get then
      local ok_s, res = pcall(provider.get, buf, cursor)
      if ok_s and res and res.text and res.text ~= "" then structural = res end
    end
  end

  -- snippet ao redor do cursor quando não há seleção nem estrutural
  local snippet = nil
  if not sel and not structural then
    local total = vim.api.nvim_buf_line_count(buf)
    if total > 0 then
      local before = M.context_lines or 5
      local after = M.context_lines or 5
      -- permite opts sobrescrever
      if opts and opts.context_lines ~= nil then before = opts.context_lines; after = opts.context_lines end
      local cur_line = cursor.line
      local s_line = math.max(1, cur_line - before)
      local e_line = math.min(total, cur_line + after)
      if s_line <= e_line then
        local lines = vim.api.nvim_buf_get_lines(buf, s_line - 1, e_line, false)
        local range = s_line == e_line and tostring(s_line) or string.format("%d-%d", s_line, e_line)
        snippet = { range = range, lines = lines, s_line = s_line, e_line = e_line }
      end
    end
  end

  return {
    buf = buf,
    path = path,                 -- absoluto ou "" para [No Name]
    rel_path = display,          -- "[No Name]" ou relativo
    filetype = ft,
    cursor = cursor,             -- {line, col 1-based, col0}
    selection = sel,             -- nil ou {mode, range, lines, text, s, e}
    structural = structural,     -- nil ou {type, range, text, lang}
    snippet = snippet,           -- nil ou {range, lines} quando sem seleção nem estrutural
  }
end

function M.format(ctx, opts)
  if not ctx then return "" end
  opts = opts or {}
  local ft = ctx.filetype ~= "" and ctx.filetype or "text"
  -- filetype vazio -> text
  local file_attr = ctx.rel_path or "[No Name]"
  -- escapa " em path para atributo (simples)
  file_attr = file_attr:gsub('"', "'")
  local cursor_str = string.format("%d:%d", ctx.cursor.line, ctx.cursor.col)

  local out = {}
  table.insert(out, string.format('<context file="%s" ft="%s" cursor="%s">', file_attr, ft, cursor_str))

  if ctx.selection and ctx.selection.text and ctx.selection.text ~= "" then
    local range = ctx.selection.range or ""
    local mode = ctx.selection.mode or "v"
    -- delimita seleção
    table.insert(out, string.format('<selection range="%s" mode="%s">', range, mode))
    table.insert(out, string.format("```%s", ft ~= "" and ft or "text"))
    -- insere texto da seleção; preserva linhas como vieram de getregion
    for _, l in ipairs(ctx.selection.lines) do
      table.insert(out, l)
    end
    table.insert(out, "```")
    table.insert(out, "</selection>")
  elseif ctx.structural and ctx.structural.text and ctx.structural.text ~= "" then
    local srange = ctx.structural.range or ""
    local stype = ctx.structural.type or "structural"
    stype = stype:gsub('"', "'")
    table.insert(out, string.format('<structural type="%s" range="%s">', stype, srange))
    table.insert(out, string.format("```%s", ft ~= "" and ft or "text"))
    for _, l in ipairs(vim.split(ctx.structural.text, "\n", {plain=true})) do
      table.insert(out, l)
    end
    table.insert(out, "```")
    table.insert(out, "</structural>")
  elseif ctx.snippet and ctx.snippet.lines then
    table.insert(out, string.format('<snippet range="%s">', ctx.snippet.range))
    table.insert(out, string.format("```%s", ft ~= "" and ft or "text"))
    for _, l in ipairs(ctx.snippet.lines) do
      table.insert(out, l)
    end
    table.insert(out, "```")
    table.insert(out, "</snippet>")
  end

  table.insert(out, "</context>")
  return table.concat(out, "\n")
end

-- Comando de teste: mostra contexto gerado
vim.api.nvim_create_user_command("PiContext", function(cmd_opts)
  local bufnr = 0
  if cmd_opts.args and cmd_opts.args ~= "" then
    local n = tonumber(cmd_opts.args)
    if n then bufnr = n end
  end
  local ctx = M.get(bufnr)
  if not ctx then
    vim.notify("[pi_context] buffer inválido", vim.log.levels.ERROR)
    return
  end
  local formatted = M.format(ctx)
  -- mostra em float ou echo
  -- tenta abrir float como core.pi faz
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(formatted, "\n", {plain=true}))
  vim.bo[buf].filetype = "markdown"
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)
  if width < 40 then width = 40 end
  if height < 10 then height = 10 end
  local row = math.floor((vim.o.lines - height)/2)
  local col = math.floor((vim.o.columns - width)/2)
  local win = vim.api.nvim_open_win(buf, true, {
    relative="editor", width=width, height=height, row=row, col=col,
    style="minimal", border="rounded", title=" PiContext ",
    title_pos="center",
  })
  vim.keymap.set("n", "q", function() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win,true) end end, {buffer=buf, silent=true})
  -- também echo para headless
  print(formatted)
end, {nargs="?", desc="Mostra contexto Pi (file, ft, cursor, seleção)"})

-- Wrapper desacoplado: prompt com contexto sem fazer core.pi conhecer pi_context
function M.prompt_with_context(text, ctx_opts)
  local ctx = M.get(ctx_opts and ctx_opts.bufnr or 0, ctx_opts)
  local formatted = M.format(ctx, ctx_opts)
  local msg = text or ""
  if formatted and formatted ~= "" then
    -- se há seleção, inclui, senão inclui só metadados (útil para validar)
    msg = msg .. "\n\n" .. formatted
  end
  -- require tardio para não criar dependência circular no load
  local ok, pi = pcall(require, "core.pi")
  if not ok then
    vim.notify("[pi_context] core.pi não carregado", vim.log.levels.ERROR)
    return
  end
  pi.prompt(msg)
end

vim.api.nvim_create_user_command("PiContextPrompt", function(opts)
  local text = opts.args
  if text == "" then text = vim.fn.input("pi com contexto: ") end
  M.prompt_with_context(text, {})
end, {nargs="*", desc="Envia Pi com contexto (metadados + seleção)"})

return M
