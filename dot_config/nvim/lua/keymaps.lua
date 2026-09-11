local M = {}

-- Basic Keymaps
vim.keymap.set("n", "!", ":!")
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear Search Highlights" })

-- Window Navigation
vim.keymap.set("n", "<C-h>", "<C-w><C-h>")
vim.keymap.set("n", "<C-l>", "<C-w><C-l>")
vim.keymap.set("n", "<C-j>", "<C-w><C-j>")
vim.keymap.set("n", "<C-k>", "<C-w><C-k>")

-- LuaSnip Navigation
vim.keymap.set({ "i", "s" }, "<C-L>", function()
    require("luasnip").jump(1)
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-J>", function()
    require("luasnip").jump(-1)
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-E>", function()
    local ls = require("luasnip")
    if ls.choice_active() then
        ls.change_choice(1)
    end
end, { silent = true })

-- Neo-Tree Keymaps
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle Explorer" })
vim.keymap.set("n", "<leader>rf", ":Neotree toggle current reveal_force_cwd<CR>", { desc = "Reveal File" })

-- Diffview Keymaps
vim.keymap.set("n", "<leader>gv", "<cmd>DiffviewOpen<cr>", { desc = "Open Diffview" })
vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File History (Current File)" })
vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "File History (Repository)" })
vim.keymap.set("n", "<leader>gx", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" })
vim.keymap.set("n", "<leader>gq", ":DiffviewOpen ", { desc = "Diffview Custom Query" })

-- Telescope Keymaps
vim.keymap.set("n", "<leader>sh", function()
    require("telescope.builtin").help_tags()
end, { desc = "Search Help" })
vim.keymap.set("n", "<leader>sk", function()
    require("telescope.builtin").keymaps()
end, { desc = "Search Keymaps" })
vim.keymap.set("n", "<leader>sf", function()
    require("telescope.builtin").find_files()
end, { desc = "Search Files" })
vim.keymap.set("n", "<leader>sg", function()
    require("telescope.builtin").live_grep()
end, { desc = "Search by Grep" })
vim.keymap.set("n", "<leader>sw", function()
    require("telescope.builtin").live_grep({ default_text = vim.fn.expand("<cword>") })
end, { desc = "Search current Word" })
vim.keymap.set("v", "<leader>sw", function()
    vim.cmd('normal! "vy')
    require("telescope.builtin").live_grep({ default_text = vim.fn.getreg("v") })
end, { desc = "Search current selection" })
vim.keymap.set("n", "<leader>sd", function()
    require("telescope.builtin").diagnostics()
end, { desc = "Search Diagnostics" })
vim.keymap.set("n", "<leader>sr", function()
    require("telescope.builtin").resume()
end, { desc = "Search Resume" })
vim.keymap.set("n", "<leader>s.", function()
    require("telescope.builtin").oldfiles()
end, { desc = "Search Recent Files" })
vim.keymap.set("n", "<leader>ss", function()
    require("telescope.builtin").lsp_document_symbols()
end, { desc = "Search Symbols" })
vim.keymap.set("n", "<leader><leader>", function()
    require("telescope.builtin").buffers()
end, { desc = "Find existing buffers" })
vim.keymap.set("n", "<leader>/", function()
    require("telescope.builtin").current_buffer_fuzzy_find(
        require("telescope.themes").get_dropdown({ previewer = false })
    )
end, { desc = "[/] Fuzzily search in current buffer" })

-- Gitsigns Keymaps (called dynamically when gitsigns attaches to a buffer)
function M.setup_gitsigns_keymaps(bufnr)
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
end

-- LSP Keymaps (called dynamically when LSP attaches to a buffer)
function M.setup_lsp_keymaps(bufnr)
    local map = function(keys, func, desc)
        vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
    end

    map("<leader>gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
    map("<leader>gi", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
    map("<leader>gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
    map("<leader>K", vim.lsp.buf.hover, "Hover Documentation")
end

return M
