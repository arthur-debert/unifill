unifill
-------

    unifill is a vim plugin to insert unicode characters.
    It's written as a telescope extension, which pretty much handles 100% of the UI. :)

    We recommend the "<leader>+  iu" (insert unicode) mapping. Once pressed, you get a 
    telescope UI that can search unicode chars by the official name, any of its common 
    aliases and category. Once selected, the unicode char will be inserted into your 
    current buffer.
→

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

4. UI Customization

    4.1 Theming

        The plugin now uses a centralized theme configuration for consistent UI styling.
        The theme provides:
        
        - Dropdown layout with 40% screen width/height
        - Bold, 100% black Unicode characters with increased width
        - 80% black text for other content
        - Italic formatting for matched text
        
        All UI options are centralized in the theme.lua file, making it easy to customize
        the appearance to your preferences.
        
    4.2 Custom Configuration
    
        If you want to customize the UI, you can modify the theme settings in your
        configuration:
        
        ---
        local unifill = require('unifill')
        local theme = require('unifill.theme')
        
        -- Customize UI layout
        theme.ui.layout.width = 0.5  -- 50% of screen width
        theme.ui.layout.height = 0.6  -- 60% of screen height
        
        -- Customize highlight groups
        vim.api.nvim_command('highlight UnifillCharacter guifg=#FF5555 gui=bold')
        vim.api.nvim_command('highlight UnifillName guifg=#888888')
        
        -- Set up key mapping
        vim.keymap.set('n', '<leader>iu', unifill.unifill,
            { desc = 'Insert Unicode character' })
        ---  lua
