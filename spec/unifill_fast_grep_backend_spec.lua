-- spec/unifill_fast_grep_backend_spec.lua
-- Tests for the fast grep backend implementation
-- This file contains tests for the optimized grep backend that minimizes Lua processing

describe("unifill fast grep backend", function()
    local FastGrepBackend
    
    before_each(function()
        -- Clear module cache
        package.loaded['unifill.backends.fast_grep_backend'] = nil
        
        -- Load the fast grep backend
        FastGrepBackend = require("unifill.backends.fast_grep_backend")
    end)
    
    after_each(function()
        -- Clear module cache
        package.loaded['unifill.backends.fast_grep_backend'] = nil
    end)
    
    -- Test that the backend can be created with default configuration
    it("can be instantiated", function()
        local backend = FastGrepBackend.new()
        assert(backend ~= nil, "backend should not be nil")
    end)
    
    -- Test that the backend returns the expected entry structure definition
    it("returns the correct entry structure", function()
        local backend = FastGrepBackend.new()
        local structure = backend:get_entry_structure()
        
        assert(structure ~= nil, "structure should not be nil")
        assert(structure.name == "string", "name should be a string")
        assert(structure.character == "string", "character should be a string")
        assert(structure.code_point == "string", "code_point should be a string")
        assert(structure.category == "string", "category should be a string")
        assert(structure.aliases == "table", "aliases should be a table")
    end)
    
    -- Test that the backend can make entries from grep output lines
    -- This is a key function for the fast_grep backend as it's optimized for minimal processing
    -- This test doesn't depend on the backend being active, as it's testing a pure function
    it("can make entries from grep output lines", function()
        -- Use the make_entry function from the backend
        local make_entry = FastGrepBackend.make_entry
        
        -- Test with a sample line
        local test_line = "→|RIGHTWARDS ARROW|U+2192|Sm|FORWARD|RIGHT ARROW"
        local entry = make_entry(test_line)
        
        assert(entry ~= nil, "entry should not be nil")
        assert(entry.character == "→", "character should be →")
        assert(entry.name == "RIGHTWARDS ARROW", "name should be RIGHTWARDS ARROW")
        assert(entry.code_point == "U+2192", "code_point should be U+2192")
        assert(entry.category == "Sm", "category should be Sm")
        assert(entry.display == "→ RIGHTWARDS ARROW (U+2192)", "display should be formatted correctly")
        assert(entry.ordinal == "RIGHTWARDS ARROW FORWARD RIGHT ARROW", "ordinal should be formatted correctly")
    end)
    
    -- Test that the backend gracefully handles invalid input
    it("returns nil for invalid lines", function()
        local make_entry = FastGrepBackend.make_entry
        
        -- Test with an invalid line
        local test_line = "invalid line"
        local entry = make_entry(test_line)
        
        assert(entry == nil, "entry should be nil for invalid input")
    end)
    
    -- Test that the backend can be configured through the unifill setup function
    it("can be configured through setup", function()
        local unifill = require("unifill")
        
        -- Save original config
        local original_backend = require("unifill.data").get_backend_name()
        
        -- Set up with fast_grep backend
        unifill.setup({
            backend = "fast_grep",
            backends = {
                fast_grep = {
                    data_path = "/custom/path/unicode_data.txt",
                    grep_command = "grep"
                }
            }
        })
        
        -- Verify the configuration was applied
        local backend_name = require("unifill.data").get_backend_name()
        assert(backend_name == "fast_grep", "backend_name should be fast_grep")
        
        -- Verify that attempting to load data with an inactive backend returns an empty table
        local data = require("unifill.data").load_unicode_data()
        assert(type(data) == "table", "data should be a table even when backend is inactive")
        assert(#data == 0, "data should be empty when backend is inactive")
        
        -- Restore original config
        unifill.setup({ backend = original_backend })
    end)
    
    -- Test that the backend properly reports its inactive status
    it("correctly reports inactive status", function()
        local backend = FastGrepBackend.new()
        assert(backend:is_active() == false, "fast_grep backend should be inactive by default")
    end)
    
    -- Mark tests that would require an active backend as pending
    pending("can load data when active", function()
        -- This test is pending because the fast_grep backend is intentionally inactive
        -- If the backend were to be made active, this test would verify data loading
        local backend = FastGrepBackend.new()
        -- Temporarily make the backend active
        backend.active = true
        
        -- Check if the backend is now active
        assert(backend:is_active() == true, "backend should be active")
        
        -- Try to load data
        local data = backend:load_data()
        assert(type(data) == "function", "data should be a function for the fast_grep backend")
        
        -- Reset the backend to inactive
        backend.active = false
    end)
    
    pending("can search data when active", function()
        -- This test is pending because the fast_grep backend is intentionally inactive
        -- If the backend were to be made active, this test would verify search functionality
    end)
end)