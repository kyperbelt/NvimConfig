local prefix = "core.plugin_config."

local configs = {
  "theme",
  "lualine",
  "nvim-tree",
  "telescope",
  "treesitter",
  "toggleterm",
  "whichkey",
  "dap",
  "lsp_config",
  "orgmode",
}


-- require("core.plugin_config.theme")
-- require("core.plugin_config.lualine")
-- require("core.plugin_config.nvim-tree")
-- require("core.plugin_config.telescope")
-- require("core.plugin_config.treesitter")
-- require("core.plugin_config.toggleterm")
-- require("core.plugin_config.whichkey")
-- require(prefix.."dap")
-- require(prefix.."lsp_config")

for _, config in ipairs(configs) do
  require(prefix..config)
end
