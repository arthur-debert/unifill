-- Add plugin paths
local plenary_path = vim.fn.expand('~/.local/share/nvim/lazy/plenary.nvim')
vim.opt.runtimepath:append(plenary_path)

-- Add current directory to runtime path
vim.opt.runtimepath:append('.')

-- Load plenary
require('plenary.busted')