local lspconfig = require("lspconfig")
local cmp = require("cmp")
local luasnip = require("luasnip")
--local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("luasnip.loaders.from_vscode").lazy_load()
luasnip.config.setup({})

local check_backspace = function()
    local col = vim.fn.col(".") - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
end

cmp.setup({
    sources = cmp.config.sources({
        { name = "luasnip" },
        { name = "buffer",  keyword_length = 3 },
        { name = "nvim_lsp" },
        { name = "path",    keyword_length = 2 },
    }),
    preselect = "aways", --"item",
    completion = {
        completeopt = "menu,menuone,noinsert",
    },

    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    --	{ name = "buffer" },

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
            elseif check_backspace then
                fallback()
            else
                fallback()
            end
        end, { "i", "s" }),
    }),
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

local servers = {
    "clangd",
    --"pyright",
    "jedi_language_server",
    "rust_analyzer",
    "lua_ls",
}

for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup({
        -- on_attach = my_custom_on_attach,
        capabilities = capabilities,
    })
end

--format on save
vim.cmd([[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]])
