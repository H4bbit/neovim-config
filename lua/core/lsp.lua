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
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})

cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    }),
    matching = { disallow_symbol_nonprefix_matching = false }
})

-- 3. Capabilities do nvim-cmp para os servidores LSP
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- 4. Nova Configuração de Servidores LSP (Neovim >= 0.12)
local servers = {
    "clangd",
    "jedi_language_server",
    "lua_ls",
    "ts_ls", -- Atualizado: tsserver foi renomeado para ts_ls
}

for _, server in ipairs(servers) do
    -- Adiciona as configurações extras (capabilities do cmp) ao servidor
    vim.lsp.config(server, {
        capabilities = capabilities,
    })

    -- Habilita o servidor com a nova API
    vim.lsp.enable(server)
end

-- 5. Format on Save (A abordagem correta e moderna)
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local bufnr = args.buf
        -- Verifica se o servidor atual suporta formatação de documento
        if client and client.server_capabilities.documentFormattingProvider then
            -- Cria o evento de salvar atrelado apenas a este buffer específico
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = vim.api.nvim_create_augroup("LspFormat_" .. bufnr, { clear = true }),
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = false })
                end,
            })
        end
    end,
})
