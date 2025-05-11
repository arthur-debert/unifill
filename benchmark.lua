-- Benchmark script for unifill backends
-- This script loads both backends and measures their performance

-- Set log level to INFO to see benchmark results
vim.env.UNIFILL_LOG_LEVEL = "info"

-- Load the unifill plugin
local unifill = require("unifill")
local data_manager = require("unifill.data")

-- Create a log file
local log_file = io.open("benchmark_results.txt", "w")
if not log_file then
    print("Error: Could not create benchmark_results.txt")
    return
end

-- Helper function to write to log file
local function log(msg)
    print(msg)
    log_file:write(msg .. "\n")
end

-- Benchmark function
local function benchmark_backend(backend_name, search_terms)
    log("\n=== Benchmarking " .. backend_name .. " backend ===\n")
    
    -- Configure the backend
    unifill.setup({
        backend = backend_name
    })
    
    -- Measure data loading time
    local start_time = vim.loop.hrtime()
    local data = data_manager.load_unicode_data()
    local end_time = vim.loop.hrtime()
    local load_time_ms = (end_time - start_time) / 1000000
    
    log(string.format("Data loading time: %.2f ms", load_time_ms))
    log(string.format("Number of entries: %d", #data))
    
    -- Measure search time for different terms
    log("\nSearch performance:")
    
    for _, terms in ipairs(search_terms) do
        local term_str = table.concat(terms, " ")
        log("\nSearching for: '" .. term_str .. "'")
        
        local matches = 0
        local total_search_time = 0
        
        -- Search through all entries
        for _, entry in ipairs(data) do
            local start_time = vim.loop.hrtime()
            local score = require("unifill.search").score_match(entry, terms)
            local end_time = vim.loop.hrtime()
            
            if score > 0 then
                matches = matches + 1
                total_search_time = total_search_time + (end_time - start_time)
            end
        end
        
        local avg_search_time_ms = matches > 0 and (total_search_time / matches) / 1000000 or 0
        log(string.format("  Matches found: %d", matches))
        log(string.format("  Average search time per match: %.3f ms", avg_search_time_ms))
    end
end

-- Define search terms for benchmarking
local search_terms = {
    { "arrow" },
    { "right", "arrow" },
    { "mathematical", "symbol" },
    { "latin", "letter", "small" }
}

-- Run benchmarks for both backends
benchmark_backend("lua", search_terms)
benchmark_backend("csv", search_terms)

-- Close log file
log_file:close()

print("\nBenchmark completed. Results saved to benchmark_results.txt")