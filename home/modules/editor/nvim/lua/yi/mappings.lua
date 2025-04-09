local M = {}

-- consider https://colemakmods.github.io/mod-dh/model.html
-- when it comes to reachability at first

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
    return maps
end

--- apply using nvim api
---@param maps Map[] mappings to apply
function M.apply_plain(maps)
    M.clear()
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
    -- NOTE difference between deleting and unsetting a default
    for _, lhs in ipairs { "<c-w>d", "<c-w><c-d>" } do
        vim.keymap.del("n", lhs)
    end
    for _, lhs in ipairs { "o", "q" } do
        vim.keymap.set("n", lhs, "<nop>")
    end
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
    local nv = "nv"
    return {
        -- plain
        map { [[n]], nv, "cursor left", expr = vv("h") },
        map { [[e]], nv, "cursor down", rhs = "j" },
        map { [[i]], nv, "cursor right", expr = vv("l") },
        map { [[u]], nv, "cursor up", rhs = "k" },
        map { [[<up>]], nv, "view and cursor up", rhs = "1<c-u>" },
        map { [[<down>]], nv, "view and cursor down", rhs = "1<c-d>" },
        -- words
        map { [[l]], nv, "word back", expr = vv("b") },
        map { [[ l]], nv, "word end back", expr = vv("ge") },
        map { [[<c-l>]], nv, "WORD back", expr = vv("B") },
        map { [[y]], nv, "word forward", expr = vv("w") },
        map { [[ y]], nv, "word end forward", expr = vv("e") },
        map { [[<c-y>]], nv, "WORD forward", expr = vv("W") },
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
        map { [[-]], nv, "go to last insert and center", rhs = "`^zz" },
        map { [[<]], nv, "go to previous jump location", rhs = "<c-o>" },
        map { [[<a-n>]], nv, "go to previous jump location", rhs = "<c-o>" },
    }
end

function M.for_inserts()
    local n, v = "n", "v"
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
        map { [[ssm]], n, "insert at beginning of line", rhs = "0i" },
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
    local i = "i"
    return {
        -- TODO almost not worth it?
        map { [[<c-u>]], i, "new line above", rhs = "<esc>O" },
        map { [[<c-e>]], i, "new line below", rhs = "<esc>o" },
    }
end

function M.for_changes()
    local n, v, nv = "n", "v", "nv"
    return {
        -- TODO this means operator pending, but the next [[rr]] might interfere?
        map { [[r]], n, "replace", rhs = "c" },
        map { [[rr]], n, "replace single character", rhs = "r" },
        map { [[j]], nv, "join lines", rhs = "J" },
        map { [[r]], v, "replace over visual", rhs = "c" },
        map { [[d]], nv, "delete", rhs = "d" },
        map { [[<delete>]], n, "delete under cursor", rhs = "x" },
        map { [[.]], n, "repeat", rhs = "." },
    }
end

function M.for_indentation()
    local n, v = "n", "v"
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
    local o = "o"
    return {
        -- operators
        -- TODO re for word, rre for WORD? similar to s and ss for alternate? but then how to make it work for x, c, d? space instead?
        -- or switch around once again, mark and then operation?
        -- TODO but still, is it possible to make operators, plain nav, and s-inserts be "the same"?
        map { [[e]], o, "inner word", rhs = "iw" },
        map { [[u]], o, "inner WORD", rhs = "iW" },
        map { [[ e]], o, "inner WORD with space", rhs = "aW" },
        map { [[l]], o, "to start of word", rhs = "b" },
        map { [[ l]], o, "to start of WORD", rhs = "B" },
        map { [[y]], o, "to end of word", rhs = "e" },
        map { [[ y]], o, "to end of WORD", rhs = "E" },
        map { [[n]], o, "line", rhs = "Vl" },
        map { [[ n]], o, "to start of line", rhs = "^" },
        map { [[an]], o, "to start of line", rhs = "^" },
        map { [[ i]], o, "to end of line", rhs = "$" },
        map { [[ai]], o, "to end of line", rhs = "$" },
        map { [[(]], o, "inner ()", rhs = "i(" },
        map { [[)]], o, "outer ()", rhs = "a(" },
        map { [[[]], o, "inner []", rhs = "i[" },
        map { "]", o, "outer []", rhs = "a[" },
        map { [[{]], o, "inner {}", rhs = "i{" },
        map { [[}]], o, "outer {}", rhs = "a{" },
        map { [[.]], o, "character", rhs = "l" },
        map { [[m]], o, 'inner ""', rhs = 'i"' },
        map { [[ m]], o, 'outer ""', rhs = 'a"' },
        map { [[o]], o, "inner ''", rhs = "i'" },
        map { [[ o]], o, "outer ''", rhs = "a'" },
    }
end

function M.for_visual()
    local n, v = "n", "v"
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

    local n, v = "n", "v"
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
    local n = "n"
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

---@return Map[] mappings
function M.for_windows()
    local layouts = require("lavish-layouts")
    ---@param op fun(make?: fun())
    ---@return fun() fn
    local function jump(op)
        return function()
            op(layouts.new)
        end
    end
    local n = "n"
    return {
        map { [[w]], n, "windows" },
        map { [[ww]], n, "new window", fn = layouts.new_from_split },
        map { [[wo]], n, "alternate window", rhs = "<c-w>p" },
        map { [[<c-u>]], n, "previous window", fn = layouts.previous },
        map { [[<c-e>]], n, "next window", fn = layouts.next },
        map { [[<c-n>]], n, "focus window", fn = layouts.focus },
        map { [[w ]], n, "focus window", fn = layouts.focus },
        map { [[w,]], n, "close window", fn = layouts.close }, -- [[wc]]
        map { [[w.]], n, "only window", rhs = "<cmd>wincmd o<enter>" },

        -- TODO maybe see https://vi.stackexchange.com/questions/3879/duplicate-tab-with-windows
        -- map([[wt]], "n", "new tab", cmd("tab split"))
        -- map([[wc]], "n", "close tab", cmd("tabclose"))

        -- TODO changing layout should be a user command, not a binding, right?
        map { [[wlm]], n, "layout main", fn = layouts.switch_main },
        map { [[wls]], n, "layout stacked", fn = layouts.switch_stacked },
        -- map { [[wlt]], n, "layout tiled", fn = layouts.switch_tiled },

        map { [[wn]], n, "new window from files", fn = jump(M.ops.pick_file) },
        map { [[wg]], n, "new window from live grep", fn = jump(M.ops.pick_grep) },
        map { [[wb]], n, "new window from buffers", fn = jump(M.ops.pick_buffer) },
        map { [[wh]], n, "new window from help tags", fn = jump(M.ops.pick_help) },
        map { [[wk]], n, "new window from man pages", fn = jump(M.ops.pick_man) },
        map { [[wak]], n, "new window from all man pages", fn = jump(M.ops.pick_man_all) },
        map { [[wm]], n, "new window from marks", fn = jump(M.ops.pick_mark) },

        map { [[we]], n, "jump to buffer symbols", fn = jump(M.ops.pick_buffer_symbol) },
        map { [[wu]], n, "jump to project symbols", fn = jump(M.ops.pick_project_symbol) },
        map { [[wd.]], n, "jump to buffer diagnostics", fn = jump(M.ops.pick_buffer_diagnostics) },
        map { [[wad.]], n, "jump to buffer diagnostics", fn = jump(M.ops.pick_buffer_diagnostics_all) },
        map { [[wd,]], n, "jump to project diagnostics", fn = jump(M.ops.pick_project_diagnostics) },
        map { [[wad,]], n, "jump to project diagnostics", fn = jump(M.ops.pick_project_diagnostics_all) },

        map { [[wt]], n, "go to definition", fn = jump(M.ops.go_to_definition) },
    }
end

---@return Map[] mappings
function M.for_jumps()
    ---@param op fun(make: fun())
    ---@return fun() fn
    local function jump(op)
        return function()
            op(function() end)
        end
    end
    local n = "n"
    return {
        map { [[t]], n, "jumps" },
        map { [[tn]], n, "jump to files", fn = jump(M.ops.pick_file) },
        map { [[tg]], n, "jump to live grep", fn = jump(M.ops.pick_grep) },
        map { [[tb]], n, "jump to buffers", fn = jump(M.ops.pick_buffer) },
        map { [[th]], n, "jump to help tags", fn = jump(M.ops.pick_help) },
        map { [[tk]], n, "jump to man pages", fn = jump(M.ops.pick_man) },
        map { [[tak]], n, "jump to all man pages", fn = jump(M.ops.pick_man_all) },
        map { [[tm]], n, "jump to marks", fn = jump(M.ops.pick_mark) },

        map { [[te]], n, "jump to buffer symbols", fn = jump(M.ops.pick_buffer_symbol) },
        map { [[tu]], n, "jump to project symbols", fn = jump(M.ops.pick_project_symbol) },
        map { [[td.]], n, "jump to buffer diagnostics", fn = jump(M.ops.pick_buffer_diagnostics) },
        map { [[tad.]], n, "jump to buffer all diagnostics", fn = jump(M.ops.pick_buffer_diagnostics_all) },
        map { [[td,]], n, "jump to project diagnostics", fn = jump(M.ops.pick_project_diagnostics) },
        map { [[tad,]], n, "jump to project all diagnostics", fn = jump(M.ops.pick_project_diagnostics_all) },

        -- TODO is that jumps? or just lsp?
        map { [[tt]], n, "go to definition", fn = jump(M.ops.go_to_definition) },

        -- TODO again, not quite the same as t... and w...
        map { [[tr]], n, "show references", fn = vim.lsp.buf.references },
        map { [[E]], n, "next entry", rhs = "<cmd>cn<enter>" },
        map { [[U]], n, "previous entry", rhs = "<cmd>cN<enter>" },
    }
end

---@param name string name
---@return fun(make: fun()) operation
local function nop(name)
    ---@param make fun() prepare a (new) window before jumping
    return function(make)
        vim.cmd.echomsg([["]] .. "No op is set for '" .. name .. [['"]])
    end
end

local function na(name)
    return function()
        vim.cmd.echomsg([["]] .. "No op is set for '" .. name .. [['"]])
    end
end

M.ops = {
    pick_file = nop("pick file"),
    pick_grep = nop("pick grep"),
    pick_buffer = nop("pick buffer"),
    pick_help = nop("pick help"),
    pick_man = nop("pick man"),
    pick_man_all = nop("pick all man"),
    pick_mark = nop("pick mark"),
    pick_buffer_symbol = nop("pick buffer symbol"),
    pick_project_symbol = nop("pick project symbol"),
    pick_buffer_diagnostics = nop("pick buffer diagnostics"),
    pick_buffer_diagnostics_all = nop("pick buffer diagnostics all"),
    pick_project_diagnostics = nop("pick project diagnostics"),
    pick_project_diagnostics_all = nop("pick project diagnostics all"),
    go_to_definition = nop("go to definition"),
    format_buffer = na("format buffer"),
    git = na("git"),
}

-- TODO comma is already used for last insert maybe?
-- TODO call it misc?
function M.for_comma()
    local n = "n"
    local function reset_view_and_format()
        vim.cmd([[normal! 0^]])
        M.ops.format_buffer()
    end
    return {
        map { [[,]], n, "misc" },
        -- TODO make only when available
        -- map { [[,/]], n, "which key", fn = require("which-key").show },
        -- TODO write all and then exit whatever, too dangerous?
        map { [[,x]], n, "(try) save and exit (anyway)", rhs = "<cmd>silent! wa<enter><cmd>qa!<enter>" },
        -- map { [[, ]], n, "legendary", fn = require("legendary").find },
        -- map { [[<esc>]], n, "format buffer", fn = reset_view_and_format },
        -- map { [[,g]], n, "git", fn = M.ops.git },
    }
end

function M.for_undos()
    local n = "n"
    return {
        map { [[<c-w>]], n, "undo", rhs = "u" },
        map { [[<c-f>]], n, "redo", rhs = "<c-r>" },
    }
end

-- pre-operator visuals
-- TODO w used for windows and stuff now
-- grp([[w]], "n", "visuals")
-- map([[wen]], "n", "inner ()", "vi(")
-- map([[wun]], "n", "outer ()", "va(")
-- map([[wee]], "n", "inner []", "vi[")
-- map([[wue]], "n", "outer []", "va[")
-- map([[wei]], "n", "inner []", "vi{")
-- map([[wui]], "n", "outer []", "va{")

-- TODO can we have a switch to move cursor and window with neiu, and timeout back to normal? behind b?
-- does which key do that with the hydra thing?

return M
