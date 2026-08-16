local M = {}

local MAX_FILESIZE = 100 * 1024
local AUGROUP = "CoreWinbarContext"

local state = {}

local function is_supported_buffer(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    if vim.bo[bufnr].buftype ~= "" then
        return false
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        return false
    end

    local ok, stat = pcall(vim.uv.fs_stat, name)
    if ok and stat and stat.size > MAX_FILESIZE then
        return false
    end

    return true
end

local function get_state(bufnr)
    local st = state[bufnr]
    if not st then
        st = {
            symbols = nil,
            timer = nil,
            seq = 0,
        }
        state[bufnr] = st
    end
    return st
end

local function stop_timer(st)
    if not st.timer then
        return
    end

    pcall(function()
        st.timer:stop()
        st.timer:close()
    end)

    st.timer = nil
end

local function contains(range, row, col)
    if not range or not range.start or not range["end"] then
        return false
    end

    local s = range.start
    local e = range["end"]

    if row < s.line or row > e.line then
        return false
    end

    if row == s.line and col < s.character then
        return false
    end

    if row == e.line and col >= e.character then
        return false
    end

    return true
end

local function is_callable_symbol(kind)
    return kind == vim.lsp.protocol.SymbolKind.Function
        or kind == vim.lsp.protocol.SymbolKind.Method
        or kind == vim.lsp.protocol.SymbolKind.Constructor
end

local function symbol_label(node)
    local name = node.name or ""
    if name == "" then
        return ""
    end

    if is_callable_symbol(node.kind) then
        return name .. "()"
    end

    return name
end

local function format_path(path)
    local parts = {}

    for _, node in ipairs(path or {}) do
        local text = symbol_label(node)
        if text ~= "" then
            parts[#parts + 1] = text
        end
    end

    return table.concat(parts, "  ")
end

local function deepest_path(nodes, row, col, path)
    for _, node in ipairs(nodes or {}) do
        local range = node.range or (node.location and node.location.range)
        if range and contains(range, row, col) then
            local next_path = vim.deepcopy(path or {})
            next_path[#next_path + 1] = node

            local child_path = deepest_path(node.children or {}, row, col, next_path)
            return child_path or next_path
        end
    end
end

local function refresh_buffer(bufnr)
    if not is_supported_buffer(bufnr) then
        local st = state[bufnr]
        if st then
            st.symbols = nil
        end

        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
                vim.cmd.redrawstatus()
            end
        end)

        return
    end

    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    local has_symbol_client = false

    for _, client in ipairs(clients) do
        if client:supports_method("textDocument/documentSymbol", bufnr) then
            has_symbol_client = true
            break
        end
    end

    local st = get_state(bufnr)

    if not has_symbol_client then
        st.symbols = nil
        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
                vim.cmd.redrawstatus()
            end
        end)
        return
    end

    st.seq = st.seq + 1
    local seq = st.seq

    vim.lsp.buf_request_all(bufnr, "textDocument/documentSymbol", {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    }, function(results)
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        local current = state[bufnr]
        if current ~= st or current.seq ~= seq then
            return
        end

        local trees = {}

        for _, response in pairs(results) do
            if response and response.result and not response.error and not response.err then
                local result = response.result
                if vim.islist(result) and #result > 0 then
                    trees[#trees + 1] = result
                end
            end
        end

        st.symbols = trees

        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
                vim.cmd.redrawstatus()
            end
        end)
    end)
end

function M.setup()
    local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })

    local function schedule_refresh(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        local st = get_state(bufnr)
        stop_timer(st)

        st.timer = vim.uv.new_timer()
        st.timer:start(150, 0, vim.schedule_wrap(function()
            stop_timer(st)
            refresh_buffer(bufnr)
        end))
    end

    vim.api.nvim_create_autocmd({
        "BufEnter",
        "TextChanged",
        "TextChangedI",
        "InsertLeave",
        "LspAttach",
    }, {
        group = group,
        callback = function(ev)
            schedule_refresh(ev.buf)
        end,
    })

    vim.api.nvim_create_autocmd({
        "BufWipeout",
        "BufUnload",
    }, {
        group = group,
        callback = function(ev)
            local st = state[ev.buf]
            if st then
                stop_timer(st)
                state[ev.buf] = nil
            end
        end,
    })
end

function M.context()
    local bufnr = vim.api.nvim_get_current_buf()

    if not is_supported_buffer(bufnr) then
        return ""
    end

    local st = state[bufnr]
    if not st or not st.symbols or #st.symbols == 0 then
        return ""
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1

    local best

    for _, symbols in ipairs(st.symbols) do
        local path = deepest_path(symbols, row, col, {})
        if path and (#path > (best and #best or 0)) then
            best = path
        end
    end

    return best and format_path(best) or ""
end

return M
