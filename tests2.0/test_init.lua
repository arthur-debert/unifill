-- tests2.0/test_init.lua

-- Set up isolated test environment paths
local project_root = vim.fn.getcwd()
local test_data_path = project_root .. "/tmp/test-nvim/data"
local test_config_path = project_root .. "/tmp/test-nvim/config"
local test_cache_path = project_root .. "/tmp/test-nvim/cache"
local test_state_path = project_root .. "/tmp/test-nvim/state"

-- Create directories if they don't exist
vim.fn.mkdir(test_data_path, "p")
vim.fn.mkdir(test_config_path, "p")
vim.fn.mkdir(test_cache_path, "p")
vim.fn.mkdir(test_state_path, "p")

-- Override stdpath function to use our isolated paths
local original_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(what)
  if what == "data" then
    return test_data_path
  elseif what == "config" then
    return test_config_path
  elseif what == "cache" then
    return test_cache_path
  elseif what == "state" then
    return test_state_path
  else
    return original_stdpath(what)
  end
end

-- Set environment variables for testing
vim.env.PLENARY_TEST = "1"
vim.env.LOG_LEVEL = "error"  -- Minimize logging during tests
vim.env.UNIFILL_LOG_LEVEL = "error"  -- Minimize unifill logging during tests

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Create logs directory
local log_dir = test_cache_path .. '/logs'
vim.fn.mkdir(log_dir, 'p')

-- Add the project directory to runtimepath
vim.opt.runtimepath:append(project_root)

-- Bootstrap lazy.nvim
local lazypath = test_data_path .. "/lazy/lazy.nvim"
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
local plenary_path = test_data_path .. "/lazy/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.runtimepath:append(plenary_path)
end

local telescope_path = test_data_path .. "/lazy/telescope.nvim"
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