local M = {}

function M.setup()
    M.ftplugins()
    M.qf_fix()
    M.cmd_mode()
    M.setup_term_runners()

    -- TODO all other bindings (lsp, ...)?

    -- M.legacy_mappings()

    M.set_mappings_plain()
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

function M.legacy_mappings()
    M.clear_default_mappings()
    local maps = M.get_legacy_maps()
    M.apply_maps(maps)
end

function M.get_legacy_maps()
    -- consider https://colemakmods.github.io/mod-dh/model.html

    local maps = {}

    maps['inverted T arrows'] = {
        nv = {
            { 'n', 'h' }, -- cursor left
            { 'e', 'j' }, -- cursor down
            { 'i', 'l' }, -- cursor right
            { 'u', 'k' }, -- cursor up
        },
    }

    maps['browse'] = {
        nv = {
            { '<c-u>', '1<c-u>' }, -- view and cursor up
            { '<c-e>', '1<c-d>' }, -- view and cursor down
            -- { '<c-u>', 'kzz' }, -- view and cursor up
            -- { '<c-e>', 'jzz' }, -- view and cursor down
            { 'zz', 'zz' }, -- center line in view
            { 'ze', 'zb' }, -- line at top of view
            { 'zu', 'zt' }, -- line at botton of view
            { 'k', '<cmd>set scroll=0<enter><c-u><c-u>' }, -- view and cursor one page up
            { 'h', '<cmd>set scroll=0<enter><c-d><c-d>' }, -- view and cursor one page down
        },
    }

    maps['insert'] = {
        n = {
            { 'sn', 'i' }, -- insert before block cursor
            { 'se', 'o' }, -- insert new line below
            { 'su', 'O' }, -- insert new line above
            { 'si', 'a' }, -- append after block cursor
            { 'so', 'A' }, -- append at end of line
            { 'sm', '^i' }, -- insert at beginning of line
            { 'sl', 'lbi' }, -- insert at beginning of word
            { 'sL', 'lBi' }, -- insert at beginning of Word
            { 'sy', 'hea' }, -- append at end of word
            { 'sY', 'hEa' }, -- append at end of Word
            { 's"', 'gi' }, -- insert where insert mode was last stopped
        },

        v = {
            { 's', 'c' },
        },
    }

    maps['change'] = {
        n = {
            { 'r', 'c' },
            { 'rr', 'r' },
            { '<c-n>', '<<' },
            { '<c-i>', '>>' },
            { 'p<c-n>', "'[V']<" }, -- de-indent last paste
            { 'p<c-i>', "'[V']>" }, -- indent last paste
        },
        v = {
            { 'r', 'c' },
            { '<c-n>', '<gv' },
            { '<c-i>', '>gv' },
        },
    }

    maps['right hand operators'] = {
        o = {
            { 'e', 'iw' }, -- inner word
            { 'E', 'iW' }, -- inner Word
            { 'u', 'aw' }, -- inner word with connecting whitespace
            { 'U', 'aW' }, -- inner Word with connecting whitespace
            { 'l', 'b' }, -- to start of word
            { 'L', 'B' }, -- to start of Word
            { 'y', 'e' }, -- to end of word
            { 'Y', 'E' }, -- to end of Word
            { 'i', '$' }, -- to end of line
            { 'n', 'Vl' }, -- line
            { '(', 'i(' }, -- inner ()
            { ')', 'a(' }, -- outer ()
            { '[', 'i[' }, -- inner []
            { ']', 'a[' }, -- outer []
            { '{', 'i{' }, -- inner {}
            { '}', 'a{' }, -- outer {}
            { "'e", "i'" }, -- inner ''
            { "'u", "a'" }, -- outer ''
            { '"e', 'i"' }, -- inner ""
            { '"u', 'a"' }, -- outer ""
            { '.', 'l' }, -- one character
        },
    }

    maps['moves'] = {
        nv = {
            { 'm', '0^' }, -- start of text in line
            { '<c-m>', '0' }, -- start of line
            { 'o', '$' }, -- end of line
            { '<c-k>', 'gg' }, -- top of document
            { '<c-h>', 'G' }, -- bottom of document
            { 'l', 'b' }, -- word back
            { 'L', 'B' }, -- Word back
            { 'y', 'w' }, -- word forward
            { 'Y', 'W' }, -- Word forward
        },
    }

    maps['marks'] = {
        nv = {
            { '-', "'^^zz" }, -- jump to last insert exit
        },
        n = {
            { '<', '<c-o>' }, -- jump to previous jump location
        },
    }

    maps['undo'] = {
        n = {
            { 'qn', 'u' },
            { 'qi', '<c-r>' },
        },
    }

    maps['copy'] = {
        nv = {
            { 'c', '"zy' },
            { 'x', '"zd' }, -- copy and cut
            { 'ca', '"+y' }, -- put into system clipboard
            { '<c-c>u', [["yy'<"yP]] }, -- duplicate above
            { '<c-c>e', [["yy'>"yp]] }, -- duplicate below
        },
        n = {
            { 'pu', '"zP' },
            { 'pn', '"zP' },
            { 'pe', '"zp' },
            { 'pi', '"zp' },
            { 'pv', "'[[v']]" }, -- select last pasted lines
            -- { 'wa', '[["+Y]]' }, -- put into system clipboard
        },
        v = {
            { 'p', '"zp' }, -- replace
        },
    }

    maps['search'] = {
        n = {
            { 'fi', '/' },
            { 'fn', '?' },
            { 'fy', '*' }, -- search word forward
            { 'fl', '#' }, -- search word backward
            { 'E', 'nzz' },
            { 'U', 'Nzz' },
            { 'f,', '<cmd>nohlsearch<enter>' },
        },
    }

    maps['delete'] = {
        nv = {
            { 'd', 'd' },
            -- { 'D', '"_d' },
        },
    }

    maps['visual'] = {
        nv = {
            { 'v', 'V' }, -- using line select more often
            { 'V', 'v' },
        },
    }

    maps['tabs'] = {
        n = {
            { 'ftn', '<cmd>tabprevious<enter>' }, -- previous tab
            { 'fti', '<cmd>tabnext<enter>' }, -- next tab
            { 'ft,', '<cmd>tabclose<enter>' }, -- close tab
            { 'ft.', '<cmd>tabonly<enter>' }, -- only tab
            { 'fth', 'g<tab>' }, -- last tab
            { 'ftl', '<cmd>tabmove -1<enter>' }, -- move tab left
            { 'fty', '<cmd>tabmove +1<enter>' }, -- move tab right
            { 'zn', '1gt' }, -- tab #1
            { 'ze', '2gt' }, -- tab #2
            { 'zi', '3gt' }, -- tab #3
            { 'zo', '4gt' }, -- tab #4
        },
    }

    maps['splits'] = {
        n = {
            { 'sti', '<cmd>vsplit<enter>' }, -- split right
            { 'stn', '<cmd>set splitright! | vsplit | set splitright!<enter>' }, -- split left
            { 'ste', '<cmd>split<enter>' }, -- split down
            { 'stu', '<cmv>set splitbelow! | split | set splitbelow!<enter>' }, -- split up
            { 'sty', '<cmd>tab split<enter>' }, -- new tab
            { 'stY', '<c-w>T' }, -- explode into new tab
            { 'st,', '<cmd>wincmd c | wincmd=<enter>' }, -- close split
            { 'st.', '<cmd>wincmd o | wincmd=<enter>' }, -- only split, close all other splits
            { 'sth', '<c-w>p' }, -- last split
            { 'zh', '1<c-w>w' }, -- split #1
            { 'z,', '2<c-w>w' }, -- split #2
            { 'z.', '3<c-w>w' }, -- split #3
            { 'z/', '4<c-w>w' }, -- split #4
        },
    }

    maps['quit'] = {
        n = {
            { '<c-x>', '<cmd>xa!<enter>' }, -- save all and exit
            { '<c-q>', '<cmd>qa!<enter>' }, -- exit without saving
        },
        i = {
            { '<c-x>', '<esc><cmd>xa!<enter>' }, -- save all and exit
            { '<c-q>', '<esc><cmd>qa!<enter>' }, -- exit without saving
        },
    }

    return maps
end

function M.apply_maps(maps, opts)
    for _, sections in pairs(maps) do
        for modes, binds in pairs(sections) do
            modes = vim.iter(string.gmatch(modes, '.')):totable()
            for _, bind in ipairs(binds) do
                vim.keymap.set(modes, bind[1], bind[2], opts)
            end
        end
    end
end

-- TODO get this from dk's plugin when it is ready
--
---@alias Mapping {mode: string, lhs: string, rhs: string?, expression: function?, fn: function?, desc: string }

---@return Mapping[] mappings
function M.get_mappings()
    ---@type Mapping[]
    local mappings = {}

    ---@param lhs string
    ---@param modes string
    ---@param desc string
    ---@param rhs string
    local function map(lhs, modes, desc, rhs)
        ---@type string[]
        for _, mode in ipairs(vim.iter(string.gmatch(modes, '.')):totable()) do
            vim.list_extend(mappings, { { mode = mode, lhs = lhs, rhs = rhs, desc = desc } })
        end
    end

    ---@param lhs string
    ---@param modes string
    ---@param desc string
    ---@param fn function
    local function mfn(lhs, modes, desc, fn)
        ---@type string[]
        for _, mode in ipairs(vim.iter(string.gmatch(modes, '.')):totable()) do
            vim.list_extend(mappings, { { mode = mode, lhs = lhs, fn = fn, desc = desc } })
        end
    end

    ---@param lhs string
    ---@param modes string
    ---@param desc string
    ---@param fn function
    local function mex(lhs, modes, desc, fn)
        ---@type string[]
        for _, mode in ipairs(vim.iter(string.gmatch(modes, '.')):totable()) do
            vim.list_extend(mappings, { { mode = mode, lhs = lhs, expression = fn, desc = desc } })
        end
    end

    ---@param lhs string
    ---@param modes string
    ---@param desc string
    local function grp(lhs, modes, desc)
        ---@type string[]
        for _, mode in ipairs(vim.iter(string.gmatch(modes, '.')):totable()) do
            vim.list_extend(mappings, { { mode = mode, lhs = lhs, desc = desc } })
        end
    end

    ---@param m string
    ---@return string command
    local function cmd(m)
        return '<cmd>' .. m .. '<enter>'
    end

    ---@param lhs string
    ---@param modes string
    ---@param desc string
    ---@param rhs string
    local function mxv(lhs, modes, desc, rhs)
        local fn = function()
            if vim.list_contains({ 'V', 'Vs' }, vim.api.nvim_get_mode().mode) then
                return 'v' .. rhs
            else
                return rhs
            end
        end
        mex(lhs, modes, desc, fn)
    end

    -- consider https://colemakmods.github.io/mod-dh/model.html
    -- when it comes to reachability at first

    -- plain cursor moves
    mxv([[n]], 'nv', 'cursor left', 'h')
    map([[e]], 'nv', 'cursor down', 'j')
    mxv([[i]], 'nv', 'cursor right', 'l')
    map([[u]], 'nv', 'cursor up', 'k')

    -- bigger cursor moves
    mxv([[l]], 'nv', 'word back', 'b')
    mxv([[L]], 'nv', 'WORD back', 'B')
    mxv([[y]], 'nv', 'word forward', 'w')
    mxv([[Y]], 'nv', 'WORD forward', 'W')

    mxv([[m]], 'nv', 'view and cursor to start of text in line', '0^')
    mxv([[<c-m>]], 'nv', 'cursor to start of line', '0')
    mxv([[o]], 'nv', 'cursor to end of line', '$')
    map([[<c-k>]], 'nv', 'start of document', 'gg')
    map([[<c-h>]], 'nv', 'end of document', 'G')

    -- browes
    map([[<c-u>]], 'nv', 'view cursor up', '1<c-u>')
    map([[<c-e>]], 'nv', 'view cursor up', '1<c-d>')
    map([[zz]], 'nv', 'center cursor vertically', 'zz')
    map([[ze]], 'nv', 'line at top of view', 'zb')
    map([[zu]], 'nv', 'line at bottom of view', 'zt')
    map([[k]], 'nv', 'view and cursor one page up', '<cmd>set scroll=0<enter><c-u><c-u>')
    map([[h]], 'nv', 'view and cursor one page down', '<cmd>set scroll=0<enter><c-d><c-d>')

    -- contextual cursor moves
    map([[-]], 'nv', 'go to last insert and center', '`^zz')
    map([[<]], 'nv', 'go to last jump location', '<c-o>')

    -- inserts
    grp([[s]], 'n', 'inserts')
    map([[sn]], 'n', 'insert before block cursor', 'i')
    map([[si]], 'n', 'insert after block cursor', 'a')
    map([[sl]], 'n', 'insert at beginning of word', 'lbi')
    map([[sL]], 'n', 'insert at beginning of WORD', 'lBi')
    map([[sy]], 'n', 'insert at end of word', 'hea')
    map([[sY]], 'n', 'insert at end of WORD', 'hEa')
    map([[so]], 'n', 'insert at end of line', 'A')
    map([[sm]], 'n', 'insert at beginning of line text', '^i')

    map([[ssm]], 'n', 'insert at beginning of line', '0i')
    map([[su]], 'n', 'insert new line above', 'O')
    map([[sU]], 'n', 'insert new line at top', 'ggO')
    map([[se]], 'n', 'insert new line below', 'o')
    map([[sE]], 'n', 'insert new line at bottom', 'Go')
    map([[s,]], 'n', 'insert at last insert', 'gi')
    map([[s e]], 'n', 'insert empty line below', 'o<esc>k')
    map([[s u]], 'n', 'insert empty line below', 'O<esc>j')
    map([[s]], 'v', 'insert over visual', 'c')

    -- changes
    map([[r]], 'n', 'replace', 'c')
    map([[rr]], 'n', 'replace single character', 'r')
    map([[j]], 'nv', 'join lines', 'J')
    map([[r]], 'v', 'replace over visual', 'c')
    map([[d]], 'nv', 'delete', 'd')

    -- indentation
    map([[<c-n>]], 'n', 'de-indent current line', '<<')
    map([[<c-i>]], 'n', 'indent current line', '>>')
    map([[p<c-n>]], 'n', 'de-indent last paste', "'[V']<")
    map([[p<c-i>]], 'n', 'indent last paste', "'[V']>")
    map([[<c-n>]], 'v', 'de-indent visual', '<gv')
    map([[<c-i>]], 'v', 'indent visual', '>gv')

    -- operators
    map([[e]], 'o', 'inner word', 'iw')
    map([[u]], 'o', 'inner WORD', 'iW')
    map([[ e]], 'o', 'inner WORD with space', 'aW') -- was U
    map([[l]], 'o', 'to start of word', 'b')
    map([[ l]], 'o', 'to start of WORD', 'B') -- was L
    map([[y]], 'o', 'to end of word', 'e')
    map([[ y]], 'o', 'to end of WORD', 'E') -- was Y

    map([[n]], 'o', 'line', 'Vl')
    map([[ n]], 'o', 'to start of line', '^')
    map([[ i]], 'o', 'to end of line', '$')

    map([[(]], 'o', 'inner ()', 'i(')
    map([[)]], 'o', 'outer ()', 'a(')
    map('[', 'o', 'inner []', 'i[')
    map(']', 'o', 'outer []', 'a[')

    map([[{]], 'o', 'inner {}', 'i{')
    map([[}]], 'o', 'outer {}', 'a{')

    map([[m]], 'o', 'inner ""', 'i"')
    map([[ m]], 'o', 'outer ""', 'a"')
    map([[o]], 'o', "inner ''", "i'")
    map([[ o]], 'o', "outer ''", "a'")

    map([[.]], 'o', 'character', 'l')

    -- visual
    map([[v]], 'n', 'visual lines', 'V')
    map([[v]], 'v', 'exit visual', '<esc>')
    map([[V]], 'n', 'visual', 'v')
    -- map([[av]], 'n', 'visual block', '<c-v>')
    -- map([[dv]], 'n', 'previous visual', 'gv')
    -- map([[av]], 'v', 'other side', 'o')

    -- copy paste
    -- NOTE we use register "z" so that other change operations dont interfere
    -- NOTE we use mark "z" to control cursor location after pastes
    -- TODO the original y and p are not mapped, and we cant use registers on purpose then
    -- TODO is it better more analytic? paste is just paste, and a thing that moves to end or start?
    -- NOTE both x and c keep cursor where it was
    map([[c]], 'nv', 'copy', [[mz"zy`z]])
    map([[x]], 'nv', 'cut', [[mz"zd`z]])
    -- TODO also keep cursor where it was?
    map([[cc]], 'nv', 'copy into system clipboard', '"+y')

    -- NOTE "yY copies into y, '< moves to start/end, "yp pastes
    -- TODO just copied atm
    -- map([[adu]], 'v', 'duplicate above', [["yY'<"yP]])
    -- map([[ade]], 'v', 'duplicate below', [["yY'>"yp]])
    -- map([[ad u]], 'v', 'comment and duplicate above', [["yYgv<Plug>(comment_toggle_linewise_visual)'<"yP]])
    -- map([[ad e]], 'v', 'comment and duplicate below', [["yYgv<Plug>(comment_toggle_linewise_visual)'>"yp]])

    grp([[p]], 'n', 'paste, adapt indentation, and stay')
    map([[pu]], 'n', 'insert above', [[mz"z]P`z]])
    map([[pe]], 'n', 'insert below', [[mz"z]p`z]])
    map([[pn]], 'n', 'insert before', '"zP`]k')
    map([[pi]], 'n', 'insert after', '"zp`[h')
    map([[pan]], 'n', 'insert at beginning of text in line', [[mz0^"zP`z]])
    map([[pai]], 'n', 'insert at end of line', [[mz$"zp`z]])

    grp([[p ]], 'n', 'but keep indentation')
    map([[p u]], 'n', 'insert above', [[mz"zP`z]])
    map([[p e]], 'n', 'insert below', [[mz"zp`z]])
    map([[p n]], 'n', 'insert before', '"zP`]k')
    map([[p i]], 'n', 'insert after', '"zp`[h')

    map([[p]], 'v', 'replace visual with paste', [["zp]])

    -- undos
    map([[<c-w>]], 'n', 'undo', 'u') -- was qn
    map([[<c-f>]], 'n', 'redo', '<c-r>') -- was qi

    -- search
    grp([[f]], 'n', 'search')
    map([[ff]], 'n', 'from the beginning', 'gg0/')
    map([[fu]], 'n', 'backwards', '?')
    map([[fe]], 'n', 'forward', '/')
    map([[fn]], 'n', 'word backwards', '#')
    map([[fi]], 'n', 'word forward', '*')
    map([[f,]], 'n', 'clear search', cmd('nohlsearch'))
    map([[<a-u>]], 'n', 'previous match', 'Nzz')
    map([[<a-e>]], 'n', 'next match', 'nzz')

    -- buffers, windows, and tabs
    grp([[w]], 'n', 'buffers, windows, and tabs')

    map([[wi]], 'n', 'split right', cmd('vsplit'))
    map([[we]], 'n', 'split down', cmd('split'))
    map([[wT]], 'n', 'explode into new tab', '<c-w>T')
    map([[w,]], 'n', 'close window', cmd('wincmd c'))
    map([[w.]], 'n', 'only window', cmd('wincmd o'))
    map([[w1]], 'n', 'split #1', '1<c-w>w')
    map([[w2]], 'n', 'split #2', '2<c-w>w')
    map([[w3]], 'n', 'split #3', '3<c-w>w')

    map([[wt]], 'n', 'new tab', cmd('tab split'))
    map([[wc]], 'n', 'close tab', cmd('tabclose'))
    map([[w n]], 'n', 'previous tab', cmd('tabprevious'))
    map([[w i]], 'n', 'next tab', cmd('tabnext'))

    grp([[,]], 'n', 'misc')
    map([[,,]], 'nv', 'which key', require('which-key').show)

    -- and insert mode?
    map([[,x]], 'n', '(try) save and exit (anyway)', '<cmd>silent! wa<enter><cmd>qa!<enter>')
    map([[,q]], 'n', 'exit (anyway)', '<cmd>qa!<enter>')

    return mappings
end

function M.set_mappings_plain()
    M.clear_default_mappings()
    local mappings = M.get_mappings()
    for _, map in ipairs(mappings) do
        if map.rhs then
            vim.keymap.set(map.mode, map.lhs, map.rhs, { desc = map.desc })
        elseif map.expression then
            vim.keymap.set(map.mode, map.lhs, map.expression, { desc = map.desc, expr = true })
        end
    end
end

return M
