-- tests2.0/test_init.lua
-- Set environment variables for testing
vim.env.PLENARY_TEST = "1"
vim.env.LOG_LEVEL = "error"  -- Minimize logging during tests
vim.env.UNIFILL_LOG_LEVEL = "error"  -- Minimize unifill logging during tests

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Create logs directory
local log_dir = vim.fn.stdpath('cache') .. '/logs'
vim.fn.mkdir(log_dir, 'p')

-- Add the project directory to runtimepath
local project_root = vim.fn.getcwd()
vim.opt.runtimepath:append(project_root)

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

-- Configure lazy.nvim with unifill plugin and its dependencies
require("lazy").setup({
  -- Dependencies first to ensure they're loaded before unifill
  {
    "nvim-lua/plenary.nvim",
    priority = 1000, -- Load this first
  },
  
  {
    "nvim-telescope/telescope.nvim",
    priority = 900, -- Load this second
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require('telescope').setup({
        defaults = {
          -- Telescope configuration for testing
          layout_strategy = "horizontal",
          layout_config = {
            width = 0.8,
            height = 0.8,
          },
        },
      })
    end,
  },
  
  -- Unifill plugin (local) - load after dependencies
  {
    dir = project_root,
    name = "unifill",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      -- Configure unifill for testing
      require('unifill').setup({
        -- Test configuration
        backend = "lua",
        dataset = "every-day",
        results_limit = 50,
      })
    end,
  },
})

-- Manually load dependencies
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.runtimepath:append(plenary_path)
end

local telescope_path = vim.fn.stdpath("data") .. "/lazy/telescope.nvim"
if vim.fn.isdirectory(telescope_path) == 1 then
  vim.opt.runtimepath:append(telescope_path)
end

-- Load plenary for testing
pcall(require, 'plenary.busted')

-- Clear any cached modules to ensure clean test environment
package.loaded['unifill'] = nil
package.loaded['unifill.data'] = nil
package.loaded['unifill.format'] = nil
package.loaded['unifill.search'] = nil
package.loaded['unifill.telescope'] = nil
package.loaded['unifill.log'] = nil
package.loaded['unifill.theme'] = nil