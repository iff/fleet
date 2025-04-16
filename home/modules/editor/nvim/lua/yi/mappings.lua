local M = {}

---@type "default" | "search" | "diagnostic"
M.mode = "default"

local n, i, v, o, nv, ni = "n", "i", "v", "o", "nv", "ni"

-- consider https://colemakmods.github.io/mod-dh/model.html when it comes to reachability

---@alias Map {
---   lhs: string,
---   mode: "n" | "v" | "nv" | "o",
---   desc: string,
---   rhs: string?,
---   expr: function?,
---   fn: function?,
--- }

---@param maps? Map[] mappings (defaults to M.get())
function M.apply(maps)
    maps = maps or M.get()
    M.clear()
    M.apply_plain(maps)
    -- M.apply_which_key(maps)
    -- M.apply_legendary(maps)
end

---@return Map[] mappings
function M.get()
    ---@type Map[]
    local maps = {}
    vim.list_extend(maps, M.for_moves())
    vim.list_extend(maps, M.for_inserts())
    vim.list_extend(maps, M.for_edit())
    vim.list_extend(maps, M.for_changes())
    vim.list_extend(maps, M.for_indentation())
    vim.list_extend(maps, M.for_operators())
    vim.list_extend(maps, M.for_visual())
    vim.list_extend(maps, M.for_copy_paste())
    vim.list_extend(maps, M.for_search())
    vim.list_extend(maps, M.for_windows())
    vim.list_extend(maps, M.for_jumps())
    vim.list_extend(maps, M.for_comma())
    vim.list_extend(maps, M.for_undos())
    vim.list_extend(maps, M.for_completion())
    return maps
end

--- apply using nvim api
---@param maps Map[] mappings to apply
function M.apply_plain(maps)
    for _, map in ipairs(maps) do
        for _, mode in ipairs(vim.iter(string.gmatch(map.mode, ".")):totable()) do
            if map.rhs then
                vim.keymap.set(mode, map.lhs, map.rhs, { desc = map.desc })
            elseif map.expr then
                vim.keymap.set(mode, map.lhs, map.expr, { desc = map.desc, expr = true })
            elseif map.fn then
                vim.keymap.set(mode, map.lhs, map.fn, { desc = map.desc })
            end
        end
    end
end

--- clear mappings
function M.clear()
    -- see :help default_mappings and other places
    -- currently just removing what i bumped into
    -- there was a way to clear all, including built-in I think

    -- NOTE difference between deleting a mapping and unsetting a default

    local del = vim.keymap.del
    del(n, "<c-w>d")
    del(n, "<c-w><c-d>")
    -- TODO damn ... because this happens after us? comes from matchit, a pack, but it's before the config path
    -- but we run init directly, so that happens before somehow?
    -- its a mess, plugins happen after my init ... so how can i undo things from them?
    -- how can i make my init run at the very end then?
    -- del(o, "[%") -- NOTE comes from "matchit"
    vim.cmd([[let loaded_matchit = 1]]) -- TODO as a hack now, still dont know how to not get overwritten by plugins

    local function uns(mode, lhs)
        vim.keymap.set(mode, lhs, "<nop>")
    end
    uns(n, "o")
    uns(n, "q")
end

--- apply to which key (not setting any maps)
---@param maps Map[] mappings to apply
function M.apply_which_key(maps)
    local groups = {}
    for _, map in ipairs(maps) do
        for _, mode in ipairs(vim.iter(string.gmatch(map.mode, ".")):totable()) do
            if map.rhs or map.expr or map.fn then
            else
                -- TODO i still dont seem to see anything after typing 'w'
                table.insert(groups, { map.lhs, mode = mode, group = map.desc })
            end
        end
    end
    -- see https://github.com/folke/which-key.nvim
    require("which-key").setup {
        spec = groups,
        plugins = {
            marks = false,
            registers = false,
            spelling = false,
            presets = {
                operators = false,
                motions = false,
                text_objects = false,
                windows = false,
                nav = false,
                z = false,
                g = false,
            },
        },
    }
    -- TODO ':checkhealth which-key' will show if you have duplicates and/or overlaps; does it work when not set here?
end

--- apply to legendary (not setting any maps)
---@param maps Map[] mappings to apply
function M.apply_legendary(maps)
    local spec = {}
    for _, map in ipairs(maps) do
        for _, mode in ipairs(vim.iter(string.gmatch(map.mode, ".")):totable()) do
            if map.rhs or map.expr or map.fn then
                table.insert(spec, { map.lhs, mode = mode, desc = map.desc })
            end
        end
    end
    -- TODO didnt show me n, showed me a bunch of built-ins, including the old n
    -- require("legendary").setup({ extensions = { which_key = { auto_register = true, do_binding = false } } })
    -- see https://github.com/mrjones2014/legendary.nvim
    require("legendary").setup {
        include_builtin = false,
        keymaps = spec,
    }
end

---@param args {1: string, 2: string, 3: string, rhs: string?, expr: string?, fn: function?} map specification
---@return Map
local function map(args)
    return {
        lhs = args[1],
        mode = args[2],
        desc = args[3],
        rhs = args.rhs,
        expr = args.expr,
        fn = args.fn,
    }
end

function M.for_moves()
    --- switch to character visual when in line visual
    local function vv(rhs)
        local expr = function()
            if vim.list_contains({ "V", "Vs" }, vim.api.nvim_get_mode().mode) then
                return "v" .. rhs
            else
                return rhs
            end
        end
        return expr
    end
    return {
        -- plain
        map { [[n]], nv, "cursor left", expr = vv("h") },
        map { [[e]], nv, "cursor down", rhs = "j" },
        map { [[i]], nv, "cursor right", expr = vv("l") },
        map { [[u]], nv, "cursor up", rhs = "k" },
        map { [[<up>]], nv, "view and cursor up", rhs = "1<c-u>" },
        map { [[<down>]], nv, "view and cursor down", rhs = "1<c-d>" },
        -- words
        map { [[l]], nv, "previous word start", expr = vv("b") },
        map { [[ l]], nv, "previous word end", expr = vv("ge") },
        map { [[<c-l>]], nv, "previous WORD start", expr = vv("B") },
        map { [[y]], nv, "next word start", expr = vv("w") },
        map { [[ y]], nv, "next word end", expr = vv("e") },
        map { [[<c-y>]], nv, "next WORD end", expr = vv("W") },
        -- bigger
        map { [[ n]], nv, "view and cursor to start of text in line", expr = vv("0^") }, -- [[m]]
        map { [[aan]], nv, "cursor to start of line", expr = vv("0") }, -- [[am]]
        map { [[ i]], nv, "cursor to end of line", expr = vv("$") }, -- [[o]]
        map { [[zz]], nv, "center cursor vertically", rhs = "zz" },
        -- TODO this seems to not keep the cursor in the same column? virtual edit is on? yes it is
        -- and it acts very strange, cursor appears in wrong column, but then when you neiu, it jumps to the right place
        map { [[k]], nv, "view and cursor one page up", rhs = "<cmd>set scroll=0<enter><c-u><c-u>" },
        map { [[ k]], nv, "view and cursor half page up", rhs = "<cmd>set scroll=0<enter><c-u>" },
        map { [[h]], nv, "view and cursor one page down", rhs = "<cmd>set scroll=0<enter><c-d><c-d>" },
        map { [[ h]], nv, "view and cursor half page down", rhs = "<cmd>set scroll=0<enter><c-d>" },
        map { [[ u]], nv, "start of document", rhs = "gg" },
        map { [[ e]], nv, "end of document", rhs = "G" },

        -- contextual
        map { [[ ,]], nv, "go to last insert and center", rhs = "`^zz" },
        map { [[<]], nv, "go to previous jump location", rhs = "<c-o>" },
        map { [[<backspace>]], nv, "jump back (tag stack)", rhs = "<ctrl-t>" },
    }
end

function M.for_inserts()
    return {
        map { [[s]], n, "inserts" },
        map { [[sn]], n, "insert before block cursor", rhs = "i" },
        map { [[si]], n, "insert after block cursor", rhs = "a" },
        map { [[sl]], n, "insert at beginning of word", rhs = "lbi" },
        map { [[ssl]], n, "insert at beginning of WORD", rhs = "lBi" },
        map { [[sy]], n, "insert at end of word", rhs = "hea" },
        map { [[ssy]], n, "insert at end of WORD", rhs = "hEa" },
        map { [[so]], n, "insert at end of line", rhs = "A" },
        map { [[sm]], n, "insert at beginning of line text", rhs = "^i" },
        -- map { [[ssm]], n, "insert at beginning of line", rhs = "0i" },
        map { [[su]], n, "insert new line above", rhs = "O" },
        map { [[ssu]], n, "insert new line at top", rhs = "ggO" },
        map { [[se]], n, "insert new line below", rhs = "o" },
        map { [[sse]], n, "insert new line at bottom", rhs = "Go" },
        map { [[s,]], n, "insert at last insert", rhs = "gi" },
        -- TODO map([[s ]], "n", "insert left of hop", todo)
        map { [[s e]], n, "insert empty line below", rhs = "o<esc>k" },
        map { [[s u]], n, "insert empty line below", rhs = "O<esc>j" },
        map { [[s]], v, "insert over visual", rhs = "c" },
    }
end

function M.for_edit()
    return {
        -- TODO almost not worth it?
        map { [[<c-u>]], i, "new line above", rhs = "<esc>O" },
        map { [[<c-e>]], i, "new line below", rhs = "<esc>o" },
    }
end

function M.for_changes()
    return {
        map { [[r]], nv, "change", rhs = "c" },
        map { [[rr]], n, "replace single character", rhs = "r" },
        map { [[J]], nv, "join lines", rhs = "J" },
        map { [[d]], nv, "delete", rhs = "d" },
        map { [[<delete>]], n, "delete under cursor", rhs = "x" },
        map { [[.]], n, "repeat", rhs = "." },
    }
end

function M.for_indentation()
    return {
        -- TODO shift makes more sense? and shift up down too?
        -- TODO does repeat maken sense here anyway? if we repeat with . after?
        -- map([[<c-n>]], "n", "de-indent current line", "<<")
        -- map([[<c-i>]], "n", "indent current line", ">>")
        -- map([[p<c-n>]], "n", "de-indent last paste", "'[V']<")
        -- map([[p<c-i>]], "n", "indent last paste", "'[V']>")
        -- map([[<c-n>]], "v", "de-indent visual", "<")
        -- map([[<c-i>]], "v", "indent visual", ">")
        map { [[zn]], n, "de-indent current line", rhs = "<<" },
        map { [[zi]], n, "indent current line", rhs = ">>" },
        map { [[pzn]], n, "de-indent last paste", rhs = "'[V']<" },
        map { [[pzi]], n, "indent last paste", rhs = "'[V']>" },
        map { [[zn]], v, "de-indent visual", rhs = "<" },
        map { [[zi]], v, "indent visual", rhs = ">" },
    }
end

function M.for_operators()
    return {
        -- just like "moves"
        map { [[l]], o, "to start of word", rhs = "b" },
        map { [[ l]], o, "to start of WORD", rhs = "B" },
        map { [[y]], o, "to end of word", rhs = "e" },
        map { [[ y]], o, "to end of WORD", rhs = "E" },
        map { [[n]], o, "line", rhs = "Vl" },
        map { [[ n]], o, "to start of line", rhs = "^" },
        map { [[ i]], o, "to end of line", rhs = "$" },
        map { [[e]], o, "inner word", rhs = "iw" },
        map { [[ e]], o, "inner word with space", rhs = "aw" },
        map { [[u]], o, "inner WORD", rhs = "iW" },
        map { [[ u]], o, "inner WORD with space", rhs = "aW" },

        -- other
        map { [[.]], o, "character", rhs = "l" },
        map { [[(]], o, "inner ()", rhs = "i(" },
        map { [[)]], o, "outer ()", rhs = "a(" },
        map { [[[]], o, "inner []", rhs = "i[" },
        map { "]", o, "outer []", rhs = "a[" },
        map { [[{]], o, "inner {}", rhs = "i{" },
        map { [[}]], o, "outer {}", rhs = "a{" },
        map { [["]], o, 'inner ""', rhs = 'i"' },
        map { [[ "]], o, 'outer ""', rhs = 'a"' },
        map { [[']], o, "inner ''", rhs = "i'" },
        map { [[ ']], o, "outer ''", rhs = "a'" },
        map { [[<]], o, "inner <>", rhs = "i<" },
        map { [[>]], o, "outer <>", rhs = "a<" },
    }
end

function M.for_visual()
    return {
        map { [[v]], n, "visual lines", rhs = "V" },
        -- map([[v]], "v", "visual characters", "v") -- instead use column moves to switch to characters
        map { [[av]], n, "visual block", rhs = "<c-v>" },
        map { [[dv]], n, "previous visual", rhs = "gv" },
        map { [[v]], v, "exit visual", rhs = "<esc>" },
        map { [[av]], v, "other side", rhs = "o" },
    }
end

function M.for_copy_paste()
    -- copy paste
    -- NOTE we use register "z" so that other change operations dont interfere
    -- NOTE we use mark "z" to control cursor location after pastes
    -- TODO the original y and p are not mapped, and we cant use registers on purpose then
    -- TODO is it better more analytic? paste is just paste, and a thing that moves to end or start?
    -- NOTE both x and c keep cursor where it was
    -- TODO is there a way to paste and use the indentation from the cursor (not the text)
    return {
        map { [[c]], n, "copy", rhs = [["zy]] },
        map { [[c]], v, "copy", rhs = [[mz"zy`z]] },
        map { [[x]], n, "cut", rhs = [["zd]] },
        map { [[x]], v, "cut", rhs = [[mz"zd`z]] },

        -- NOTE "yY copies into y, '< moves to start/end, "yp pastes
        map { [[adu]], v, "duplicate above", rhs = [["yY'<"yP]] },
        map { [[ade]], v, "duplicate below", rhs = [["yY'>"yp]] },
        map { [[ad u]], v, "comment and duplicate above", rhs = [["yYgv<Plug>(comment_toggle_linewise_visual)'<"yP]] },
        map { [[ad e]], v, "comment and duplicate below", rhs = [["yYgv<Plug>(comment_toggle_linewise_visual)'>"yp]] },

        map { [[p]], n, "paste, adapt indentation, and stay" },
        map { [[pu]], n, "insert above", rhs = [[mz"z]P`z]] },
        map { [[pe]], n, "insert below", rhs = [[mz"z]p`z]] },
        map { [[pn]], n, "insert before", rhs = '"zP`]k' },
        map { [[pi]], n, "insert after", rhs = '"zp`[h' },
        map { [[pan]], n, "insert at beginning of text in line", rhs = [[mz0^"zP`z]] },
        map { [[pai]], n, "insert at end of line", rhs = [[mz$"zp`z]] },

        map { [[p ]], n, "but keep indentation" },
        map { [[p u]], n, "insert above", rhs = [[mz"zP`z]] },
        map { [[p e]], n, "insert below", rhs = [[mz"zp`z]] },
        map { [[p n]], n, "insert before", rhs = '"zP`]k' },
        map { [[p i]], n, "insert after", rhs = '"zp`[h' },

        map { [[pp]], n, "but move" },
        map { [[ppu]], n, "insert above", rhs = '"z]P`[' },
        map { [[ppe]], n, "insert below", rhs = '"z]p`]' },
        map { [[ppn]], n, "insert before", rhs = '"zP`[' },
        map { [[ppi]], n, "insert after", rhs = '"zp`]' },
        map { [[ppan]], n, "insert at beginning of text in line", rhs = '0^"zP`[' },
        map { [[ppai]], n, "insert at end of line", rhs = '$"zp`z`]' },

        map { [[pp ]], n, "but keep indentation" },
        map { [[pp u]], n, "insert above", rhs = '"zP`[' },
        map { [[pp e]], n, "insert below", rhs = '"zp`]' },
        map { [[pp n]], n, "insert before", rhs = '"zP`[' },
        map { [[pp i]], n, "insert after", rhs = '"zp`]' },

        map { [[p]], v, "replace visual with paste", rhs = [["zp]] },
    }
end

function M.for_search()
    return {
        map { [[f]], n, "search" },
        map { [[ff]], n, "from the beginning", rhs = "gg0/" },
        map { [[fu]], n, "backwards", rhs = "?" },
        map { [[fe]], n, "forward", rhs = "/" },
        map { [[fn]], n, "word backwards", rhs = "#" },
        map { [[fi]], n, "word forward", rhs = "*" },
        map { [[f,]], n, "clear search", rhs = "<cmd>nohlsearch<enter>" },
        map { [[<a-u>]], n, "previous match", rhs = "Nzz" },
        map { [[<a-e>]], n, "next match", rhs = "nzz" },
    }
end

function M.with_mode(set_mode, rhs)
    local function fn()
        set_mode()
        return rhs
    end
    return fn
end

function M.with_search(rhs)
    return M.with_mode(M.set_search, rhs)
end

function M.set_search()
    M.mode = "search"
    local maps = {
        map { [[<c-k>]], n, "previous match", rhs = "Nzz" },
        map { [[<c-h>]], n, "next match", rhs = "nzz" },
    }
    M.apply_plain(maps)
    vim.cmd.redrawstatus()
end

function M.with_default(rhs)
    return M.with_mode(M.set_default, rhs)
end

function M.set_default()
    M.mode = "default"
    -- TODO clear actual mappings?
    vim.cmd.redrawstatus()
end

function M.set_diagnostic()
    M.mode = "diagnostic"
    local maps = {
        map {
            [[<c-k>]],
            n,
            "previous match",
            fn = function()
                vim.diagnostic.jump { count = -1, float = true }
            end,
        },
        map {
            [[<c-h>]],
            n,
            "next match",
            fn = function()
                vim.diagnostic.jump { count = 1, float = true }
            end,
        },
    }
    M.apply_plain(maps)
    vim.cmd.redrawstatus()
end

---@return Map[] mappings
function M.for_windows()
    local layouts = require("lavish-layouts")
    return {
        map { [[w]], n, "windows" },
        map { [[ww]], n, "new window", fn = layouts.new_from_split },
        map { [[<c-u>]], n, "previous window", fn = layouts.previous },
        map { [[<c-e>]], n, "next window", fn = layouts.next },
        map { [[<c-n>]], n, "focus window", fn = layouts.focus },
        map { [[w ]], n, "focus window", fn = layouts.focus },
        map { [[w,]], n, "close window", fn = layouts.close }, -- [[wc]]
        map { [[w.]], n, "only window", rhs = "<cmd>wincmd o<enter>" },
        map { [[wd]], n, "close window and delete buffer", fn = layouts.close_and_delete },

        -- tabs
        -- map { [[w  ]], n, "new tab", rhs = "<cmd>tab split<enter>" },
        -- map { [[w ,]], n, "close tab", rhs = "<cmd>tabclose<enter>" },
        -- map { [[w .]], n, "only tab", rhs = "<cmd>tabonly<enter>" },
        -- map { [[w n]], n, "previous tab", rhs = "<cmd>-tabnext<enter>" },
        -- map { [[w i]], n, "next tab", rhs = "<cmd>+tabnext<enter>" },

        -- TODO changing layout should be a user command, not a binding, right?
        map { [[wlm]], n, "layout main", fn = layouts.switch_main },
        map { [[wls]], n, "layout stacked", fn = layouts.switch_stacked },
    }
end

---@return Map[] mappings
function M.for_jumps()
    -- TODO want to make this generic, and dynamic
    local t = require("yi.telescope")
    local l = require("yi.lsp")

    return {
        map { [[t]], n, "jumps" },

        map {
            [[td ]],
            n,
            "jump to next diagnostic",
            fn = function()
                M.set_diagnostic()
                vim.diagnostic.jump { count = 1, float = true }
            end,
        },

        map { [[tr]], n, "jump to references", fn = l.pick_references },
        map { [[tar]], n, "jump to previous references", fn = t.pick_previous_references },
        -- TODO wrong place a bit
        map { [[E]], n, "next entry", rhs = "<cmd>cn<enter>" },
        map { [[U]], n, "previous entry", rhs = "<cmd>cN<enter>" },
        map {
            [[a.]],
            n,
            "show lsp hover",
            fn = function()
                -- TODO cant find where we can set those defaults
                vim.lsp.buf.hover { border = "double", anchor_bias = "above" }
            end,
        },
        map {
            [[a,]],
            n,
            "show diagnostic",
            fn = vim.diagnostic.open_float,
        },
        -- TODO would be nicer to have the same binding to toggle
        map { [[=]], n, "highlight references", fn = l.highlight_references },
        map { [[?]], n, "clear highlight references", fn = l.clear_highlight_references },
        -- TODO range actions also exist, not the same as union of actions, more like "make try except" and stuff
        map { [[a;]], n, "code action", fn = l.code_action },
        map { [[a;]], v, "code action", fn = l.code_action },
        map { [[a_]], n, "toggle inlay hints", fn = l.toggle_inlay_ints },
        map { [[<F11-t>]], i, "show function signature", fn = l.show_function_signature },
        -- TODO again this would be better just a command behind a lsp prefix, like for layouts?
        map { [[ao]], n, "rename symbol", fn = l.rename_symbol },
        map { [[ai]], n, "add ignore", fn = l.add_ignore },

        map { [[tt]], n, "definition", fn = l.go_to_definition },
        map { [[tn]], n, "files", fn = t.pick_file },
        map { [[tg]], n, "live grep", fn = t.pick_grep },
        map { [[tb]], n, "buffers", fn = t.pick_buffer },
        map { [[th]], n, "help tags", fn = t.pick_help },
        map { [[tk]], n, "man pages", fn = t.pick_man },
        map { [[t k]], n, "all man pages", fn = t.pick_man_all },
        map { [[tm]], n, "marks", fn = t.pick_mark },
        map { [[tfc]], n, "config files", fn = t.pick_file_config },
        map { [[te]], n, "buffer symbols", fn = t.pick_buffer_symbol },
        map { [[tu]], n, "project symbols", fn = t.pick_project_symbol },
        map { [[tde]], n, "buffer diagnostics", fn = t.pick_buffer_diagnostics },
        map { [[tdae]], n, "buffer all diagnostics", fn = t.pick_buffer_diagnostics_all },
        map { [[tdu]], n, "project diagnostics", fn = t.pick_project_diagnostics },
        map { [[tdau]], n, "project all diagnostics", fn = t.pick_project_diagnostics_all },
        map { [[tc]], n, "files diff to main", fn = t.pick_diff_files },
    }
end

-- TODO comma is already used for last insert maybe?
-- TODO call it misc?
function M.for_comma()
    local function reset_view_and_format()
        vim.cmd([[normal! 0^]])
        require("yi.formatter").format_buffer()
    end
    local g = require("yi.fugitive")
    return {
        map { [[,]], n, "misc" },
        map { [[,x]], n, "(try) save and exit (anyway)", rhs = "<cmd>silent! wa<enter><cmd>qa!<enter>" },
        map { [[<c-d>]], ni, "(try) save and exit (anyway)", rhs = "<cmd>silent! wa<enter><cmd>qa!<enter>" },

        -- formatter and git
        map { [[==]], n, "format buffer", fn = reset_view_and_format },
        map { [[gn]], n, "git", fn = g.git },
    }
end

function M.for_undos()
    return {
        map { [[<c-w>]], n, "undo", rhs = "u" },
        map { [[<c-f>]], n, "redo", rhs = "<c-r>" },
    }
end

function M.for_completion()
    local c = require("yi.completion")
    return {
        map { [[<c-t>]], i, "complete flat", fn = c.complete_flat },
        map { [[<c-l>]], i, "complete full", fn = c.complete_full },
    }
end

return M
