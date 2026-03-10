--[[
=====================================================================
==================== NEOVIM CONCISE CONFIGURATION ===================
=====================================================================
A concise, outline-driven configuration.
Chapters:
1. Foundation (Options)
2. Manager (Lazy.nvim)
3. Plugins (UI, Tools, Intelligence, Knowledge)
4. Workflow (Custom Scripts)
]]

-- ==================================================================
-- Chapter 1: The Foundation
-- ==================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.g.termguicolors = true
vim.g.background = "light"

-- Options
vim.o.number = true
vim.o.relativenumber = true -- Line numbers
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true -- Indentation
vim.schedule(function()
    vim.o.clipboard = "unnamedplus"
end) -- Clipboard
vim.o.ignorecase = true
vim.o.smartcase = true -- Search
-- UI
vim.o.signcolumn = "yes"
vim.o.cursorline = true
vim.o.guicursor = "n-v-i-c:block-Cursor"
vim.o.scrolloff = 10 -- 原本我打算讓游標一直待在畫面中間，但這真的太暈了
vim.o.splitright = true
vim.o.splitbelow = true -- Splits
vim.o.list = false
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- Whitespace
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.confirm = true
vim.o.inccommand = "split"
vim.o.mouse = "a" -- Behavior
-- Obsidian
vim.o.conceallevel = 1

-- Basic Keymaps
vim.keymap.set("n", "!", ":!")
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear Search Highlights" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>")
vim.keymap.set("n", "<C-l>", "<C-w><C-l>")
vim.keymap.set("n", "<C-j>", "<C-w><C-j>")
vim.keymap.set("n", "<C-k>", "<C-w><C-k>")

-- ==================================================================
-- Chapter 2: The Manager
-- ==================================================================
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

-- ==================================================================
-- Chapter 3: The Plugins
-- ==================================================================
require("lazy").setup({

    -- [[ Section 3.1: UI & Aesthetics ]]
    -- 1. mini.statusline: Simple icons statusline
    -- 2. neo-tree: File Explorer (<leader>e)
    -- 3. which-key: Keymap Helper
    -- 4. image.nvim: Image support (Markdown)

    {
        "p00f/alabaster.nvim",
        priority = 1000,
        config = function()
            vim.cmd("colorscheme alabaster")
        end,
    },
    {
        "echasnovski/mini.statusline",
        config = function()
            require("mini.statusline").setup({ use_icons = vim.g.have_nerd_font })
        end,
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        lazy = false,
        branch = "v3.x",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
        keys = {
            { "<leader>e", ":Neotree toggle<CR>", desc = "Toggle Explorer" },
            { "<leader>tr", ":Neotree toggle current reveal_force_cwd<CR>", desc = "Reveal File" },
            -- nnoremap / :Neotree toggle current reveal_force_cwd<cr>
            -- nnoremap | :Neotree reveal<cr>
            -- nnoremap gd :Neotree float reveal_file=<cfile> reveal_force_cwd<cr>
            -- nnoremap <leader>b :Neotree toggle show buffers right<cr>
            -- nnoremap <leader>s :Neotree float git_status<cr>
        },
        opts = {
            filesystem = {
                window = {
                    position = "current",
                },
                mappings = {
                    ["\\"] = "close_window",
                },
            },
        },
    },
    { "folke/which-key.nvim", event = "VimEnter", opts = { icons = { mappings = vim.g.have_nerd_font } } },

    -- [[ Section 3.2: The Tools ]]
    -- 1. mini.ai/surround: Text objects & surroundings
    -- 2. guess-indent: Auto-detect indentation
    -- 3. Telescope: Fuzzy Finder (<leader>s...)
    -- 4. LuaSnip: Custom Snippets

    {
        "echasnovski/mini.nvim",
        config = function()
            require("mini.ai").setup({ n_lines = 500 })
            require("mini.surround").setup()
        end,
    },
    { "NMAC427/guess-indent.nvim", opts = {} },
    {
        "nvim-telescope/telescope.nvim",
        branch = "master",
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
            local builtin = require("telescope.builtin")
            -- Map: <leader>s...
            vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
            vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
            vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
            vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
            vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
            vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
            vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = "[S]earch Recent Files" })
            vim.keymap.set("n", "<leader>sds", builtin.lsp_document_symbols, { desc = "[S]earch [D]ocument [S]ymbols" })
            vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
            vim.keymap.set("n", "<leader>/", function()
                builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({ previewer = false }))
            end, { desc = "[/] Fuzzily search in current buffer" })
        end,
    },
    {
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!).
        build = "make install_jsregexp",
    },

    -- [[ Section 3.3: The Intelligence ]]
    -- 1. blink.cmp: Autocompletion (LSP, Snippets, Buffer)
    -- 2. nvim-lspconfig: Language Servers (Mason, Fidget, Lazydev)
    -- 3. conform.nvim: Formatting (Stylua, Black)
    -- 4. Treesitter: Syntax Highlighting

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
                ensure_installed = vim.tbl_flatten({ vim.tbl_keys(servers), formatters }),
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
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end
                    -- Inlay Hints: Enable automatically
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
                        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
                    end
                    -- Maps
                    map("<leader>gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
                    map("<leader>gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
                    map("<leader>gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
                    map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
                    map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
                    map(
                        "<leader>ws",
                        require("telescope.builtin").lsp_dynamic_workspace_symbols,
                        "[W]orkspace [S]ymbols"
                    )
                    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
                    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
                    map("<leader>K", vim.lsp.buf.hover, "Hover Documentation")
                    map("<leader>gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
                end,
            })
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = {
            notify_on_error = false,
            format_on_save = function(bufnr)
                -- Disable with a global or buffer-local variable
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
        lazy = false,
        opts = {
            ensure_installed = {
                "bash",
                "c",
                "cpp",
                "html",
                "lua",
                "luadoc",
                "rust",
                "markdown",
                "markdown_inline",
                "python",
                "vim",
                "vimdoc",
            },
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
        },
        -- config = function(_, opts)
        --     require("nvim-treesitter.configs").setup(opts)
        -- end,
    },

    -- [[ Section 3.4: Knowledge ]]
    -- 1. markdown-preview: Render narkdown in browser

    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown", "codecompanion" },
        opts = {
            heading = { enabled = false },
            bullet = { enabled = true, icons = { "-", "=", "+", "*" } },
            code = { enabled = true, width = "block" },
            latex = {
                enabled = true,
                render_modes = true,
                converter = { "utftex", "latex2text" },
                highlight = "RenderMarkdownMath",
                position = "center",
                top_pad = 0,
                bottom_pad = 0,
            },
        },
    },

    -- [[ Section 3.5: Music ]]
    -- 1. Strudel: Live Coding with your favorite editor, Neovim

    -- Run :StrudelLaunch to Launch
    -- Run :StrudelToggle to start and stop the playback
    -- Run :StrudelUpdate to trigger the update of your code
    -- Run :StrudelQuit to close your browser
    {
        "gruvw/strudel.nvim",
        build = "npm ci",
        config = function()
            require("strudel").setup()
        end,
    },
})

-- ==================================================================
-- Chapter 4: The Custom Workflow
-- ==================================================================

-- Open URI
vim.ui.open = (function(overridden)
    return function(uri, opt)
        if vim.endswith(uri, ".png") then
            vim.cmd("edit " .. uri) -- early return to just open in neovim
            return
        elseif vim.endswith(uri, ".pdf") then
            opt = { cmd = { "evince" } } -- override open app
        else
            vim.fn.jobstart({ "google-chrome", uri })
        end
        return overridden(uri, opt)
    end
end)(vim.ui.open)

-- Filetype for [No Name](Buffer) is Markdown
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        if vim.fn.expand("%") == "" and vim.bo.filetype == "" and vim.bo.buftype == "" then
            vim.bo.filetype = "markdown"
        end
    end,
})

-- Lua Snippets
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- Jumping Forward
vim.keymap.set({ "i", "s" }, "<C-L>", function()
    ls.jump(1)
end, { silent = true })
-- Jumping Backward
vim.keymap.set({ "i", "s" }, "<C-J>", function()
    ls.jump(-1)
end, { silent = true })
-- Changing the Active Choice
vim.keymap.set({ "i", "s" }, "<C-E>", function()
    if ls.choice_active() then
        ls.change_choice(1)
    end
end, { silent = true })

vim.api.nvim_create_user_command("FormatDisable", function(args)
    if args.bang then
        -- FormatDisable! will disable formatting just for this buffer
        vim.b.disable_autoformat = true
    else
        vim.g.disable_autoformat = true
    end
end, {
    desc = "Disable autoformat-on-save",
    bang = true,
})

vim.api.nvim_create_user_command("FormatEnable", function()
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
end, {
    desc = "Re-enable autoformat-on-save",
})

ls.add_snippets("all", {
    ls.snippet("trigger", {
        ls.text_node("Wow! Text!"),
    }),
})
