if vim.g.neovide then
  vim.g.neovide_remember_window_size = true
end

vim.g.loaded_netrw = 1
vim.g["grammarous#jar_url"] = 'https://www.languagetool.org/download/LanguageTool-5.9.zip'
vim.g.loaded_netrwPlugin = 1

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set('i', '<C-J>', 'copilot#Accept("<CR>")', {
  expr = true,
  replace_keycodes = false
})

vim.g.copilot_no_tab_map = true
-- disable copilot by default
vim.g.copilot_enabled = false


-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- NOTE: First, some plugins that don't require any configuration

  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',
  'godlygeek/tabular',
  'rhysd/vim-grammarous',
  'github/copilot.vim',
  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',


  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  --
  {
    "tamago324/nlsp-settings.nvim",
    dependencies = {
      "neovim/nvim-lspconfig", -- Optional but recommended dependency
    },
    config = function()
      require("nlspsettings").setup({
        config_home = vim.fn.stdpath('config') .. '/nlsp-settings',
        local_settings_root_markers = { '.git' },
        jsonls_append_default_schemas = true,
        append_default_schemas = true,
        loader = 'json'
      })
    end
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    lazy = false,
    keys = {
      {
        '<leader>cf',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = true,
      -- format_on_save = function(bufnr)
      --   -- Disable "format_on_save lsp_fallback" for languages that don't
      --   -- have a well standardized coding style. You can add additional
      --   -- languages here or re-enable it for the disabled ones.
      --   local disable_filetypes = { c = true, cpp = true, java = false, xml = true, html = true, javascript = true }
      --   return {
      --     timeout_ms = 500,
      --     lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      --   }
      -- end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use a sub-list to tell conform to run *until* a formatter
        -- is found.
        -- javascript = { { "prettierd", "prettier" } },
        java = { 'jdtls', 'clang-format' },
        php = { 'php' }
      },
      formatters = {
        php = {
          command = "php-cs-fixer",
          args = {
            "fix",
            "$FILENAME",
            -- "--config=/your/path/to/config/file/[filename].php",
            -- "--allow-risky=yes",             -- if you have risky stuff in config, if not you dont need it.
          },
          stdin = false,
        }
      },
    },
  },

  {                --Note Taking notetaking notes note
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    --   "BufReadPre path/to/my-vault/**.md",
    --   "BufNewFile path/to/my-vault/**.md",
    -- },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",

      -- see below for full list of optional dependencies 👇
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/notes/vault1",
        },
      },

      -- see below for full list of options 👇
    },
  },
  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        -- markdown = { 'markdownlint' },
        java = { 'checkstyle' },
        html = { 'djlint' },
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          require('lint').try_lint()
        end,
      })
    end,
  },
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim',       tag = 'legacy', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim',
    },
  },
  {
    'Hoffs/omnisharp-extended-lsp.nvim',
  },
  {
    'smoka7/hop.nvim',
    version = "*",
    opts = {
      keys = 'etovxqpdygfblzhckisuran'
    },
    config = function()
      local hop = require 'hop';
      hop.setup();
      local directions = require 'hop.hint'.HintDirection;
      vim.keymap.set('n', '<leader><leader>/', function()
        hop.hint_char1 {
          direction = directions.AFTER_CURSOR
        }
      end, { desc = 'Hop to [H]ere' }) -- Hop to here
    end
  },
  {
    -- debugger | debugging | dap
    'mfussenegger/nvim-dap',
    dependencies = {
      -- Creates a beautiful debugger UI
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',

      -- Installs the debug adapters for you
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',

      -- Add your own debuggers here
      'leoluz/nvim-dap-go',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'


      require('mason-nvim-dap').setup {
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_installation = true,
        automatic_setup = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {},

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure that you have the debuggers for the langs you want
          -- 'delve',
          'java',
        },
      }

      dap.adapters.godot = {
        type = "server",
        host = "127.0.0.1",
        port = 6006,
      }

      dap.configurations.gdscript = {
        {
          type = "godot",
          request = "launch",
          name = "Launch Scene",
          program = "${workspaceFolder}",
          launch_scene = true,
        },
      }

      -- Basic debugging keymaps, feel free to change to your liking!
      vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
      vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
      vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
      vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
      vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
      vim.keymap.set('n', '<leader>B', function()
        dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end, { desc = 'Debug: Set Breakpoint' })

      -- Dap UI setup
      -- For more information, see |:help nvim-dap-ui|
      dapui.setup {
        -- Set icons to characters that are more likely to work in every terminal.
        --    Feel free to remove or use ones that you like more! :)
        --    Don't feel like these are good choices.
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
          icons = {
            pause = '‖',
            play = '▶',
            step_into = '⏎',
            step_over = '⤠',
            step_out = '⤟',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏻',
            disconnect = '⏏',
          },
        },
      }

      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      -- Install golang specific config
      require('dap-go').setup()
    end,
  },
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    config = function()
      -- trouble keybinds | trouble keymaps
      vim.keymap.set("n", "<leader>xx", function() require("trouble").open("diagnostics") end,
        { desc = "[X]pen Trouble" })
      -- vim.keymap.set("n", "<leader>xw", function() require("trouble").open("workspace_diagnostics") end,
      --   { desc = "[W]orkpace diagnostics" })
      -- vim.keymap.set("n", "<leader>xd", function() require("trouble").open("document_diagnostics") end,
      --   { desc = "[D]ocument diagnostics" })
      vim.keymap.set("n", "<leader>xq", function() require("trouble").open("quickfix") end, { desc = "[Q]uickfix" })
      vim.keymap.set("n", "<leader>xl", function() require("trouble").open("loclist") end, { desc = "[L]oclist" })
    end,
  },

  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',
    },
  },
  {
    'nvim-tree/nvim-tree.lua',
    commit = '75ff64e',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('nvim-tree').setup({
      })
    end
  },

  -- Useful plugin to show you pending keybinds.
  {
    'folke/which-key.nvim',
    config = function()
      local wk = require("which-key")

      wk.register({
        ["<leader>f"] = { name = "+find" },
        ["<leader>w"] = { name = "+window" },
        ["<leader>b"] = { name = "+buffer" },
        ["<leader>c"] = { name = "+code" },
        ["<leader>g"] = { name = "+git" },
      })
    end
    ,
    opts = {}
  },
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>gp', require('gitsigns').prev_hunk,
          { buffer = bufnr, desc = '[G]o to [P]revious Hunk' })
        vim.keymap.set('n', '<leader>gn', require('gitsigns').next_hunk, { buffer = bufnr, desc = '[G]o to [N]ext Hunk' })
        vim.keymap.set('n', '<leader>ph', require('gitsigns').preview_hunk, { buffer = bufnr, desc = '[P]review [H]unk' })
      end,
    },
  },

  {
    -- Theme gruvbox
    -- "ellisonleao/gruvbox.nvim",
    -- "Mofiqul/dracula.nvim",
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'tokyonight-moon'
      -- vim.cmd.colorscheme 'dracula'
      -- vim.cmd.colorscheme 'gruvbox'
    end,
  },

  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = true,
        theme = 'tokyonight',
        -- component_separators = '|',
        -- section_separators = '',
      },
      sections = {
        lualine_a = {
          'mode',
        },
        lualine_c = {
          'filename',
          'searchcount',
        }
      }
    },
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help indent_blankline.txt`
    main = "ibl",
    opts = {
      indent = {
        char = '┊',
        -- show_trailing_blankline_indent = false,
      },
      whitespace = {
        remove_blankline_trail = true
      }
    },
  },

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
  },

  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },
  {
    -- markdown preview
    "iamcco/markdown-preview.nvim",
    config = function()
      vim.fn["mkdp#util#install"]()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
    end,
  },

}, {})

require 'extension.snippets'

-- Config

vim.o.hlsearch = true
vim.o.number = true
vim.o.relativenumber = true

vim.o.breakindent = true

vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.wo.signcolumn = 'yes'

vim.o.clipboard = 'unnamedplus'

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.textwidth = 200

vim.o.completeopt = 'menuone,noselect'

vim.o.termguicolors = true
vim.o.conceallevel = 1

--[[KEYMAPS | keymappings | maps | keybinds]]


-- misc | general
vim.keymap.set('n', '<Leader>h', ':nohlsearch<CR>', { desc = "Remove Highlight" })
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- file | directory
local toggle_replace = function()
  local api = require("nvim-tree.api")
  if api.tree.is_visible() then
    api.tree.close()
  else
    api.tree.open({
      current_window = true,
      find_file = true,
    })
  end
end

vim.keymap.set('n', '<Leader>dt', toggle_replace, { desc = "directory [T]oggle" })
vim.keymap.set('n', '<leader>fc', ':e ~/.config/nvim/init.lua<CR>', { desc = "[C]onfig" }) -- open configuration file

-- windows
vim.keymap.set('n', '<Leader>wv', ':vsplit<CR>', { desc = "Vertical Split" })
vim.keymap.set('n', '<Leader>ws', ':split<CR>', { desc = "Horizontal Split" })
vim.keymap.set('n', '<Leader>wh', '<c-w>h', { desc = "Move Left" })
vim.keymap.set('n', '<Leader>wj', '<c-w>j', { desc = "Move Down" })
vim.keymap.set('n', '<Leader>wk', '<c-w>k', { desc = "Move Up" })
vim.keymap.set('n', '<Leader>wl', '<c-w>l', { desc = "Move Right" })

-- buffer
vim.keymap.set('n', '<Leader>bn', '<c-w>l', { desc = "Move Right" })
vim.keymap.set('n', '<Leader>bx', ':bd<CR>', { desc = "Delete Buffer" })


local prev_buf = 0
vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
  pattern = { "" },
  callback = function(ev)
    if vim.fn.buflisted(ev.buf) > 0 then
      prev_buf = ev.buf
    end
  end
})


vim.keymap.set('n', '<Leader>bb', function() return ":" .. prev_buf .. "b<CR>" end,
  { desc = "[B]ack buffer", expr = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = '[F]ind [F]iles' })
vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = '[F]ind [H]elp' })
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, { desc = '[F]ind with Live [G]rep' })
vim.keymap.set('n', '<leader>fd', require('telescope.builtin').diagnostics, { desc = '[F]ind [D]iagnostics' })
vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers, { desc = '[F]ind [B]uffers' })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
require('nvim-treesitter.configs').setup {
  -- Add languages to be installed here that you want installed for treesitter
  ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'typescript', 'vimdoc', 'vim', 'markdown',
    'markdown_inline' },

  -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
  auto_install = false,

  highlight = { enable = true, additional_vim_regex_highlighting = { 'markdown' } },
  indent = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<c-space>',
      node_incremental = '<c-space>',
      scope_incremental = '<c-s>',
      node_decremental = '<M-space>',
    },
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ['aa'] = '@parameter.outer',
        ['ia'] = '@parameter.inner',
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer',
      },
    },
    swap = {
      enable = true,
      swap_next = {
        ['<leader>a'] = '@parameter.inner',
      },
      swap_previous = {
        ['<leader>A'] = '@parameter.inner',
      },
    },
  },
}


vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevelstart = 99

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = '[lsp] ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>cn', vim.lsp.buf.rename, 're[N]ame')
  nmap('<leader>cc', vim.lsp.buf.code_action, '[C]ode action')

  nmap('<leader>cd', vim.lsp.buf.definition, 'goto [D]efinition')
  nmap('<leader>cr', require('telescope.builtin').lsp_references, 'goto [R]eferences')
  nmap('<leader>ci', vim.lsp.buf.implementation, 'goto [I]mplementation')
  nmap('<leader>ct', vim.lsp.buf.type_definition, '[T]ype definition')
  -- nmap('<leader>cf', vim.lsp.buf.format, '[F]ormat buffer')
  nmap('<leader>cs', require('telescope.builtin').lsp_document_symbols, 'document [s]ymbols')
  nmap('<leader>cS', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'workspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('<leader>ck', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
end


-- [[LSP]]

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.

local servers = {
  -- clangd = {},
  -- gopls = {},
  -- pyright = {},
  -- rust_analyzer = {},
  -- tsserver = {},
  -- html = { filetypes = { 'html', 'twig', 'hbs'} },
  -- glsl_analyzer = {},
  -- checkstyle = {
  -- },
  emmet_language_server = {},
  lua_ls = {
    Lua = {

      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
  biome = {
  },
  jinja_lsp = {
    filetypes = { 'html' }
  },
  omnisharp = {
    -- cmd = {'./local/share/nvim/mason/bin/omnisharp', '--languageserver', '--hostPID', tostring(vim.fn.getpid())},
    enable_roslyn_analyzers = true,
  },
  html = {
    -- filetypes = { 'html', 'twig', 'hbs', "jsx", "tsx", "rust", "css", "scss", "javascript", "typescript" },
    init_options = {
      -- userLanguages = {
      --   rust = "html"
      -- },
    },
  },
  tailwindcss = {
    -- filetypes = { 'html', 'twig', 'hbs', "jsx", "tsx", "rust", "css", "scss", "javascript", "typescript", "javascriptreact", "typescriptreact"},
    init_options = {
      -- userLanguages = {
      --   rust = "html"
      -- },
    },
  },
  jdtls = {
  },
}

local checkstyle = require('lint').linters.checkstyle
checkstyle.args = {
  "-c",
  "file://" .. vim.fn.getcwd() .. "/config/checkstyle/checkstyle.xml"
}

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

require('mason-tool-installer').setup { ensure_installed = vim.tbl_keys(servers or {}) }

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      handlers = server_name == "omnisharp" and { ["textDocument/definition"] = require('omnisharp_extended').handler } or
          {},
      format = (servers[server_name] or {}).format,
      settings = servers[server_name],
      filetypes = (servers[server_name] or {}).filetypes,
      init_options = (servers[server_name] or {}).init_options,
    }
  end,
}

require("lspconfig")['gdscript'].setup {
  capabilities = capabilities,
  on_attach = on_attach,
  -- cmd = vim.lsp.rpc.connect('172.18.176.1', 6005)
}
require 'lspconfig'.glsl_analyzer.setup {
  capabilities = capabilities,
  on_attach = on_attach,
}


-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {
  updateevents = "TextChanged,TextChangedI",
}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'codeium' },
  },
}


-- whichkey

local wk = require("which-key")

wk.register({
  ["<leader>f"] = { name = "+find" },
  ["<leader>w"] = { name = "+window" },
  ["<leader>b"] = { name = "+buffer" },
  ["<leader>c"] = { name = "+code" },
  ["<leader>g"] = { name = "+git" },
})
