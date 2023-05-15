

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.backspace = '2'
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.autowrite = true
vim.opt.cursorline = true
vim.opt.autoread = true 
vim.opt.timeout = true
vim.opt.timeoutlen = 300

vim.opt.number = true
vim.opt.relativenumber = true

-- spacing
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.expandtab = true

-------------
-- keymaps 
-------------
vim.keymap.set('n', '<Leader>h', ':nohlsearch<CR>', {desc="Remove Highlight"})

-- windows
vim.keymap.set('n', '<Leader>wv', ':vsplit<CR>', {desc="Vertical Split"})
vim.keymap.set('n', '<Leader>ws', ':split<CR>', {desc="Horizontal Split"})
vim.keymap.set('n', '<Leader>wh', '<c-w>h', {desc="Move Left"})
vim.keymap.set('n', '<Leader>wj', '<c-w>j', {desc="Move Down"})
vim.keymap.set('n', '<Leader>wk', '<c-w>k', {desc="Move Up"})
vim.keymap.set('n', '<Leader>wl', '<c-w>l', {desc="Move Right"})



