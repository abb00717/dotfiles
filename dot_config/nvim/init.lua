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
        "p00f/alabaster.nvim",
        priority = 1000,
        config = function()
            vim.cmd("colorscheme alabaster")

            local bg = "#efebe3"
            vim.api.nvim_set_hl(0, "Normal", { bg = bg })
            vim.api.nvim_set_hl(0, "NormalNC", { bg = bg })
            vim.api.nvim_set_hl(0, "SignColumn", { bg = bg })
            vim.api.nvim_set_hl(0, "LineNr", { bg = bg })
            vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = bg })
            vim.api.nvim_set_hl(0, "CursorLine", { bg = "#d8d8d8" })
        end,
    },
    {
        "echasnovski/mini.statusline",
        opts = { use_icons = vim.g.have_nerd_font },
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

    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "nvim-telescope/telescope-ui-select.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("telescope").setup({
                extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown() } },
            })
            pcall(require("telescope").load_extension, "fzf")
            pcall(require("telescope").load_extension, "ui-select")
        end,
    },

    -- LSP & Completion
    {
        "saghen/blink.cmp",
        version = "v0.*",
        dependencies = { "rafamadriz/friendly-snippets", "L3MON4D3/LuaSnip" },
        opts = {
            snippets = { preset = "luasnip" },
            keymap = { preset = "default" },
            appearance = { use_nvim_cmp_as_default = true, nerd_font_variant = "mono" },
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
            local servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            completion = { callSnippet = "Replace" },
                            format = { enable = true, default_config = { indent_style = "space", indent_size = "4" } },
                        },
                    },
                },
                marksman = {},
                pyright = {},
                clangd = {},
                rust_analyzer = {},
            }
            local formatters = { "stylua", "clang-format", "isort", "black", "prettier" }
            require("mason").setup()
            require("mason-tool-installer").setup({
                ensure_installed = vim.iter({ vim.tbl_keys(servers), formatters }):flatten():totable(),
            })
            require("mason-lspconfig").setup({
                handlers = {
                    function(server_name)
                        local server = servers[server_name] or {}
                        server.capabilities = require("blink.cmp").get_lsp_capabilities(server.capabilities)
                        require("lspconfig")[server_name].setup(server)
                    end,
                },
            })
            vim.diagnostic.config({
                virtual_text = false,
                signs = false,
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
    {
        "stevearc/conform.nvim",
        opts = {
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                return { timeout_ms = 500, lsp_format = "fallback" }
            end,
            formatters_by_ft = { lua = { "stylua" }, python = { "isort", "black" }, markdown = { "prettier" } },
            formatters = { stylua = { prepend_args = { "--indent-type", "Spaces", "--indent-width", "4" } } },
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate",
        opts = {
            ensure_installed = { "bash", "c", "cpp", "html", "rust", "markdown", "python" },
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
        },
        config = function(_, opts)
            require("nvim-treesitter").setup(opts)
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
            on_attach = function(bufnr)
                local gitsigns = require("gitsigns")

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gitsigns.nav_hunk("next")
                    end
                end, { desc = "Next Git Hunk" })

                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gitsigns.nav_hunk("prev")
                    end
                end, { desc = "Previous Git Hunk" })

                -- Actions
                map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Stage Hunk" })
                map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Reset Hunk" })
                map("v", "<leader>hs", function()
                    gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { desc = "Stage Hunk (Visual)" })
                map("v", "<leader>hr", function()
                    gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { desc = "Reset Hunk (Visual)" })
                map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "Stage Buffer" })
                map("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "Undo Staged Hunk" })
                map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "Reset Buffer" })
                map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Preview Hunk" })
                map("n", "<leader>hb", function()
                    gitsigns.blame_line({ full = true })
                end, { desc = "Blame Line" })
                map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "Toggle Blame Line" })
                map("n", "<leader>hd", gitsigns.diffthis, { desc = "Diff This" })
                map("n", "<leader>hD", function()
                    gitsigns.diffthis("~")
                end, { desc = "Diff This (~)" })
                map("n", "<leader>td", gitsigns.toggle_deleted, { desc = "Toggle Deleted" })
            end,
        },
    },
    {
        "sindrets/diffview.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("diffview").setup({
                enhanced_diff_hl = true,
                hooks = {
                    diff_buf_read = function(bufnr)
                        vim.opt_local.foldenable = false
                    end,
                },
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
