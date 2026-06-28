local M = {}

-- Basic Keymaps
vim.keymap.set('n', '!', ':!')
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear Search Highlights' })

-- Window Navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>')
vim.keymap.set('n', '<C-l>', '<C-w><C-l>')
vim.keymap.set('n', '<C-j>', '<C-w><C-j>')
vim.keymap.set('n', '<C-k>', '<C-w><C-k>')

-- LuaSnip Navigation (Loaded in snippets config if needed, but keeping here for global access)
local has_ls, ls = pcall(require, 'luasnip')
if has_ls then
    vim.keymap.set({ 'i', 's' }, '<C-L>', function() ls.jump(1) end, { silent = true })
    vim.keymap.set({ 'i', 's' }, '<C-J>', function() ls.jump(-1) end, { silent = true })
    vim.keymap.set({ 'i', 's' }, '<C-E>', function()
        if ls.choice_active() then ls.change_choice(1) end
    end, { silent = true })
end

-- Neo-Tree Keymaps
vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Toggle Explorer' })
vim.keymap.set('n', '<leader>tr', ':Neotree toggle current reveal_force_cwd<CR>', { desc = 'Reveal File' })

-- Diffview Keymaps
vim.keymap.set('n', '<leader>gv', '<cmd>DiffviewOpen<cr>', { desc = 'Open Diffview' })
vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', { desc = 'File History (Current File)' })
vim.keymap.set('n', '<leader>gH', '<cmd>DiffviewFileHistory<cr>', { desc = 'File History (Repository)' })
vim.keymap.set('n', '<leader>gx', '<cmd>DiffviewClose<cr>', { desc = 'Close Diffview' })
vim.keymap.set('n', '<leader>gq', ':DiffviewOpen ', { desc = 'Diffview Custom Query' })

-- Telescope Keymaps
vim.keymap.set('n', '<leader>sh', function() require('telescope.builtin').help_tags() end, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', function() require('telescope.builtin').keymaps() end, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', function() require('telescope.builtin').find_files() end, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sg', function() require('telescope.builtin').live_grep() end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sw', function()
    require('telescope.builtin').live_grep({ default_text = vim.fn.expand("<cword>") })
end, { desc = '[S]earch current [W]ord' })
vim.keymap.set('v', '<leader>sw', function()
    vim.cmd('normal! "vy')
    require('telescope.builtin').live_grep({ default_text = vim.fn.getreg('v') })
end, { desc = '[S]earch current selection' })
vim.keymap.set('n', '<leader>sd', function() require('telescope.builtin').diagnostics() end, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', function() require('telescope.builtin').resume() end, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', function() require('telescope.builtin').oldfiles() end, { desc = '[S]earch Recent Files' })
vim.keymap.set('n', '<leader>sds', function() require('telescope.builtin').lsp_document_symbols() end, { desc = '[S]earch [D]ocument [S]ymbols' })
vim.keymap.set('n', '<leader><leader>', function() require('telescope.builtin').buffers() end, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
    require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { previewer = false })
end, { desc = '[/] Fuzzily search in current buffer' })

-- LSP Keymaps (called dynamically when LSP attaches to a buffer)
function M.setup_lsp_keymaps(bufnr)
    local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
    end

    map('<leader>gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    map('<leader>gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    map('<leader>K', vim.lsp.buf.hover, 'Hover Documentation')
end

return M
