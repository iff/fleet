local M = {}

function M.setup()
    local telescope = require('telescope')
    local actions = require('telescope.actions')

    require('telescope.pickers.layout_strategies').laforge = function(self, max_columns, max_lines, layout_config)
        -- local resolve = require("telescope.config.resolve")
        -- local p_window = require("telescope.pickers.window")
        -- local initial_options = p_window.get_initial_window_options(self)
        -- local results = initial_options.results
        -- local prompt = initial_options.prompt
        -- local preview = initial_options.preview
        local half = vim.fn.round(max_lines / 2)
        local pad = 3
        return {
            preview = {
                border = true,
                borderchars = { '─', '│', '═', '│', '┌', '┐', '╛', '╘' },
                col = 2,
                enter = false,
                height = half - pad - 3,
                line = 2,
                width = max_columns - 2,
            },
            prompt = {
                border = true,
                borderchars = { '═', '│', '─', '│', '╒', '╕', '│', '│' },
                col = 2,
                enter = true,
                height = 1,
                line = half + pad + 2,
                title = self.prompt_title,
                width = max_columns - 2,
            },
            results = {
                border = { 0, 1, 1, 1 },
                borderchars = { '═', '│', '─', '│', '╒', '╕', '┘', '└' },
                col = 2,
                enter = false,
                height = max_lines - half - pad - 4,
                line = half + pad + 4,
                width = max_columns - 2,
            },
        }
    end

    -- local defaults = require('telescope.themes').get_ivy({ layout_config = { height = 0.4 } })
    local defaults = {
        -- TODO how to make the layout strat and the rest go together? many things are not independent, like sorting_strategy
        layout_strategy = 'laforge',
        sorting_strategy = 'ascending',
        prompt_prefix = '󰄾 ',
        entry_prefix = '   ',
        selection_caret = ' 󰧚 ',
    }
    defaults.scroll_strategy = 'limit'
    defaults.mappings = {
        i = {
            ['<c-j>'] = actions.move_selection_next,
            ['<c-k>'] = actions.move_selection_previous,
            ['<enter>'] = actions.select_default,
            ['<c-v>'] = actions.select_vertical,
            ['<c-s>'] = actions.select_horizontal,
            ['<c-t>'] = actions.select_tab,
            ['<tab>'] = actions.toggle_selection + actions.move_selection_next,
            ['<s-tab>'] = actions.toggle_all,
            ['<c-f>'] = function(prompt_bufnr)
                telescope.extensions.hop._hop(prompt_bufnr, { callback = actions.select_default })
            end,
        },
        n = {
            ['q'] = actions.close,
            ['y'] = 'move_selection_next',
            ['l'] = 'move_selection_previous',
            ['<enter>'] = actions.select_default,
            ['n'] = actions.select_vertical,
            ['u'] = actions.select_horizontal,
            ['t'] = actions.select_tab,
            ['<tab>'] = actions.toggle_selection + actions.move_selection_next,
            ['<s-tab>'] = actions.toggle_all,
        },
    }
    defaults.path_display = { 'truncate' }

    telescope.setup({
        defaults = defaults,
        extensions = {
            fzf = {},
            -- hop = {},
            ['ui-select'] = {},
        },
    })
    telescope.load_extension('fzf')
    -- telescope.load_extension('hop')
    telescope.load_extension('ui-select')

    -- M.mappings()

    -- new bindings for lavish layouts
    M.set_ops()
end

function M.mappings()
    local map = vim.keymap.set
    local bi = require('telescope.builtin')

    map('', 'gg', ':Telescope git_files<cr>', { desc = 'find git files' })
    map('n', 'ge', bi.lsp_document_symbols, { desc = 'document symbols' })
    map('n', 'gi', bi.lsp_dynamic_workspace_symbols, { desc = 'workspace symbols' })
    map('n', 'gf', bi.find_files, { desc = 'find files' })

    -- map('n', 'gr', bi.live_grep, { desc = 'live grep' })
    map('n', 'gn', bi.buffers, { desc = 'buffers' })
    map('n', 'go', bi.help_tags, { desc = 'help tags' })
    map('n', 'gm', function()
        bi.man_pages({ sections = { 'ALL' } })
    end, { desc = 'man pages' })
    map('n', 'gt', bi.commands, { desc = 'vim commands' })
    map('n', 'gc', M.git_diff_files, {})

    map('n', 'gu', function()
        bi.diagnostics({ initial_mode = 'normal', bufnr = 0, severity_limit = vim.diagnostic.severity.ERROR })
    end, { desc = 'lsp diagnostic buffer messages' })
    map('n', 'gU', function()
        bi.diagnostics({ initial_mode = 'normal', bufnr = 0, severity_limit = vim.diagnostic.severity.WARN })
    end, { desc = 'lsp diagnostic buffer messages' })
    map('n', 'g,', function()
        bi.diagnostics({
            initial_mode = 'normal',
            bufnr = nil,
            no_unlisted = false,
            severity_limit = vim.diagnostic.severity.ERROR,
        })
    end, { desc = 'lsp diagnostic all messages' })
end

function M.git_diff_files(opts)
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local list = vim.fn.systemlist('git diff --name-only master 2>/dev/null | git diff --name-only main')

    pickers
        .new(opts, {
            prompt_title = 'git diff to main/master',
            finder = finders.new_table({ results = list }),
            sorter = conf.generic_sorter(opts),
        })
        :find()
end

local function at_top()
    vim.cmd([[normal! zt]])
end

local function jump_find_files(entry)
    -- { "config/lua/dk/mappings.lua",
    --   index = 4,
    --   <metatable> = {
    --     __index = <function 1>,
    --     cwd = "/home/dkuettel/config/i/nvim",
    --     display = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry[1]))
end

local function jump_help_tags(entry)
    -- {
    --   cmd = "/*:map-nowait*",
    --   display = ":map-nowait",
    --   filename = "/nix/store/g6k5yzipk2ianqxj1d3xj1ab19kc31lf-neovim-unwrapped-0.10.3/share/nvim/runtime/doc/map.txt",
    --   index = 2300,
    --   ordinal = ":map-nowait",
    --   <metatable> = {
    --     __index = <function 1>
    --   }
    -- }
    -- NOTE vim's help handling is a bit bumpy
    -- the trick is to make a new buffer of type "help" so that :help decides to use it
    -- this way we can control where it ends up predictably
    vim.cmd.enew() -- NOTE doesnt seem to leave unused unnamed buffers around, even thou I expected it to
    vim.bo.buftype = 'help' -- NOTE documentation says dont do this, but no problem so far
    vim.cmd.help(entry.display) -- TODO might have to escape here?
end

local function jump_lsp_symbol(entry)
    -- lsp symbol
    -- {
    --   col = 12,
    --   display = <function 1>,
    --   filename = "/home/dkuettel/config/i/nvim/config/lua/dk/mappings.lua",
    --   index = 583,
    --   lnum = 286,
    --   ordinal = "M.for_visual Function",
    --   symbol_name = "M.for_visual",
    --   symbol_type = "Function",
    --   <metatable> = {
    --     __index = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
    vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
    at_top()
end

local function jump_live_grep(entry)
    -- { "dev/run-tmux-bound-gg:5:12:# tmux new-window iloop run --until -- nix run '.?submodules=1#default' -- config/lua/dk/nvim.lua",
    --   col = 12,
    --   filename = "dev/run-tmux-bound-gg",
    --   index = 1,
    --   lnum = 5,
    --   text = "# tmux new-window iloop run --until -- nix run '.?submodules=1#default' -- config/lua/dk/nvim.lua",
    --   <metatable> = {
    --     __index = <function 1>,
    --     cwd = "/home/dkuettel/config/i/nvim",
    --     display = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
    vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
    at_top()
end

local function jump_buffers(entry)
    -- {
    --   bufnr = 1,
    --   display = <function 1>,
    --   filename = "config/lua/dk/nvim.lua",
    --   index = 1,
    --   indicator = "%a  ",
    --   lnum = 1,
    --   ordinal = "1 : config/lua/dk/nvim.lua",
    --   path = "/home/dkuettel/config/i/nvim/config/lua/dk/nvim.lua",
    --   <metatable> = {
    --     __index = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
end

local function jump_diagnostics(entry)
    -- {
    --   col = 1,
    --   display = <function 1>,
    --   filename = "/home/dkuettel/config/i/nvim/config/lua/dk/nvim.lua",
    --   index = 1,
    --   lnum = 3,
    --   ordinal = " Unexpected <exp> .",
    --   text = "Unexpected <exp> .",
    --   type = "ERROR",
    --   <metatable> = {
    --     __index = <function 2>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
    vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
    at_top()
end

local function jump_man(entry)
    -- {
    --   description = "search for files in a directory hierarchy",
    --   display = <function 1>,
    --   index = 867,
    --   keyword = "find (1)",
    --   ordinal = "find",
    --   section = "1",
    --   value = "find",
    --   <metatable> = {
    --     __index = <function 2>
    --   }
    -- }
    -- TODO probably needs escaping?
    vim.cmd.edit('man://' .. entry.value .. '(' .. entry.section .. ')')
end

local function jump_marks(entry)
    -- {
    --   col = 39,
    --   display = 'a      9   38     -- vim.cmd.colorscheme("retrobox")',
    --   filename = "/home/dkuettel/config/i/nvim/config/lua/dk/nvim.lua",
    --   index = 1,
    --   lnum = 9,
    --   ordinal = 'a      9   38     -- vim.cmd.colorscheme("retrobox")',
    --   <metatable> = {
    --     __index = <function 1>
    --   }
    -- }
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
    vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
    at_top()
end

---@param picker
---@param jump?
---@param opts?
---@return fun(make: fun()) op
local function as_op(picker, jump, opts)
    local actions = require('telescope.actions')
    local state = require('telescope.actions.state')
    ---@param make fun()
    return function(make)
        local callback = {
            -- prompt_title = "buffer symbol", -- TODO should it come from outside? that its in-place, or a split?
            attach_mappings = function(prompt_bufnr, map)
                local function enter(prompt_bufnr)
                    local entry = state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if not entry then
                        return
                    end
                    make()
                    if jump then
                        jump(entry)
                    else
                        vim.print(entry)
                    end
                end
                map('i', '<enter>', enter)
                map('n', '<enter>', enter)
                return true
            end,
        }
        local merged = vim.tbl_deep_extend('force', opts or {}, callback)
        picker(merged)
    end
end

function M.set_ops()
    local builtin = require('telescope.builtin')

    -- NOTE jumping to a selected entry is very messy sadly
    -- telescope seems to offer no way to inject behavior there
    -- and the code itself is also strange
    -- see require("telescope.actions.set").edit(prompt_bufnr, "edit")
    -- looks to try to be generic even though entry makers are not necessarily like that
    -- would it not be better if an entry had carried the means of "going there"?
    -- TODO maybe there is a way to monkey patch? right now i duplicate some behavior
    -- in the jump_* functions
    -- because there are still subtleties when it comes to the jump stack?

    -- TODO builtin.resume could be interesting when jumping around with diagnostics!
    local ops = require('yi/mappings').ops

    ops.pick_file = as_op(builtin.find_files, jump_find_files)
    ops.pick_grep = as_op(builtin.live_grep, jump_live_grep)
    ops.pick_buffer = as_op(builtin.buffers, jump_buffers)
    ops.pick_help = as_op(builtin.help_tags, jump_help_tags)
    ops.pick_man = as_op(builtin.man_pages, jump_man)
    ops.pick_man_all = as_op(builtin.man_pages, jump_man, { sections = { 'ALL' } })
    ops.pick_mark = as_op(builtin.marks, jump_marks, { initial_mode = 'normal' })

    -- TODO for python we want ptags, how to overwrite this?
    ops.pick_buffer_symbol = as_op(builtin.lsp_document_symbols, jump_lsp_symbol)
    ops.pick_project_symbol = as_op(builtin.lsp_dynamic_workspace_symbols, jump_lsp_symbol)

    -- TODO needed to set severity because of a bug, otherwise shows nothing, still true?
    -- see https://github.com/nvim-telescope/telescope.nvim/issues/2661
    local buffer_diagnostics = { initial_mode = 'normal', bufnr = 0, severity_limit = vim.diagnostic.severity.ERROR }
    local buffer_diagnostics_all = { initial_mode = 'normal', bufnr = 0, severity_limit = vim.diagnostic.severity.HINT }
    local project_diagnostics =
        { initial_mode = 'normal', bufnr = nil, no_unlisted = false, severity_limit = vim.diagnostic.severity.ERROR }
    local project_diagnostics_all =
        { initial_mode = 'normal', bufnr = nil, no_unlisted = false, severity_limit = vim.diagnostic.severity.HINT }
    ops.pick_buffer_diagnostics = as_op(builtin.diagnostics, jump_diagnostics, buffer_diagnostics)
    ops.pick_buffer_diagnostics_all = as_op(builtin.diagnostics, jump_diagnostics, buffer_diagnostics_all)
    ops.pick_project_diagnostics = as_op(builtin.diagnostics, jump_diagnostics, project_diagnostics)
    ops.pick_project_diagnostics_all = as_op(builtin.diagnostics, jump_diagnostics, project_diagnostics_all)
end

return M
