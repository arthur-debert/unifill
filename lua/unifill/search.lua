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
    
    -- Split text into words
    local words = {}
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
    log.debug("Scoring match for terms:", vim.inspect(terms))
    
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
                    -- Only count exact word matches in aliases
                    if alias_match == 2 then
                        total_score = total_score + 1  -- Much lower score for alias matches
                        found = true
                        location = "alias"
                        match_details[term] = {
                            location = "alias",
                            match_type = "exact",
                            text = alias
                        }
                        log.debug(string.format("Term '%s' matched in alias: %s (score: 1)",
                            term, alias))
                        break
                    end
                end
            end
        end
        
        -- Check category (lowest priority)
        if not found then
            local friendly_category = format.friendly_category(entry.category)
            local category_match = check_word_match(friendly_category, term)
            if category_match == 2 then  -- Only count exact word matches in category
                total_score = total_score + 0.0001  -- Lowest score for category matches
                found = true
                location = "category"
                match_details[term] = {
                    location = "category",
                    match_type = "exact",
                    text = friendly_category
                }
                log.debug(string.format("Term '%s' matched in category: %s (score: 0.0001)",
                    term, friendly_category))
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
        log.debug("Not all terms matched. Matched terms:", vim.inspect(match_details))
        return 0
    end

    -- Calculate final score
    local final_score = total_score * vim.tbl_count(matched_terms)
    log.debug(string.format("Final score for '%s': %s (matched terms: %s)",
        entry.name, final_score, vim.tbl_count(matched_terms)))
    
    return final_score
end

return {
    check_word_match = check_word_match,
    score_match = score_match
}