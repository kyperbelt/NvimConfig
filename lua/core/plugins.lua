local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)

  use 'wbthomason/packer.nvim'
  use "ellisonleao/gruvbox.nvim"

  -- File tree
  use "nvim-tree/nvim-tree.lua"
  use "nvim-tree/nvim-web-devicons"

  -- Status line
  use "nvim-lualine/lualine.nvim"

  -- Syntax
  use "nvim-treesitter/nvim-treesitter"
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.1',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  -- Terminal
  use {"akinsho/toggleterm.nvim"}

  -- KeyMappings
  use {
    "folke/which-key.nvim",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end
  } 

  use{
    "numToStr/Comment.nvim",
    config = function()
      require('Comment').setup()
    end
  }

  -- LSP
  use "williamboman/mason.nvim"
  use "williamboman/mason-lspconfig.nvim"
  use "neovim/nvim-lspconfig"
  use "mfussenegger/nvim-dap"

  use "github/copilot.vim"


  -- NOTE TAKING
  use { "nvim-orgmode/orgmode", config = function()
      require("orgmode").setup{}
    end
  }

  -- Utility
  use "mg979/vim-visual-multi"




  -- My plugins here
  -- use 'foo1/bar1.nvim'
  -- use 'foo2/bar2.nvim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)


