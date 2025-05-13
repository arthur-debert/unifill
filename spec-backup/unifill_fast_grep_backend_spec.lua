-- Tests for the fast grep backend implementation
-- This file contains tests for the optimized grep backend that minimizes Lua processing

local assert = require("luassert")

describe("unifill fast grep backend", function()
    local FastGrepBackend
    
    before_each(function()
        -- Load the fast grep backend
        FastGrepBackend = require("unifill.backends.fast_grep_backend")
    end)
    
    -- Test that the backend can be created with default configuration
    it("can be instantiated", function()
        local backend = FastGrepBackend.new()
        assert.is_not_nil(backend)
    end)
    
    -- Test that the backend returns the expected entry structure definition
    it("returns the correct entry structure", function()
        local backend = FastGrepBackend.new()
        local structure = backend:get_entry_structure()
        
        assert.is_not_nil(structure)
        assert.equals("string", structure.name)
        assert.equals("string", structure.character)
        assert.equals("string", structure.code_point)
        assert.equals("string", structure.category)
        assert.equals("table", structure.aliases)
    end)
    
    -- Test that the backend can parse grep output lines into entry objects
    -- This is a key function for the fast_grep backend as it's optimized for minimal processing
    it("can make entries from grep output lines", function()
        -- Use the make_entry function from the backend
        local make_entry = FastGrepBackend.make_entry
        
        -- Test with a sample line
        local test_line = "→|RIGHTWARDS ARROW|U+2192|Sm|FORWARD|RIGHT ARROW"
        local entry = make_entry(test_line)
        
        assert.is_not_nil(entry)
        assert.equals("→", entry.character)
        assert.equals("RIGHTWARDS ARROW", entry.name)
        assert.equals("U+2192", entry.code_point)
        assert.equals("Sm", entry.category)
        assert.equals("→ RIGHTWARDS ARROW (U+2192)", entry.display)
        assert.equals("RIGHTWARDS ARROW FORWARD RIGHT ARROW", entry.ordinal)
    end)
    -- Test that the backend gracefully handles invalid input
    it("returns nil for invalid lines", function()
        local make_entry = FastGrepBackend.make_entry
        
        -- Test with an invalid line
        local test_line = "invalid line"
        local entry = make_entry(test_line)
        
        assert.is_nil(entry)
    end)
    -- Test that the backend can be configured through the unifill setup function
    it("can be configured through setup", function()
        -- Skip this test if telescope is not available
        local has_telescope = pcall(require, "telescope.pickers")
        if not has_telescope then
            pending("Telescope not available, skipping test")
            return
        end
        
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
        assert.equals("fast_grep", backend_name)
        
        -- Restore original config
        unifill.setup({ backend = original_backend })
    end)
end)