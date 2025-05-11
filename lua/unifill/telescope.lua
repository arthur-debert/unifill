-- Telescope integration for unifill

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require("telescope.pickers.entry_display")

local format = require("unifill.format")
local search = require("unifill.search")
local log = require("unifill.log")
local theme = require("unifill.theme")

-- Custom sorter for telescope
local function custom_sorter(opts)
    log.debug("Creating custom sorter with opts:", vim.inspect(opts))
    return require("telescope.sorters").Sorter:new {
        scoring_function = function(_, prompt, line, entry)
            local start_time = vim.loop.hrtime()
            log.debug("=== TELESCOPE SCORING START ===")
            log.debug("Prompt: '" .. prompt .. "'")
            
            -- Check if entry is nil
            if not entry or not entry.value then
                log.debug("ERROR: entry.value is nil")
                return -1
            end
            
            log.debug("Entry: " .. entry.value.name)
            
            if prompt == "" then
                log.debug("Empty prompt, returning default score")
                log.debug("=== TELESCOPE SCORING END (DEFAULT) ===")
                return 1
            end

            -- For telescope, convert our score to its convention (lower is better)
            local terms = vim.split(prompt, "%s+")
            log.debug("Raw split terms: " .. vim.inspect(terms))
            
            -- Skip empty terms
            local filtered_terms = {}
            for _, term in ipairs(terms) do
                if term and term:gsub("%s", "") ~= "" then
                    table.insert(filtered_terms, term)
                    log.debug("Added valid term: '" .. term .. "'")
                else
                    log.debug("Skipped empty term")
                end
            end
            
            log.debug("Filtered terms for search: " .. vim.inspect(filtered_terms))
            
            if #filtered_terms == 0 then
                log.debug("No valid search terms, showing all results")
                log.debug("=== TELESCOPE SCORING END (NO TERMS) ===")
                return 1
            end
            
            log.debug("Calling search.score_match with terms: " .. vim.inspect(filtered_terms))
            local test_score = search.score_match(entry.value, filtered_terms)
            log.debug("Raw score returned from search.score_match: " .. tostring(test_score))
            
            -- Convert score: 0 becomes -1 (filtered), higher becomes lower (better match)
            if test_score == 0 then
                log.debug("Entry filtered out: " .. entry.value.name)
                log.debug("=== TELESCOPE SCORING END (FILTERED) ===")
                return -1
            end
            
            -- Normalize the score for Telescope (lower is better)
            local final_score = 1 / (test_score + 0.0001) -- Avoid division by zero
            
            local end_time = vim.loop.hrtime()
            local scoring_time_ms = (end_time - start_time) / 1000000
            
            log.debug(string.format("Final telescope score for '%s': %s (original: %s, time: %.3f ms)",
                entry.value.name, final_score, test_score, scoring_time_ms))
            log.debug("=== TELESCOPE SCORING END (SCORE: " .. final_score .. ") ===")
            
            -- Log performance for complex queries
            if #filtered_terms > 1 and test_score > 0 then
                log.info(string.format("Telescope scoring for '%s' with query '%s' took %.3f ms",
                    entry.value.name, prompt, scoring_time_ms))
            end
            
            return final_score
        end,

        highlighter = opts.highlighter or function(_, prompt, display)
            -- Highlight matching terms with italic
            local highlights = {}
            local terms = vim.split(prompt:lower(), "%s+")
            local display_lower = display:lower()
            
            for _, term in ipairs(terms) do
                local pattern = "%f[%w_]" .. vim.pesc(term) .. "%f[^%w_]"
                local start = display_lower:find(pattern)
                if start then
                    table.insert(highlights, {
                        start = start,
                        finish = start + #term - 1,
                        hl_group = theme.highlights.match
                    })
                end
            end
            
            return highlights
        end
    }
end

-- Entry maker for telescope
local function entry_maker(entry)
    -- Skip control characters
    if entry.category == "Cc" or entry.category == "Cn" then
        log.debug("Skipping control character:", entry.name)
        return nil
    end

    -- Format the name and category
    local name = format.to_title_case(entry.name)
    local aliases = format.format_aliases(entry.aliases)
    local category = format.friendly_category(entry.category)
    
    -- Create a displayer with specific column widths
    local displayer = entry_display.create {
        separator = theme.ui.separator,
        items = {
            theme.ui.columns.character,
            theme.ui.columns.name,
            theme.ui.columns.details,
        },
    }
    
    -- Create display function that returns formatted text with highlights
    local display = function()
        return displayer {
            { entry.character, theme.highlights.character },
            { name, theme.highlights.name },
            { aliases .. " (" .. category .. ")", theme.highlights.details },
        }
    end

    log.debug(string.format("Created telescope entry for '%s'", entry.name))

    return {
        value = entry,
        display = display,
        ordinal = entry.name .. " " .. (entry.aliases and table.concat(entry.aliases, " ") or "")
    }
end

return {
    custom_sorter = custom_sorter,
    entry_maker = entry_maker
}