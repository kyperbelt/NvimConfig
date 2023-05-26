local orgmode = require("orgmode")

orgmode.setup_ts_grammar()

require("nvim-treesitter.configs").setup {
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = { "org" },
  },
  ensure_installed = { "org" },
}

orgmode.setup({
  org_agenda_files = {
    "~/org-agenda/*",
  },
  org_default_notes_file = "~/org-agenda/refile.org",

})
