local cmp = require("cmp")
local luasnip = require("luasnip")

-- 1. Configuração do LuaSnip
require("luasnip.loaders.from_vscode").lazy_load()
luasnip.config.setup({})

local check_backspace = function()
    local col = vim.fn.col(".") - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
end

-- 2. Configuração do nvim-cmp
cmp.setup({
    sources = cmp.config.sources({
        { name = "buffer",  keyword_length = 3 },
        -- { name = "minuet" },
        { name = "path",    keyword_length = 2 },
        { name = "luasnip" },
        { name = "nvim_lsp" },
    }),
    preselect = "always",
    completion = {
        completeopt = "menu,menuone,noinsert",
    },
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete({}),
        ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        }),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif luasnip.expandable() then
                luasnip.expand()
            elseif check_backspace() then
                fallback()
            else
                fallback()
            end
        end, { "i", "s" }),
    }),
})

-- 2.5 Configuração do nvim-cmp para Linha de Comando (Substitui o wilder)
cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = "buffer" },
    },
})

cmp.setup.cmdline(":", {
    mapping = {
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.confirm({
                    select = true,
                    behavior = cmp.ConfirmBehavior.Replace,
                })
            else
                fallback()
            end
        end, { "c" }),

        ["<S-Tab>"] = cmp.mapping.select_prev_item(),

        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),

        ["<CR>"] = cmp.mapping.confirm({
            select = true,
            behavior = cmp.ConfirmBehavior.Replace,
        }),
    },
    sources = cmp.config.sources({
        { name = "path" },
    }, {
        {
            name = "cmdline",
            option = {
                ignore_cmds = { "Man", "!" },
                treat_trailing_slash = true,
            },
        },
    }),
    matching = { disallow_symbol_nonprefix_matching = false },
})
-- 3. Capabilities do nvim-cmp para os servidores LSP
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- 4. Nova Configuração de Servidores LSP (Neovim >= 0.12)
local servers = {
    "clangd",
    "basedpyright",
    "ruff",
    "ts_ls", -- Atualizado: tsserver foi renomeado para ts_ls
    "biome",
    "elmls",
}

vim.lsp.config("lua_ls", {
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME },
                -- se ainda precisar de limites mais agressivos:
                -- maxPreload = 1000,
                -- preloadFileSize = 100,
            },
            telemetry = {
                enable = false,
            },
        },
    },
})
vim.lsp.enable("lua_ls")

for _, server in ipairs(servers) do
    -- Adiciona as configurações extras (capabilities do cmp) ao servidor
    vim.lsp.config(server, {
        capabilities = capabilities,
    })

    -- Habilita o servidor com a nova API
    vim.lsp.enable(server)
end

-- 5. Format on Save (A abordagem correta e moderna)
local format_preference = {
    javascript = { "biome" },
    javascriptreact = { "biome" },
    typescript = { "biome" },
    typescriptreact = { "biome" },
    python = { "ruff" },
    c = { "clangd" },
    cpp = { "clangd" },
    lua = { "lua_ls" },
    rust = { "rust_analyzer", "rust-analyzer" },
    elm = { "elmls" },
}

local function format_priority(client_name, filetype)
    for priority, name in ipairs(format_preference[filetype] or {}) do
        if client_name == name then
            return priority
        end
    end

    return math.huge
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true }),
    callback = function(args)
        local bufnr = args.buf
        local group = vim.api.nvim_create_augroup("LspFormat_" .. bufnr, { clear = false })

        if #vim.api.nvim_get_autocmds({ group = group, event = "BufWritePre", buffer = bufnr }) > 0 then
            return
        end

        vim.api.nvim_create_autocmd("BufWritePre", {
            group = group,
            buffer = bufnr,
            callback = function()
                local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })
                local filetype = vim.bo[bufnr].filetype

                table.sort(clients, function(a, b)
                    local priority_a = format_priority(a.name, filetype)
                    local priority_b = format_priority(b.name, filetype)

                    if priority_a == priority_b then
                        return a.name < b.name
                    end

                    return priority_a < priority_b
                end)

                local client = clients[1]
                if client then
                    vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = false })
                end
            end,
        })
    end,
})
