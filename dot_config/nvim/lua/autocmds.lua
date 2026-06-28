-- Open URI with custom logic
vim.ui.open = (function(overridden)
    return function(uri, opt)
        if vim.endswith(uri, '.png') then
            vim.cmd('edit ' .. uri)
            return
        elseif vim.endswith(uri, '.pdf') then
            opt = { cmd = { 'evince' } }
        else
            vim.fn.jobstart { 'google-chrome', uri }
        end
        return overridden(uri, opt)
    end
end)(vim.ui.open)

-- Default filetype to Markdown for empty buffers
vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = vim.api.nvim_create_augroup('filetype_detection', { clear = true }),
    callback = function()
        if vim.bo.filetype == '' or vim.bo.filetype == 'markdown' then
            vim.cmd 'filetype detect'
        end
    end,
})

-- Formatting Commands
vim.api.nvim_create_user_command('FormatDisable', function(args)
    if args.bang then
        vim.b.disable_autoformat = true
    else
        vim.g.disable_autoformat = true
    end
end, { desc = 'Disable autoformat-on-save', bang = true })

vim.api.nvim_create_user_command('FormatEnable', function()
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
end, { desc = 'Re-enable autoformat-on-save' })
