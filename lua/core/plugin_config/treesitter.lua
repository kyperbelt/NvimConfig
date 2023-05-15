require("nvim-treesitter.configs").setup(
  {
    ensure_installed = {
                        -- languages 
                        "c", 
                        "lua", 
                        "java", 
                        "rust", 
                        "markdown", 
                        "python", 
                        "gdscript",
                      },

    sync_install = false,
    auto_install = true,
    highlight = {
      enable = true,
    }
  }
)
