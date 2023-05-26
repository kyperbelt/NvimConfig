

require("which-key").setup {
  -- your configuration comes here
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
}


local wk = require("which-key")

wk.register({
  ["<leader>f"] = {name = "+find"},
  ["<leader>w"] = {name = "+window"},
  ["<leader>t"] = {name = "+terminal"},
  ["<leader>o"] = {name = "+org"},
  ["<leader>b"] = {name = "+buffer"},
  ["<leader>c"] = {name = "+code"},
})
