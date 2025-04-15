local M = {}

function M.on_attach_rust(client, bufnr)
    local function nmap(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
    end

    M.on_attach(client, bufnr)
    nmap("td", ":RustLsp openDocs<CR>", "go to docs")
end

function M.setup(capabilities)
    vim.g.rustaceanvim = {
        server = {
            on_attach = M.on_attach_rust,
            capabilities = capabilities,
        },
    }
end

return M
