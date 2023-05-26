
require("lualine").setup ({
  options = {
      icons_enabled = true,
      theme = "gruvbox",
    },
  sections = {
    lualine_a = {
      'mode',
      -- 'branch',
      -- 'vim.inspect(vim.cmd("call copilot#Call(\'checkStatus\', {})") == "")'
    },
    lualine_c = {
      'filename',
      'searchcount'
    },
   -- lualine_a = {
   --   "vim.inspect(vim.cmd([[Copilot status]]))"
   -- },
   print()
  }
})
