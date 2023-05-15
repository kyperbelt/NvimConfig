require("lualine").setup ({
  options = {
      icons_enabled = true,
      theme = "gruvbox",
    },
  sections = {
    lualine_a = {
      'mode',
      'branch'
    },
    lualine_c = {
      'filename',
      'searchcount'
    }
  }
})
