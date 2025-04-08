local M = {}

function M.setup()
    M.ftplugins()
    M.qf_fix()
    M.cmd_mode()
    M.setup_term_runners()

    require('mappings').apply()
end

function M.ftplugins()
    vim.cmd([[
        autocmd FileType python imap <buffer> <F11>b breakpoint()
        autocmd FileType python imap <buffer> <F11>a # TODO
        autocmd FileType rust imap <buffer> <F11>a todo!()
    ]])
end

function M.qf_fix()
    local map = vim.keymap.set

    -- FIXME not sure why I need to rebind this?
    map('n', '<CR>', function()
        if vim.o.buftype == 'quickfix' then
            return ':.cc<CR>'
        else
            -- TODO maybe bind something interesting here?
            return '<CR>'
        end
    end, { expr = true, replace_keycodes = true })
end

function M.cmd_mode()
    local map = vim.keymap.set

    vim.api.nvim_create_autocmd('CmdwinEnter', {
        callback = function()
            map({ 'n', 'v' }, '<esc>', '<c-w>c', { buffer = true })
        end,
    })

    map({ 'n', 'v' }, ':', function()
        local old = vim.opt.splitkeep
        vim.opt.splitkeep = 'topline'
        vim.api.nvim_create_autocmd('CmdwinLeave', {
            callback = function()
                vim.opt.splitkeep = old -- NOTE to prevent the main view from jumping
                return true
            end,
            once = true,
        })
        return 'q:i'
    end, { expr = true, desc = 'super command line in insert mode' })

    map({ 'n', 'v' }, ';', function()
        local old = vim.opt.splitkeep
        vim.opt.splitkeep = 'topline'
        vim.api.nvim_create_autocmd('CmdwinLeave', {
            callback = function()
                vim.opt.splitkeep = old -- NOTE to prevent the main view from jumping
                return true
            end,
            once = true,
        })
        return 'q:k'
    end, { expr = true, desc = 'super command line in normal mode' })
end

function M.setup_term_runners()
    local map = vim.api.nvim_set_keymap

    map(
        'n',
        '<leader>g',
        ":vsplit | term zsh -c '$(pwd)/.tmux/g'<CR>",
        { noremap = true, silent = true, desc = 'run .tmux/g' }
    )

    -- those are very nn specific, how could we add those only for nn envs?
    map(
        'n',
        '<leader>t',
        ":vsplit | term zsh -c 'xj t -1'<CR>",
        { noremap = true, silent = true, desc = 'xj tail last' }
    )
    map('n', '<leader>s', ":vsplit | term zsh -c 'xj ls'<CR>", { noremap = true, silent = true, desc = 'xj ls' })

    -- make sure we always scroll to the last line in term buffers
    vim.cmd([[
      augroup TermScroll
        autocmd!
        autocmd BufWinEnter,WinEnter term://* startinsert | autocmd BufWritePost <buffer> normal! G
        autocmd TermOpen * startinsert
      augroup END
    ]])

    -- exit insert mode in terminal with an easier shortcut
    -- or use c-,
    vim.keymap.set('t', '<ESC>', [[<C-\><C-n>]])
end

function M.clear_default_mappings()
    -- see :help default_mappings and other places

    -- disable some original mappings
    for _, k in pairs({ 'q', 'a', 'Q' }) do
        vim.keymap.set('', k, '<nop>')
    end

    vim.keymap.del('n', '<c-w>d')
    vim.keymap.del('n', '<c-w><c-d>')
end

return M
