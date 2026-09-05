-- lua/core/pi_context.lua - captura mínima de contexto do Neovim
-- API: M.get(bufnr?), M.format(ctx, opts?)
-- Não depende de core.pi

local M = {}

local function rel_path(path)
  if path == "" or path == nil then return "[No Name]" end
  local rel = vim.fn.fnamemodify(path, ":~:.")
  if rel == "" then return path end
  return rel
end

local function get_cursor()
  local ok, cur = pcall(vim.api.nvim_win_get_cursor, 0)
  if not ok or not cur then return { line = 1, col = 1, col0 = 0 } end
  return { line = cur[1], col = cur[2] + 1, col0 = cur[2] }
end

function M.get(bufnr, opts)
  if type(bufnr) == "table" and opts == nil then opts = bufnr; bufnr = nil end
  local buf = bufnr
  if buf == nil or buf == 0 then buf = vim.api.nvim_get_current_buf() end
  if type(buf) == "table" then buf = vim.api.nvim_get_current_buf(); opts = bufnr end
  if not vim.api.nvim_buf_is_valid(buf) then return nil end
  local path = vim.api.nvim_buf_get_name(buf)
  local display = rel_path(path)
  local ft = vim.bo[buf].filetype or ""
  local cursor = get_cursor()
  return {
    buf = buf,
    path = path,
    rel_path = display,
    filetype = ft,
    cursor = cursor,
  }
end

function M.format(ctx, opts)
  if not ctx then return "" end
  opts = opts or {}
  local ft = ctx.filetype ~= "" and ctx.filetype or "text"
  local file_attr = ctx.rel_path or "[No Name]"
  file_attr = file_attr:gsub('"', "'")
  local cursor_str = string.format("%d:%d", ctx.cursor.line, ctx.cursor.col)
  local out = {}
  table.insert(out, string.format('<context file="%s" ft="%s" cursor="%s">', file_attr, ft, cursor_str))
  table.insert(out, "</context>")
  return table.concat(out, "\n")
end

vim.api.nvim_create_user_command("PiContext", function(cmd_opts)
  local bufnr = 0
  if cmd_opts.args and cmd_opts.args ~= "" then
    local n = tonumber(cmd_opts.args)
    if n then bufnr = n end
  end
  local ctx = M.get(bufnr)
  if not ctx then vim.notify("[pi_context] buffer inválido", vim.log.levels.ERROR); return end
  local formatted = M.format(ctx)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(formatted, "\n", {plain=true}))
  vim.bo[buf].filetype = "markdown"
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)
  if width < 40 then width = 40 end
  if height < 10 then height = 10 end
  local row = math.floor((vim.o.lines - height)/2)
  local col = math.floor((vim.o.columns - width)/2)
  local win = vim.api.nvim_open_win(buf, true, {relative="editor", width=width, height=height, row=row, col=col, style="minimal", border="rounded", title=" PiContext ", title_pos="center"})
  vim.keymap.set("n", "q", function() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win,true) end end, {buffer=buf, silent=true})
  print(formatted)
end, {nargs="?", desc="Mostra contexto Pi (file, ft, cursor, seleção)"})

function M.prompt_with_context(text, ctx_opts)
  local ctx = M.get(ctx_opts and ctx_opts.bufnr or 0, ctx_opts)
  local formatted = M.format(ctx, ctx_opts)
  local msg = text or ""
  if formatted and formatted ~= "" then msg = msg .. "\n\n" .. formatted end
  local ok, pi = pcall(require, "core.pi")
  if not ok then vim.notify("[pi_context] core.pi não carregado", vim.log.levels.ERROR); return end
  pi.prompt(msg)
end

vim.api.nvim_create_user_command("PiContextPrompt", function(opts)
  local text = opts.args
  if text == "" then text = vim.fn.input("pi com contexto: ") end
  M.prompt_with_context(text, {})
end, {nargs="*", desc="Envia Pi com contexto (metadados + seleção)"})

return M
