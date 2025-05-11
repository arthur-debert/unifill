-- Add plugin paths
local plenary_path = vim.fn.expand('~/.local/share/nvim/lazy/plenary.nvim')
vim.opt.runtimepath:append(plenary_path)

-- Add current directory to runtime path
vim.opt.runtimepath:append('.')

-- Set test environment variable
vim.env.PLENARY_TEST = "1"
vim.env.UNIFILL_LOG_LEVEL = "error"  -- Minimize logging during tests

-- Create test cache directory
local cache_dir = vim.fn.stdpath('cache')
vim.fn.mkdir(cache_dir, 'p')

-- Clear any cached modules to ensure clean test environment
package.loaded['unifill'] = nil
package.loaded['unifill.data'] = nil
package.loaded['unifill.format'] = nil
package.loaded['unifill.search'] = nil
package.loaded['unifill.telescope'] = nil

-- Load plenary
require('plenary.busted')