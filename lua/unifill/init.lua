-- unifill is a vim plugin to insert unicode characters.
-- it leverages telescope, that is it's written as telescope extension.
-- we recommend the "<leader>+  iu" (insert unicode) :-), once that is pressed you get a telescope UI that can search unicode chars by the official name, any of it's common aliases and category, once selected the UI char will be inserted into your current buffer.

-- Import required modules
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local themes = require "telescope.themes"

local data = require("unifill.data")
local format = require("unifill.format")
local telescope_utils = require("unifill.telescope")
local theme = require("unifill.theme")
local log = require("unifill.log")

-- Log initialization silently
log.debug("Unifill plugin initialized")

-- Set up the theme
theme.setup()

-- Main picker function
local function unifill(opts)
    log.debug("Unifill picker called with opts:", opts)
    opts = opts or {}
    
    -- Apply dropdown theme with custom sizing
    opts = themes.get_dropdown(theme.ui.layout)

    local unicode_data = data.load_unicode_data()
    if not unicode_data then
        log.error("Failed to load Unicode data")
        vim.notify("Failed to load Unicode data", vim.log.levels.ERROR)
        return
    end
    log.info("Unicode data loaded successfully")

    -- Add backend name to opts for sorter selection
    opts.backend = data.get_backend_name()
    
    pickers.new(opts, {
        prompt_title = "Unicode Characters",
        finder = finders.new_table {
            results = unicode_data,
            entry_maker = telescope_utils.entry_maker
        },
        sorter = telescope_utils.custom_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                log.info("Character selected:", selection.value.character,
                    "Name:", selection.value.name)
                -- Check if the current buffer is modifiable
                if vim.api.nvim_buf_get_option(0, 'modifiable') then
                    -- Insert the unicode character at cursor
                    vim.api.nvim_put({ selection.value.character }, "", false, true)
                else
                    -- Show an error message if the buffer is not modifiable
                    vim.notify("Cannot insert character in a non-modifiable buffer", vim.log.levels.ERROR)
                    log.error("Attempted to insert character in a non-modifiable buffer")
                end
            end)
            return true
        end,
    }):find()
end

-- Set up the key mapping
vim.keymap.set('n', '<leader>fu', unifill, { noremap = true, silent = true })

-- Return the module
return {
    -- Main picker function
    unifill = unifill,
    
    -- Setup function for configuration
    -- @param config Table with configuration options:
    -- {
    --   backend = "lua",  -- Data backend to use: "lua" (default) or "csv"
    --   backends = {
    --     lua = {
    --       data_path = nil  -- Optional custom path to lua data file
    --     },
    --     csv = {
    --       data_path = nil  -- Optional custom path to csv data file
    --     }
    --   }
    -- }
    --
    -- Benchmark results (why lua is the default backend):
    -- - Data loading: lua=77ms vs csv=225ms (lua is ~3x faster)
    -- - Search performance: lua is generally faster, especially for complex queries
    --   - Simple search "arrow": lua=0.003ms vs csv=0.007ms per match
    --   - Complex search "right arrow": lua=0.092ms vs csv=0.344ms per match
    --
    -- The CSV backend is provided for easier inspection and modification of the dataset.
    -- To generate both data formats, run: bin/fetch-data --format all
    setup = function(config)
        return data.setup(config)
    end,
    
    -- Re-export the logger for API compatibility
    log = require("unifill.log"),
    
    -- Test exports
    _test = {
        load_unicode_data = data.load_unicode_data,
        entry_maker = telescope_utils.entry_maker,
        to_title_case = format.to_title_case,
        format_aliases = format.format_aliases,
        friendly_category = format.friendly_category,
        score_match = require("unifill.search").score_match
    }
}