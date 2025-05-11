-- unifill is a vim plugin to insert unicode characters.
-- it leverages telescope, that is it's written as telescope extension.
-- we recommend the "<leader>+  iu" (insert unicode) :-), once that is pressed you get a telescope UI that can search unicode chars by the official name, any of it's common aliases and category, once selected the UI char will be inserted into your current buffer.

-- Import required modules
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local data = require("unifill.data")
local format = require("unifill.format")
local telescope_utils = require("unifill.telescope")
local log = require("unifill.log")

log.info("Unifill plugin initialized")

-- Main picker function
local function unifill(opts)
    log.debug("Unifill picker called with opts:", opts)
    opts = opts or {}

    local unicode_data = data.load_unicode_data()
    if not unicode_data then
        log.error("Failed to load Unicode data")
        vim.notify("Failed to load Unicode data", vim.log.levels.ERROR)
        return
    end
    log.info("Unicode data loaded successfully")

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
                -- Insert the unicode character at cursor
                vim.api.nvim_put({ selection.value.character }, "", false, true)
            end)
            return true
        end,
    }):find()
end

-- Set up the key mapping
vim.keymap.set('n', '<leader>fu', unifill, { noremap = true, silent = true })

-- Return the module
return {
    unifill = unifill,
    log = require("unifill.log"),  -- Re-export the logger for API compatibility
    _test = {
        load_unicode_data = data.load_unicode_data,
        entry_maker = telescope_utils.entry_maker,
        to_title_case = format.to_title_case,
        format_aliases = format.format_aliases,
        friendly_category = format.friendly_category,
        score_match = require("unifill.search").score_match
    }
}