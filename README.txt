u#nifill
-------

    unifill is a vim plugin to insert unicode characters.
    It's written as a telescope extension, which pretty much handles 100% of the UI. :)

    We recommend the "<leader>+  iu" (insert unicode) mapping. Once pressed, you get a 
    telescope UI that can search unicode chars by the official name, any of its common 
    aliases and category. Once selected, the unicode char will be inserted into your 
    current buffer.
→

1. Installing
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
                -- Configure the plugin (optional)
                local unifill = require('unifill')
                unifill.setup({
                    -- Use default configuration
                    -- See section 2.1 for backend configuration options
                })
                
                -- Set up key mappings
                vim.keymap.set('n', '<leader>iu', unifill.unifill,
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
            bin/gen-datasets

        --  bash

    This executes glyph-catcher/src/setup_dataset.py. It will create a .venv and
    install deps in the glyph-catcher directory.
    
2.1 File Locations

    The plugin follows the XDG Base Directory Specification for storing files:
    
    - Dataset files:
      - Primary: Plugin's data directory (for local development)
      - System-wide: $XDG_DATA_HOME/unifill/ (typically ~/.local/share/unifill/)
    
    - Source Unicode files:
      - $XDG_DATA_HOME/glyph-catcher/source-files/ (typically ~/.local/share/glyph-catcher/source-files/)
    
    - Master data file:
      - $XDG_DATA_HOME/glyph-catcher/ (typically ~/.local/share/glyph-catcher/)
    
    - Cache files:
      - $XDG_CACHE_HOME/glyph-catcher/ (typically ~/.cache/glyph-catcher/)
    
    - Log files:
      - $XDG_CACHE_HOME/unifill/logs/ (typically ~/.cache/unifill/logs/)
    
    - Temporary files:
      - System temporary directory (via tempfile.gettempdir())

2.1 Data Backends

    The plugin now supports configurable data backends. You can choose between:
    
    - Lua backend (default): Uses a Lua table for fast loading and searching
    - CSV backend: Uses a CSV file, which may be easier to inspect or modify
    - Grep backend: Uses external grep tools for ultra-fast initialization
    - Fast Grep backend: Optimized grep backend with minimal Lua processing

    You can configure the data backend using the setup function:

        ---
        require('unifill').setup({
            backend = "lua",  -- Use "lua", "csv", or "grep"
            backends = {
                lua = {
                    data_path = "/path/to/your/unicode_data.lua"  -- Optional custom path
                },
                csv = {
                    data_path = "/path/to/your/unicode_data.csv"  -- Optional custom path
                },
                grep = {
                    data_path = "/path/to/your/unicode_data.txt",  -- Optional custom path
                    grep_command = "rg"  -- Command to use for grep (default: "rg" for ripgrep)
                },
                fast_grep = {
                    data_path = "/path/to/your/unicode_data.txt",  -- Optional custom path
                    grep_command = "rg"  -- Command to use for grep (default: "rg" for ripgrep)
                }
            }
        })
        ---  lua

    The default configuration will use the Lua backend with the dataset located at
    the standard path in the plugin directory.
    
    You can generate all data formats by running:
    
        --
            bin/gen-datasets --format all
        --  bash
    
    This will create the Lua, CSV, and TXT versions of the dataset.
|
    2.1.1 Backend Comparison
|
    Each backend has different performance characteristics:
|
    - Lua: Fast searching (~0.1ms), moderate initialization time (~70-320ms)
    - CSV: Fast searching (~0.1ms), moderate initialization time (~180-225ms)
    - Grep: Slower searching (~8-35ms), very fast initialization (~1-3ms)
    - Fast Grep: Improved searching (~6-7ms), fast initialization (~7ms)
|
    The grep backend is ideal for situations where you need to start up quickly
    and don't search frequently. The fast_grep backend provides a good balance
    between initialization speed and search performance. For more details on the
    grep backends, see dev/guides/grep-backend.md.


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
            
    3.3 File Locations
    
        The plugin follows XDG Base Directory Specification for storing files:
        
        - Log files: $XDG_CACHE_HOME/unifill/logs/unifill.log (typically ~/.cache/unifill/logs/)
        - Data files: $XDG_DATA_HOME/unifill/ (typically ~/.local/share/unifill/)
        - Cache files: $XDG_CACHE_HOME/unifill/ (typically ~/.cache/unifill/)
        - Temporary files: System temporary directory (via os.tmpname())
        
        This ensures that the plugin respects system conventions and doesn't clutter
        the user's home directory with temporary or cache files.

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
