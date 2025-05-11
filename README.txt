unifill
-------

    unifill is a vim plugin to insert unicode characters.
    It's written as a telescope extension, which pretty much handles 100% of the UI. :)

    We recommend the "<leader>+  iu" (insert unicode) mapping. Once pressed, you get a 
    telescope UI that can search unicode chars by the official name, any of its common 
    aliases and category. Once selected, the unicode char will be inserted into your 
    current buffer.


1. Installing
    
    Install with your favorite plugin manager. For example, with lazy.nvim:

        --- 
        {
        "arthur-debert/unifill",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim", -- required for testing
        },
        config = function()
            -- Optional: set up key mappings
            vim.keymap.set('n', '<leader>iu', require('unifill').unifill, 
            { desc = 'Insert Unicode character' })
        end
        }
    ---  lua


2. Dataset

    The plugin uses a database of unicode code points, names, categories and common 
    aliases. This is a largish file, at 5MB, but gets unloaded after execution.

    As an optimization, we're saving the data as a lua file, which makes the plugin 
    code much simpler. It's a lookup table, and should be faster to run.

    The dataset can be generated automatically by running:

        --
            bin/fetch-data

        --  bash

    This executes unifill-datafetch/src/setup_dataset.py. It will create a .venv and 
    Install deps in the unifill-datafetch directory.


3. Development
    
    3.1 Testing

        The plugin uses plenary.nvim for testing. To run the test suite:

        1. Make sure plenary.nvim is installed
        2. Run `bin/run-tests` from the project root

        Tests are located in the spec/ directory and use the plenary test format.

    3.2 Continuous Integration

        Tests are automatically run on every push and pull request using GitHub Actions.
        
        The workflow:
        
            - Sets up Neovim
            - Installs required plugins
            - Runs the test suite
