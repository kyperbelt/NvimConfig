require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {"lua_ls"}
})

lspconfig = require("lspconfig")
lspconfig.lua_ls.setup({})




-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', '<Leader>cr', vim.lsp.buf.rename, vim.tbl_deep_extend("force", opts,{desc = "Rename"}))
    vim.keymap.set('n', '<Leader>cc', vim.lsp.buf.code_action, vim.tbl_deep_extend("force", opts,{desc = "Code Action"}))

    vim.keymap.set('n', '<Leader>cd', vim.lsp.buf.definition, vim.tbl_deep_extend("force", opts,{desc = "Definition"}))
    vim.keymap.set('n', '<Leader>ck', vim.lsp.buf.hover, vim.tbl_deep_extend("force", opts,{desc = "Show Hover"}))
    vim.keymap.set('n', '<Leader>ci', vim.lsp.buf.implementation, vim.tbl_deep_extend("force", opts,{desc = "Implementation"}))
    vim.keymap.set('n', '<Leader>cr', require("telescope.builtin").lsp_references,vim.tbl_deep_extend("force", opts,{desc = "Find References"}))

    vim.keymap.set('n', '<Leader>cf', vim.lsp.buf.format, vim.tbl_deep_extend("force", opts,{desc = "Format"}))


    -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    --vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    --vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    --vim.keymap.set('n', '<space>wl', function()
    --  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    --end, opts)
    --vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    --vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    --vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    --vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    --vim.keymap.set('n', '<space>f', function()
    --  vim.lsp.buf.format { async = true }
    --end, opts)
  end,
})
