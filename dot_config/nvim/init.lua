require("options")
require("keymaps")
require("autocmds")

-- Lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins setup
require("lazy").setup({
    -- UI
    {
        "ABB00717/alabaster.nvim",
        -- dir = '~/Programming/Projects/alabaster.nvim',
        priority = 1000,
        config = function()
            vim.cmd("colorscheme alabaster")
        end,
    },
    {
        "echasnovski/mini.indentscope",
        config = function()
            local indentscope = require("mini.indentscope")
            indentscope.setup({
                draw = { animation = indentscope.gen_animation.none() },
                options = { try_as_border = true },
            })

            vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#a39c92" })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "neo-tree", "help", "TelescopePrompt", "lazy", "mason", "checkhealth" },
                callback = function()
                    vim.b.miniindentscope_disable = true
                end,
            })
        end,
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
        opts = {
            filesystem = {
                window = { position = "current" },
                mappings = { ["\\"] = "close_window" },
            },
        },
    },
    { "folke/which-key.nvim", event = "VimEnter", opts = { icons = { mappings = vim.g.have_nerd_font } } },
    {
        "nvim-treesitter/nvim-treesitter-context",
        config = function()
            require("treesitter-context").setup({
                enable = true,
                line_numbers = false,
                max_lines = -1,
                trim_scope = "outer",
                mode = "topline",
            })
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "nvim-telescope/telescope-ui-select.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local actions = require("telescope.actions")
            require("telescope").setup({
                defaults = {
                    -- So "Search by Grep" won't look that messy
                    path_display = { "filename_first" },
                    dynamic_preview_title = true,
                    layout_config = {
                        horizontal = { preview_width = 0.70 },
                    },
                    mappings = {
                        i = { ["<Esc>"] = actions.close },
                    },
                    vimgrep_arguments = {
                        "rg",
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--smart-case",
                        "--trim",
                    },
                },
                extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown() } },
            })
            pcall(require("telescope").load_extension, "fzf")
            pcall(require("telescope").load_extension, "ui-select")
        end,
    },
    {
        -- For auto completion
        "saghen/blink.cmp",
        version = "v1.*",
        dependencies = { "rafamadriz/friendly-snippets", "L3MON4D3/LuaSnip" },
        opts = {
            snippets = { preset = "luasnip" },
            -- See :h blink-cmp-config-keymap for defining your own keymap
            keymap = { preset = "default" },
            appearance = { nerd_font_variant = "mono" },
            completion = { documentation = { auto_show = true } }, -- Show the docs automatically
            signature = { enabled = true },
            sources = { default = { "lsp", "path", "snippets", "buffer" } },
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "j-hui/fidget.nvim",
            { "folke/lazydev.nvim", ft = "lua", opts = {} },
            "saghen/blink.cmp",
        },
        config = function()
            -- Only a bootstrap list for a fresh machine. mason-lspconfig enables
            -- every installed server on its own, so nothing has to be listed here
            -- for it to start.
            local servers = require("servers")
            -- One per language. A second formatter claiming the same filetype only
            -- adds another pass over the buffer, so the pick is made here rather
            -- than left to whatever the registry happens to return first.
            local formatters = require("formatters")
            require("mason-tool-installer").setup({
                ensure_installed = vim.iter({ servers, formatters }):flatten():totable(),
            })

            vim.lsp.config("*", {
                capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
            })
            -- Mason files stylua and rubocop under LSP as well as Formatter, so
            -- automatic_enable would start them as a second client on every lua and
            -- ruby buffer. conform already drives both through their CLI.
            require("mason-lspconfig").setup({
                automatic_enable = { exclude = { "stylua", "rubocop" } },
            })
            vim.diagnostic.config({
                virtual_text = true,
                signs = true,
                underline = false,
                update_in_insert = false,
            })
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(event)
                    require("keymaps").setup_lsp_keymaps(event.buf)
                end,
            })
        end,
    },
    { "williamboman/mason.nvim", opts = {} },
    {
        "stevearc/conform.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = function()
            -- Mason tags packages with display language names and its own package
            -- names; conform keys off filetypes and its own builtin names. Neither
            -- pair lines up by lowercasing alone.
            local ft_alias = {
                ["c++"] = "cpp",
                ["c#"] = "cs",
                jsx = "javascriptreact",
                tsx = "typescriptreact",
                assembly = "asm",
                shell = "sh",
                bash = "sh",
                mksh = "sh",
            }
            local name_alias = {
                ["sql-formatter"] = "sql_formatter",
                ["nginx-config-formatter"] = "nginxfmt",
            }

            local by_ft = {}
            for _, pkg in ipairs(require("mason-registry").get_installed_packages()) do
                if vim.tbl_contains(pkg.spec.categories, "Formatter") then
                    local name = name_alias[pkg.spec.name] or pkg.spec.name
                    for _, lang in ipairs(pkg.spec.languages or {}) do
                        local ft = lang:lower()
                        ft = ft_alias[ft] or ft
                        by_ft[ft] = by_ft[ft] or {}
                        -- Several Mason languages collapse onto one filetype (Shell,
                        -- Bash and Mksh are all sh), which would otherwise queue the
                        -- same formatter for repeated passes over the buffer.
                        if not vim.tbl_contains(by_ft[ft], name) then
                            table.insert(by_ft[ft], name)
                        end
                    end
                end
            end

            -- The registry returns packages in no particular order, and clang-format
            -- claims half the C family plus JSON and Java. Anything with a real
            -- preference, or an order that matters, is pinned here.
            by_ft = vim.tbl_extend("force", by_ft, {
                python = { "isort", "black" },
                javascript = { "standardjs" },
                json = { "prettier" },
                java = { "google-java-format" },
            })

            return {
                format_on_save = function(bufnr)
                    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                        return
                    end
                    return { timeout_ms = 500, lsp_format = "fallback" }
                end,
                formatters_by_ft = by_ft,
                formatters = {
                    stylua = { prepend_args = { "--indent-type", "Spaces", "--indent-width", "4" } },
                    ["pretty-php"] = { prepend_args = { "--one-true-brace-style" } },
                    nginxfmt = {
                        condition = function(_, ctx)
                            local lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)
                            return not vim.iter(lines):any(function(line)
                                -- Filter non Nginx grammar *_by_lua_block by OpenResty
                                return line:match("_by_lua_block%s*{") ~= nil
                            end)
                        end,
                    },
                },
            }
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        -- The main branch needs Nvim 0.12 and replaces configs.setup: parsers are
        -- installed imperatively, and highlighting is core's job via
        -- vim.treesitter.start. Upstream does not support lazy-loading it.
        branch = "main",
        lazy = false,
        -- Parsers are pinned per plugin revision, so they must be rebuilt on update.
        build = ":TSUpdate",
        config = function()
            local ts = require("nvim-treesitter")
            ts.setup()
            ts.install(require("parsers"))
            require("ts_autoinstall").setup(ts)
        end,
    },

    -- Git Integration
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            numhl = false,
            linehl = false,
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
            current_line_blame = true,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "right_align", -- 'eol' | 'overlay' | 'right_align'
                delay = 0,
                ignore_whitespace = true,
                virt_text_priority = 100,
                use_focus = true,
            },
            on_attach = function(bufnr)
                require("keymaps").setup_gitsigns_keymaps(bufnr)
            end,
        },
    },
    {
        "sindrets/diffview.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("diffview").setup({
                enhanced_diff_hl = true,
            })
        end,
    },
})

-- Custom Snippets
local ls = require("luasnip")
ls.add_snippets("all", {
    ls.snippet("trigger", { ls.text_node("Wow! Text!") }),
})

-- Diff Highlighting Customizations
-- Keep standard syntax highlighting for code lines, only highlight number/sign columns
local function set_diff_hl()
    -- Remove solid backgrounds from diff lines
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "NONE", fg = "#e06c75" }) -- Soft red for deletion filler lines
    vim.api.nvim_set_hl(0, "DiffText", { bg = "NONE", underline = true, bold = true }) -- Underline changed text

    -- Diffview sign column colors (icons in active review diff splits)
    -- Adjust 'fg' hex codes below to change the symbol colors
    vim.api.nvim_set_hl(0, "DiffviewSignAdd", { fg = "#448c27", bg = "NONE" }) -- Green sign for additions
    vim.api.nvim_set_hl(0, "DiffviewSignDelete", { fg = "#e06c75", bg = "NONE" }) -- Red sign for deletions
    vim.api.nvim_set_hl(0, "DiffviewSignChange", { fg = "#e5c07b", bg = "NONE" }) -- Yellow/Amber sign for changes

    -- GitSigns icon colors (icons in the left margin of standard files)
    -- Adjust 'fg' hex codes below to change normal editing sign colors
    vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#448c27", bg = "NONE" }) -- Green sign
    vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#e5c07b", bg = "NONE" }) -- Yellow sign
    vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#e06c75", bg = "NONE" }) -- Red sign
end

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = set_diff_hl,
})

-- Apply immediately
set_diff_hl()
