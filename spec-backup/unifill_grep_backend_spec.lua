local assert = require("luassert")

describe("unifill grep backend", function()
    local GrepBackend
    
    before_each(function()
        -- Load the grep backend
        GrepBackend = require("unifill.backends.grep_backend")
    end)
    
    it("can be instantiated", function()
        local backend = GrepBackend.new()
        assert.is_not_nil(backend)
    end)
    
    it("returns the correct entry structure", function()
        local backend = GrepBackend.new()
        local structure = backend:get_entry_structure()
        
        assert.is_not_nil(structure)
        assert.equals("string", structure.name)
        assert.equals("string", structure.character)
        assert.equals("string", structure.code_point)
        assert.equals("string", structure.category)
        assert.equals("table", structure.aliases)
    end)
    
    it("can parse grep output lines", function()
        local backend = GrepBackend.new()
        
        -- Use the parse_grep_line function from the backend
        local parse_grep_line = GrepBackend.parse_grep_line
        
        -- Test with a sample line
        local test_line = "→|RIGHTWARDS ARROW|U+2192|Sm|FORWARD|RIGHT ARROW"
        local entry = parse_grep_line(test_line)
        
        assert.is_not_nil(entry)
        assert.equals("→", entry.character)
        assert.equals("RIGHTWARDS ARROW", entry.name)
        assert.equals("U+2192", entry.code_point)
        assert.equals("Sm", entry.category)
        assert.equals(2, #entry.aliases)
        assert.equals("FORWARD", entry.aliases[1])
        assert.equals("RIGHT ARROW", entry.aliases[2])
    end)
    
    it("creates a valid command generator", function()
        local backend = GrepBackend.new({
            grep_command = "rg",
            data_path = "/path/to/data.txt"
        })
        
        local cmd = backend:create_command_generator("test")
        
        assert.is_not_nil(cmd)
        assert.equals("rg", cmd.command)
        assert.is_table(cmd.args)
        assert.equals(5, #cmd.args)
        assert.equals("--no-heading", cmd.args[1])
        assert.equals("--line-number", cmd.args[2])
        assert.equals("-i", cmd.args[3])
        assert.equals("test", cmd.args[4])
        assert.equals("/path/to/data.txt", cmd.args[5])
    end)
    
    it("escapes special characters in the search prompt", function()
        local backend = GrepBackend.new({
            grep_command = "rg",
            data_path = "/path/to/data.txt"
        })
        
        local cmd = backend:create_command_generator("test*+?")
        
        assert.is_not_nil(cmd)
        assert.equals("rg", cmd.command)
        assert.is_table(cmd.args)
        assert.equals(5, #cmd.args)
        assert.equals("--no-heading", cmd.args[1])
        assert.equals("--line-number", cmd.args[2])
        assert.equals("-i", cmd.args[3])
        -- Special characters should be escaped
        assert.equals("test\\*\\+\\?", cmd.args[4])
        assert.equals("/path/to/data.txt", cmd.args[5])
    end)
    
    it("returns nil for empty prompt", function()
        local backend = GrepBackend.new()
        local cmd = backend:create_command_generator("")
        assert.is_nil(cmd)
    end)
    
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
        
        -- Set up with grep backend
        unifill.setup({
            backend = "grep",
            backends = {
                grep = {
                    data_path = "/custom/path/unicode_data.txt",
                    grep_command = "grep"
                }
            }
        })
        
        -- Verify the configuration was applied
        local backend_name = require("unifill.data").get_backend_name()
        assert.equals("grep", backend_name)
        
        -- Restore original config
        unifill.setup({ backend = original_backend })
    end)
end)