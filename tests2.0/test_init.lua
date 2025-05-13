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
  -- Unifill plugin (local)
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

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
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
})

-- Load plenary for testing
require('plenary.busted')

-- Clear any cached modules to ensure clean test environment
package.loaded['unifill'] = nil
package.loaded['unifill.data'] = nil
package.loaded['unifill.format'] = nil
package.loaded['unifill.search'] = nil
package.loaded['unifill.telescope'] = nil
package.loaded['unifill.log'] = nil
package.loaded['unifill.theme'] = nil