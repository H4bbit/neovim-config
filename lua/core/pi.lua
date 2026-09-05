-- lua/core/pi.lua - núcleo RPC mínimo para pi --mode rpc
-- Fundação: 1 job persistente, framing LF-only, demux response/event, streaming text_delta

local M = {}

local state = {
  job_id = nil,
  buf = nil,
  win = nil,
  stdout_buf = "",
  is_streaming = false,
  pending = {},
  seq = 0,
}

local function ensure_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = "hide"
  vim.bo[state.buf].filetype = "markdown"
  vim.bo[state.buf].swapfile = false
  return state.buf
end

local function ensure_win()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    return state.win
  end
  local buf = ensure_buf()
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.6)
  if width < 40 then width = 40 end
  if height < 10 then height = 10 end
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  state.win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " pi ",
    title_pos = "center",
  })
  -- q para fechar, <Esc> também
  pcall(vim.keymap.set, "n", "q", function()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_close(state.win, true)
      state.win = nil
    end
  end, { buffer = buf, silent = true, desc = "Fechar pi float" })
  return state.win
end

local function append(delta)
  local buf = ensure_buf()
  ensure_win()
  -- append deve rodar no main loop; on_stdout já está no main loop mas
  -- usamos vim.schedule para garantir não bloquear callback rápido
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    -- pega última linha atual para concatenar delta que pode não ter \n
    local line_count = vim.api.nvim_buf_line_count(buf)
    local last = vim.api.nvim_buf_get_lines(buf, line_count - 1, line_count, false)[1] or ""
    -- se buffer começou vazio (1 linha vazia), last == ""
    local parts = vim.split(delta, "\n", { plain = true })
    if #parts == 1 then
      vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count, false, { last .. parts[1] })
    else
      vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count, false, { last .. parts[1] })
      if #parts > 1 then
        vim.api.nvim_buf_set_lines(buf, line_count, -1, false, vim.list_slice(parts, 2, #parts))
      end
    end
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      pcall(vim.api.nvim_win_set_cursor, state.win, { vim.api.nvim_buf_line_count(buf), 0 })
    end
    vim.cmd("redraw")
  end)
end

local function handle(evt)
  if evt.type == "response" then
    if evt.id and state.pending[evt.id] then
      local cb = state.pending[evt.id]
      state.pending[evt.id] = nil
      pcall(cb, evt)
    end
    if evt.success == false then
      vim.schedule(function()
        vim.notify("[pi] " .. (evt.error or "erro desconhecido"), vim.log.levels.ERROR)
      end)
    end
    return
  end
  if evt.type == "extension_ui_request" then
    -- v1: ignora fire-and-forget, loga dialog se aparecer
    vim.schedule(function()
      vim.notify("[pi] extension_ui_request: " .. (evt.method or "?"), vim.log.levels.DEBUG)
    end)
    return
  end
  if evt.type == "agent_start" then
    state.is_streaming = true
    vim.schedule(function()
      local buf = ensure_buf()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      ensure_win()
    end)
  elseif evt.type == "message_update" then
    local ae = evt.assistantMessageEvent
    if ae and ae.type == "text_delta" and ae.delta then
      append(ae.delta)
    end
  elseif evt.type == "agent_settled" then
    state.is_streaming = false
    vim.schedule(function()
      -- garante que float está visível no fim
      ensure_win()
    end)
  elseif evt.type == "extension_error" then
    vim.schedule(function()
      vim.notify("[pi] extension_error: " .. vim.inspect(evt), vim.log.levels.ERROR)
    end)
  end
  -- demais eventos (turn_start, message_start, etc) ignorados na v1 mas já demultiplexados
end

local function on_stdout(_, data)
  if not data then return end
  -- Neovim envia [''] no EOF, ignorar; também pode vir {'',''} em splits
  if #data == 1 and data[1] == "" then return end
  -- data pode conter '' como sentinela de \n no fim; table.concat restaura framing exato
  local text = table.concat(data, "\n")
  state.stdout_buf = state.stdout_buf .. text
  while true do
    local nl = state.stdout_buf:find("\n", 1, true)
    if not nl then break end
    local line = state.stdout_buf:sub(1, nl - 1)
    state.stdout_buf = state.stdout_buf:sub(nl + 1)
    if line:sub(-1) == "\r" then line = line:sub(1, -2) end
    if line ~= "" then
      local ok, evt = pcall(vim.json.decode, line)
      if ok and evt then
        handle(evt)
      else
        vim.schedule(function()
          vim.notify("[pi] JSON inválido: " .. line:sub(1, 200), vim.log.levels.WARN)
        end)
      end
    end
  end
end

local function is_alive()
  if not state.job_id then return false end
  local ok, info = pcall(vim.api.nvim_get_chan_info, state.job_id)
  return ok and info ~= nil and info.id ~= nil
end

local function start()
  if is_alive() then return state.job_id end
  -- limpar estado anterior
  state.stdout_buf = ""
  state.is_streaming = false
  -- não limpar pending aqui: on_exit já limpou, mas se start foi chamado após falha
  state.job_id = vim.fn.jobstart({ "pi", "--mode", "rpc" }, {
    on_stdout = on_stdout,
    on_stderr = function(_, d)
      local m = table.concat(d, "\n")
      if m:match("%S") then
        vim.schedule(function()
          vim.notify("[pi stderr] " .. m:sub(1, 500), vim.log.levels.WARN)
        end)
      end
    end,
    on_exit = function(_, code, _)
      vim.schedule(function()
        for _, cb in pairs(state.pending) do
          pcall(cb, { success = false, error = "pi exit code=" .. tostring(code) })
        end
        state.pending = {}
        state.job_id = nil
        state.is_streaming = false
        if code ~= 0 then
          vim.notify("[pi] processo encerrou code=" .. tostring(code), vim.log.levels.WARN)
        end
      end)
    end,
    stdout_buffered = false,
    stderr_buffered = false,
  })
  if not state.job_id or state.job_id <= 0 then
    state.job_id = nil
    error("falha ao iniciar pi --mode rpc (jobstart retornou " .. tostring(state.job_id) .. ")")
  end
  return state.job_id
end

function M.send(cmd, cb)
  start()
  state.seq = state.seq + 1
  cmd.id = tostring(state.seq)
  if cb then state.pending[cmd.id] = cb end
  local line = vim.json.encode(cmd) .. "\n"
  local ok = vim.fn.chansend(state.job_id, line)
  if ok == 0 then
    if cb then state.pending[cmd.id] = nil end
    vim.notify("[pi] chansend falhou (canal fechado)", vim.log.levels.ERROR)
    state.job_id = nil
  end
  return cmd.id
end

function M.prompt(text)
  if state.is_streaming then
    vim.notify("[pi] já está respondendo — aguarde ou :PiAbort", vim.log.levels.WARN)
    return
  end
  if not text or text:match("^%s*$") then
    text = vim.fn.input("pi: ")
  end
  if not text or text == "" then return end
  M.send({ type = "prompt", message = text })
end

function M.abort()
  if not state.is_streaming then
    vim.notify("[pi] nada para abortar", vim.log.levels.INFO)
    return
  end
  M.send({ type = "abort" })
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  else
    ensure_win()
  end
end

function M.get_state() return { job_id = state.job_id, is_streaming = state.is_streaming, buf = state.buf, win = state.win } end

-- comandos
vim.api.nvim_create_user_command("Pi", function(opts) require("core.pi_context").prompt_with_context(opts.args, { range = opts.range, line1 = opts.line1, line2 = opts.line2, count = opts.count }) end, { nargs = "*", range = true, desc = "Enviar prompt ao pi" })
vim.api.nvim_create_user_command("PiAbort", function() M.abort() end, { desc = "Abortar geração pi" })
vim.api.nvim_create_user_command("PiToggle", function() M.toggle() end, { desc = "Toggle float pi" })

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if state.job_id then pcall(vim.fn.jobstop, state.job_id) end
  end,
  desc = "Finaliza pi --mode rpc ao sair",
})

return M
