vim.g.rustaceanvim = {
    server = {
        on_attach = function(_, bufnr)
            local opts = { buffer = bufnr, silent = true }

            vim.keymap.set("n", "<leader>a", function()
                vim.cmd.RustLsp("codeAction")
            end, opts)

            vim.keymap.set("n", "K", function()
                vim.cmd.RustLsp({ "hover", "actions" })
            end, opts)
        end,
        default_settings = {
            ["rust-analyzer"] = {
                -- Executa verificações ao salvar.
                checkOnSave = true,

                cargo = {
                    -- Analisa apenas as features padrão.
                    -- Troque para true apenas se você realmente precisar
                    -- de todas as features durante o desenvolvimento.
                    allFeatures = false,

                    buildScripts = {
                        -- Mantenha true na maioria dos projetos.
                        -- Coloque false apenas se quiser reduzir ainda mais
                        -- o uso de CPU/RAM e souber que seu projeto não
                        -- depende de build.rs.
                        enable = false,
                    },
                },

                procMacro = {
                    -- Desabilita a expansão de procedural macros.
                    -- Geralmente melhora bastante o desempenho.
                    -- Se notar problemas com crates como serde, clap,
                    -- thiserror, tokio etc., volte para true.
                    enable = false,
                },

                check = {
                    -- Mais rápido para o dia a dia.
                    -- command = "check",

                    -- Se preferir usar Clippy ao salvar, substitua por:
                    command = "clippy",
                    -- E, opcionalmente:
                    extraArgs = {
                        "--",
                        "-W",
                        "clippy::pedantic",
                    },
                },
            },
        },
    },
}
