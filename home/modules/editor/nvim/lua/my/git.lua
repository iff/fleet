local M = {}

function M.setup()
    vim.g['fugitive_no_maps'] = 1

    -- FIXME want gg
    vim.keymap.set('n', 'gn', ':tab Git<enter>')

    vim.api.nvim_create_autocmd('User', {
        pattern = { 'FugitiveIndex', 'FugitiveObject' },
        callback = M.status_config,
    })

    vim.api.nvim_create_autocmd({ 'FileType' }, {
        pattern = { 'gitcommit' },
        callback = M.gitcommit_config,
    })

    require('gitsigns').setup({
        on_attach = function(bufnr)
            local gitsigns = require('gitsigns')

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            map('n', 'ge', function()
                if vim.wo.diff then
                    vim.cmd.normal({ ']c', bang = true })
                else
                    gitsigns.nav_hunk('next')
                end
            end)

            map('n', 'gu', function()
                if vim.wo.diff then
                    vim.cmd.normal({ '[c', bang = true })
                else
                    gitsigns.nav_hunk('prev')
                end
            end)
        end,
    })
end

local function map(m, a, b, desc)
    vim.keymap.set(m, a, b, { buffer = true, nowait = true, desc = desc })
end

function M.status_config()
    map('n', 'qq', '<Plug>fugitive:U', 'unstage everything')
    map({ 'n', 'v' }, 't', '<Plug>fugitive:-', 'stage or unstage')

    map({ 'n', 'v' }, 'v', 'V', 'line visual mode')

    -- TODO move to k (up) and (h) up
    map('v', 'u', 'k', 'move up in visual mode')
    map('v', 'e', 'j', 'move down in visual mode')

    map('n', 'e', '<Plug>fugitive:)', 'next file, hunk, or revision')
    map('n', 'u', '<Plug>fugitive:(', 'previous file, hunk, or revision')
    map('n', 'n', '<Plug>fugitive:<', 'fold inline diff')
    map('n', 'i', '<Plug>fugitive:>', 'unfold inline diff')

    map('n', 'd', '<Plug>fugitive:O<cmd>Gvdiff<enter>', 'diff in tab')
    map('n', 'g', '<Plug>fugitive:O', 'open file')

    map('n', 'cc', '<cmd>Git commit --verbos<enter>')
    map('n', 'cn', '<cmd>Git commit --no-verify --verbos<enter>')
    map('n', 'ce', '<cmd>Git commit --amend --quiet<enter>')

    map('n', 'ru', '<cmd>Git push<enter>')
    map('n', 'rr', '<cmd>tab Git<enter>', 'refresh status')
end

function M.gitcommit_config()
    vim.bo.textwidth = 0
    local n = 'n'
    map(n, '<esc>', '<cmd>x<enter>')
    map(n, '<c-o>', '<cmd>x<enter>')
    vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
        once = true,
        buffer = 0,
        callback = function()
            vim.cmd.startinsert()
        end,
    })
end

return M
