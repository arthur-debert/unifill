-- Search functionality for unifill

local format = require("unifill.format")
local log = require("unifill.log")

-- Helper function to check word matches in text
-- Returns:
-- 2: Exact word match (e.g., "right" matches "RIGHT" or "ARROW POINTING RIGHT")
-- 1: Word start match (e.g., "right" matches "RIGHTWARDS")
-- 0: No match
local function check_word_match(text, term)
    text = text:lower()
    term = term:lower()
    
    -- First check for a direct substring match in the full text
    if text:find(vim.pesc(term), 1, true) then
        return 1  -- Substring match
    end
    
    -- Split text into words
    for word in text:gmatch("[%w_]+") do
        -- Check for exact word match (highest priority)
        if word == term then
            return 2  -- Exact word match
        end
        -- Check for word-part match (lower priority)
        if word:find("^" .. vim.pesc(term)) then
            return 1  -- Word-part match
        end
    end
    
    return 0  -- No match
end

-- Score a match based on where terms are found
--
-- Scores matches based on two factors:
-- 1. Location priority: name > alias > category
-- 2. Match quality: exact word > word start
--
-- For each search term, finds the best match across all locations.
-- A term must match somewhere for the entry to be considered.
--
-- Scoring:
-- - Name matches: 1000000000000 points (any match quality)
-- - Alias matches: 1 point (exact word matches only)
-- - Category matches: 0.0001 points (exact word matches only)
--
-- Example:
-- Entry: { name = "RIGHTWARDS ARROW", aliases = {"FORWARD"} }
-- Terms: {"right"}
-- Result: 1000000000000 (word start match in name)
--
-- @param entry Table with name, category, and optional aliases
-- @param terms Array of search terms
-- @return Score, or 0 if any term doesn't match
local function score_match(entry, terms)
    local start_time = vim.loop.hrtime()
    log.debug("=== START SCORING ===")
    log.debug("Scoring entry: " .. (entry.name or "unknown"))
    log.debug("Terms: " .. vim.inspect(terms))
    
    if not entry or not entry.name or not entry.category then
        log.debug("Invalid entry structure:", vim.inspect(entry))
        return 0
    end

    local matched_terms = {}
    local total_score = 0
    local match_details = {}  -- Store details about where matches occurred

    -- Check each term
    for _, term in ipairs(terms) do
        local found = false
        local best_match = 0
        local location = "none"  -- none, category, alias, name
        
        -- Check name (highest priority)
        local name_match = check_word_match(entry.name, term)
        if name_match > 0 then
            -- Score based on match quality
            local name_score = name_match == 2
                and 1000000000000  -- Exact word match in name
                or 100000000000    -- Partial word match in name
            total_score = total_score + name_score
            found = true
            location = "name"
            match_details[term] = {
                location = "name",
                match_type = name_match == 2 and "exact" or "partial",
                text = entry.name,
                score = name_score
            }
            log.debug(string.format("Term '%s' matched in name: %s (score: %s, match_type: %s)",
                term, entry.name, name_score, name_match == 2 and "exact" or "partial"))
        end
        
        -- Check aliases (medium priority)
        if not found and entry.aliases then
            for _, alias in ipairs(entry.aliases) do
                local alias_match = check_word_match(alias, term)
                if alias_match > 0 then
                    -- Accept any match type for aliases, but score exact matches higher
                    local alias_score = alias_match == 2 and 10 or 1
                    total_score = total_score + alias_score
                    found = true
                    location = "alias"
                    match_details[term] = {
                        location = "alias",
                        match_type = alias_match == 2 and "exact" or "partial",
                        text = alias,
                        score = alias_score
                    }
                    log.debug(string.format("Term '%s' matched in alias: %s (score: %s, match_type: %s)",
                        term, alias, alias_score, alias_match == 2 and "exact" or "partial"))
                    break
                end
            end
        end
        
        -- Check category (lowest priority)
        if not found then
            local friendly_category = format.friendly_category(entry.category)
            local category_match = check_word_match(friendly_category, term)
            if category_match > 0 then  -- Accept any match type for category
                local category_score = category_match == 2 and 0.001 or 0.0001
                total_score = total_score + category_score
                found = true
                location = "category"
                match_details[term] = {
                    location = "category",
                    match_type = category_match == 2 and "exact" or "partial",
                    text = friendly_category,
                    score = category_score
                }
                log.debug(string.format("Term '%s' matched in category: %s (score: %s, match_type: %s)",
                    term, friendly_category, category_score, category_match == 2 and "exact" or "partial"))
            end
        end

        if found then
            matched_terms[term] = true
        else
            log.debug(string.format("Term '%s' not found in entry: %s",
                term, entry.name))
        end
    end

    -- Return 0 if not all terms matched
    if vim.tbl_count(matched_terms) < #terms then
        log.debug("Not all terms matched. Matched terms: " .. vim.inspect(matched_terms))
        log.debug("Match details: " .. vim.inspect(match_details))
        log.debug("=== END SCORING (FILTERED) ===")
        return 0
    end

    -- Calculate final score
    local final_score = total_score * vim.tbl_count(matched_terms)
    
    local end_time = vim.loop.hrtime()
    local search_time_ms = (end_time - start_time) / 1000000
    
    log.debug(string.format("Final score for '%s': %s (matched terms: %s, time: %.3f ms)",
        entry.name, final_score, vim.tbl_count(matched_terms), search_time_ms))
    log.debug("=== END SCORING (SCORE: " .. final_score .. ") ===")
    
    -- For significant searches (with multiple terms), log performance info
    if #terms > 1 and final_score > 0 then
        log.info(string.format("Search for '%s' in '%s' took %.3f ms (score: %s)",
            table.concat(terms, " "), entry.name, search_time_ms, final_score))
    end
    
    return final_score
end

return {
    check_word_match = check_word_match,
    score_match = score_match
}