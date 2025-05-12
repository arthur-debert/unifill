-- Benchmark script for unifill backends
-- This script loads all backends and measures their performance for different datasets

-- Set log level to ERROR to avoid excessive logging
vim.env.UNIFILL_LOG_LEVEL = "error"

-- Check if telescope is available
local has_telescope = pcall(require, "telescope.pickers")
if not has_telescope then
    -- Mock telescope modules for headless mode
    package.loaded["telescope.pickers"] = {}
    package.loaded["telescope.finders"] = {}
    package.loaded["telescope.sorters"] = {
        get_fzy_sorter = function() return {} end
    }
end

-- Load the unifill plugin
local unifill = require("unifill")
local data_manager = require("unifill.data")
local constants = require("unifill.constants")

-- Create a log file
local log_file = io.open("benchmark_results.txt", "w")
if not log_file then
    print("Error: Could not create benchmark_results.txt")
    return
end

-- Table to store all benchmark results
local all_benchmark_results = {}

-- Initialize results structure for a specific dataset
local function init_benchmark_results(dataset)
    return {
        dataset = dataset,
        backends = {
            lua = { name = "lua", load_time = 0, entries = 0, searches = {} },
            csv = { name = "csv", load_time = 0, entries = 0, searches = {} },
            grep = { name = "grep", init_time = 0, searches = {} },
            fast_grep = { name = "fast_grep", init_time = 0, searches = {} }
        }
    }
end

-- Helper function to write to log file
local function log(msg)
    log_file:write(msg .. "\n")
end

-- Helper function to format a table with aligned columns
local function format_table(headers, rows)
    -- Calculate column widths
    local col_widths = {}
    for i, header in ipairs(headers) do
        col_widths[i] = #header
    end
    
    for _, row in ipairs(rows) do
        for i, cell in ipairs(row) do
            col_widths[i] = math.max(col_widths[i], #tostring(cell))
        end
    end
    
    -- Format headers
    local header_line = ""
    local separator_line = ""
    for i, header in ipairs(headers) do
        header_line = header_line .. string.format("%-" .. col_widths[i] + 2 .. "s", header)
        separator_line = separator_line .. string.rep("-", col_widths[i]) .. "  "
    end
    
    -- Format rows
    local result = {header_line, separator_line}
    for _, row in ipairs(rows) do
        local line = ""
        for i, cell in ipairs(row) do
            line = line .. string.format("%-" .. col_widths[i] + 2 .. "s", tostring(cell))
        end
        table.insert(result, line)
    end
    
    return table.concat(result, "\n")
end

-- Benchmark function
-- Benchmark function for standard backends (lua, csv)
local function benchmark_standard_backend(benchmark_results, backend_name, search_terms, dataset)
    -- Get the plugin root directory
    local plugin_root = require("unifill.data").get_plugin_root()
    
    -- Configure the backend with the specified dataset and explicit data paths
    local config = {
        backend = backend_name,
        dataset = dataset,
        backends = {
            lua = {
                data_path = plugin_root .. "/data/unicode." .. dataset .. ".lua"
            },
            csv = {
                data_path = plugin_root .. "/data/unicode." .. dataset .. ".csv"
            },
            grep = {
                data_path = plugin_root .. "/data/unicode." .. dataset .. ".txt"
            },
            fast_grep = {
                data_path = plugin_root .. "/data/unicode." .. dataset .. ".txt"
            }
        }
    }
    
    -- Log the configuration
    log(string.format("\nConfiguring %s backend with dataset: %s", backend_name, dataset))
    log(string.format("Data path: %s", config.backends[backend_name].data_path))
    
    -- Apply the configuration
    unifill.setup(config)
    
    -- Get the actual configuration used
    local actual_config = require("unifill.data").get_config()
    log(string.format("Actual dataset being used: %s", actual_config.dataset))
    log(string.format("Actual data path: %s", actual_config.backends[backend_name].data_path))
    
    -- Measure data loading time
    local start_time = vim.loop.hrtime()
    local data = data_manager.load_unicode_data()
    local end_time = vim.loop.hrtime()
    local load_time_ms = (end_time - start_time) / 1000000
    
    -- Store results
    benchmark_results.backends[backend_name].load_time = load_time_ms
    benchmark_results.backends[backend_name].entries = #data
    
    -- Log for file
    log(string.format("\n=== Benchmarking %s backend with %s dataset ===\n", backend_name, dataset))
    log(string.format("Data loading time: %.2f ms", load_time_ms))
    log(string.format("Number of entries: %d", #data))
    log("\nSearch performance:")
    
    -- Measure search time for different terms
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
        
        -- Store results
        table.insert(benchmark_results.backends[backend_name].searches, {
            terms = term_str,
            matches = matches,
            time = avg_search_time_ms,
            type = "avg_per_match"
        })
        
        -- Log for file
        log(string.format("  Matches found: %d", matches))
        log(string.format("  Average search time per match: %.3f ms", avg_search_time_ms))
    end
end

-- Benchmark function for grep backend
local function benchmark_grep_backend(benchmark_results, backend_name, search_terms, dataset)
    -- Get the plugin root directory
    local plugin_root = require("unifill.data").get_plugin_root()
    
    -- Configure the backend with the specified dataset and explicit data paths
    local config = {
        backend = backend_name,
        dataset = dataset,
        backends = {
            lua = {
                data_path = plugin_root .. "/data/unicode." .. dataset .. ".lua"
            },
            csv = {
                data_path = plugin_root .. "/data/unicode." .. dataset .. ".csv"
            },
            grep = {
                data_path = plugin_root .. "/data/unicode." .. dataset .. ".txt"
            },
            fast_grep = {
                data_path = plugin_root .. "/data/unicode." .. dataset .. ".txt"
            }
        }
    }
    
    -- Log the configuration
    log(string.format("\nConfiguring %s backend with dataset: %s", backend_name, dataset))
    log(string.format("Data path: %s", config.backends[backend_name].data_path))
    
    -- Apply the configuration
    unifill.setup(config)
    
    -- Get the actual configuration used
    local actual_config = require("unifill.data").get_config()
    log(string.format("Actual dataset being used: %s", actual_config.dataset))
    log(string.format("Actual data path: %s", actual_config.backends[backend_name].data_path))
    
    -- Measure initialization time
    local start_time = vim.loop.hrtime()
    local backend_module = backend_name == "grep"
        and require("unifill.backends.grep_backend")
        or require("unifill.backends.fast_grep_backend")
    local backend = backend_module.new(require("unifill.data").get_config().backends[backend_name])
    local end_time = vim.loop.hrtime()
    local init_time_ms = (end_time - start_time) / 1000000
    
    -- Store results
    benchmark_results.backends[backend_name].init_time = init_time_ms
    
    -- Log for file
    log(string.format("\n=== Benchmarking %s backend with %s dataset ===\n", backend_name, dataset))
    log(string.format("Backend initialization time: %.2f ms", init_time_ms))
    log("\nSearch performance:")
    
    -- Measure search time for different terms
    for _, terms in ipairs(search_terms) do
        local term_str = table.concat(terms, " ")
        log("\nSearching for: '" .. term_str .. "'")
        
        -- Measure grep command execution time
        local start_time = vim.loop.hrtime()
        
        -- Execute grep command and count results
        local cmd = backend:create_command_generator(term_str)
        if not cmd then
            log("  Error: Failed to create grep command")
            goto continue
        end
        
        -- Build the command string
        local command_args = {}
        for _, arg in ipairs(cmd.args) do
            table.insert(command_args, "'" .. arg:gsub("'", "\\'") .. "'")
        end
        local command = cmd.command .. " " .. table.concat(command_args, " ")
        
        -- Execute the command and count the results
        local handle = io.popen(command .. " | wc -l")
        if not handle then
            log("  Error: Failed to execute grep command")
            goto continue
        end
        
        local result = handle:read("*a")
        handle:close()
        
        local matches = tonumber(result:match("%d+")) or 0
        
        local end_time = vim.loop.hrtime()
        local search_time_ms = (end_time - start_time) / 1000000
        
        -- Store results
        local search_result = {
            terms = term_str,
            matches = matches,
            time = search_time_ms,
            type = "total",
            individual_matches = {}
        }
        
        -- For multi-word searches, also try individual words to compare
        if #terms > 1 then
            log(string.format("  Matches found (exact phrase): %d", matches))
            
            -- Try searching for individual words
            for _, term in ipairs(terms) do
                local term_cmd = backend:create_command_generator(term)
                if term_cmd then
                    local term_args = {}
                    for _, arg in ipairs(term_cmd.args) do
                        table.insert(term_args, "'" .. arg:gsub("'", "\\'") .. "'")
                    end
                    local term_command = term_cmd.command .. " " .. table.concat(term_args, " ")
                    
                    local term_handle = io.popen(term_command .. " | wc -l")
                    if term_handle then
                        local term_result = term_handle:read("*a")
                        term_handle:close()
                        local term_matches = tonumber(term_result:match("%d+")) or 0
                        
                        -- Store individual word results
                        table.insert(search_result.individual_matches, {term = term, matches = term_matches})
                        
                        -- Log for file
                        log(string.format("  Matches for '%s': %d", term, term_matches))
                    end
                end
            end
        else
            log(string.format("  Matches found: %d", matches))
        end
        
        -- Add to results
        table.insert(benchmark_results.backends[backend_name].searches, search_result)
        
        -- Log for file
        log(string.format("  Total search time: %.3f ms", search_time_ms))
        
        ::continue::
    end
end

-- Function to run benchmarks for a specific dataset
local function run_benchmarks_for_dataset(dataset, search_terms)
    log(string.format("\n\n========== BENCHMARKING %s DATASET ==========\n", dataset:upper()))
    
    -- Initialize results for this dataset
    local benchmark_results = init_benchmark_results(dataset)
    
    -- Run benchmarks for all backends with this dataset
    benchmark_standard_backend(benchmark_results, "lua", search_terms, dataset)
    benchmark_standard_backend(benchmark_results, "csv", search_terms, dataset)
    benchmark_grep_backend(benchmark_results, "grep", search_terms, dataset)
    benchmark_grep_backend(benchmark_results, "fast_grep", search_terms, dataset)
    
    -- Add results to the all_benchmark_results table
    table.insert(all_benchmark_results, benchmark_results)
    
    return benchmark_results
end

-- Define search terms for benchmarking
local search_terms = {
    { "arrow" },
    { "right", "arrow" },
    { "mathematical", "symbol" },
    { "latin", "letter", "small" }
}

-- Run benchmarks for both datasets
local everyday_results = run_benchmarks_for_dataset(constants.DATASET.EVERYDAY, search_terms)
local complete_results = run_benchmarks_for_dataset(constants.DATASET.COMPLETE, search_terms)

-- Format and display results in tables for the log file
log("\n\n================ BENCHMARK RESULTS SUMMARY ================\n")

-- Helper function to format results for a specific dataset
local function format_dataset_results(benchmark_results)
    -- Create a combined table with backends as rows and search terms as columns
    local search_terms_list = {}
    for _, terms in ipairs(search_terms) do
        table.insert(search_terms_list, table.concat(terms, " "))
    end
    
    -- Calculate median search times for each backend
    local function calculate_median(times)
        if #times == 0 then
            return 0
        end
        
        table.sort(times)
        if #times % 2 == 0 then
            return (times[#times/2] + times[#times/2 + 1]) / 2
        else
            return times[math.ceil(#times/2)]
        end
    end
    
    local lua_search_times = {}
    local csv_search_times = {}
    local grep_search_times = {}
    local fast_grep_search_times = {}
    
    for _, search in ipairs(benchmark_results.backends.lua.searches) do
        table.insert(lua_search_times, search.time)
    end
    
    for _, search in ipairs(benchmark_results.backends.csv.searches) do
        table.insert(csv_search_times, search.time)
    end
    
    for _, search in ipairs(benchmark_results.backends.grep.searches) do
        table.insert(grep_search_times, search.time)
    end
    
    for _, search in ipairs(benchmark_results.backends.fast_grep.searches) do
        table.insert(fast_grep_search_times, search.time)
    end
    
    local lua_median = calculate_median(lua_search_times)
    local csv_median = calculate_median(csv_search_times)
    local grep_median = calculate_median(grep_search_times)
    local fast_grep_median = calculate_median(fast_grep_search_times)
    
    -- Create headers: Backend, Init Time, Search Term 1, Search Term 2, etc., Median
    local headers = {"Backend", "Init Time", "Entries"}
    for _, term in ipairs(search_terms_list) do
        table.insert(headers, term)
    end
    table.insert(headers, "Median Time")
    
    -- Create rows for each backend
    local rows = {}
    
    -- Helper function to find search result for a specific backend and term
    local function find_search_result(backend_name, term)
        for _, search in ipairs(benchmark_results.backends[backend_name].searches) do
            if search.terms == term then
                if backend_name == "grep" or backend_name == "fast_grep" then
                    local match_info = search.matches
                    if #search.individual_matches > 0 then
                        match_info = search.matches .. " (exact)"
                    end
                    -- Format search time with 2 integer places and 2 decimal places
                    return string.format("%s / %5.2f ms", tostring(match_info), search.time)
                else
                    -- Format search time with 2 integer places and 2 decimal places
                    return string.format("%d / %5.2f ms", search.matches, search.time)
                end
            end
        end
        return "N/A"
    end
    
    -- Lua backend row
    local lua_row = {"lua", string.format("%7.2f ms", benchmark_results.backends.lua.load_time), benchmark_results.backends.lua.entries}
    for _, term in ipairs(search_terms_list) do
        table.insert(lua_row, find_search_result("lua", term))
    end
    table.insert(lua_row, string.format("%5.2f ms", lua_median))
    table.insert(rows, lua_row)
    
    -- CSV backend row
    local csv_row = {"csv", string.format("%7.2f ms", benchmark_results.backends.csv.load_time), benchmark_results.backends.csv.entries}
    for _, term in ipairs(search_terms_list) do
        table.insert(csv_row, find_search_result("csv", term))
    end
    table.insert(csv_row, string.format("%5.2f ms", csv_median))
    table.insert(rows, csv_row)
    
    -- Grep backend row
    local grep_row = {"grep", string.format("%7.2f ms", benchmark_results.backends.grep.init_time), "N/A"}
    for _, term in ipairs(search_terms_list) do
        table.insert(grep_row, find_search_result("grep", term))
    end
    table.insert(grep_row, string.format("%5.2f ms", grep_median))
    table.insert(rows, grep_row)
    
    -- Fast Grep backend row
    local fast_grep_row = {"fast_grep", string.format("%7.2f ms", benchmark_results.backends.fast_grep.init_time), "N/A"}
    for _, term in ipairs(search_terms_list) do
        table.insert(fast_grep_row, find_search_result("fast_grep", term))
    end
    table.insert(fast_grep_row, string.format("%5.2f ms", fast_grep_median))
    table.insert(rows, fast_grep_row)
    
    return headers, rows
end

-- Format and output results for each dataset
log(string.format("\n=== %s Dataset Results ===\n", everyday_results.dataset:upper()))
local everyday_headers, everyday_rows = format_dataset_results(everyday_results)
log(format_table(everyday_headers, everyday_rows))

log(string.format("\n\n=== %s Dataset Results ===\n", complete_results.dataset:upper()))
local complete_headers, complete_rows = format_dataset_results(complete_results)
log(format_table(complete_headers, complete_rows))

-- Close log file
log_file:close()

-- Exit Vim
vim.cmd("qa!")