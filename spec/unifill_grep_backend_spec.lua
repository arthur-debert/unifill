-- spec/unifill_grep_backend_spec.lua
-- Tests for the grep backend implementation

describe("unifill grep backend", function()
    local GrepBackend
    
    before_each(function()
        -- Clear module cache
        package.loaded['unifill.backends.grep_backend'] = nil
        
        -- Load the grep backend
        GrepBackend = require("unifill.backends.grep_backend")
    end)
    
    after_each(function()
        -- Clear module cache
        package.loaded['unifill.backends.grep_backend'] = nil
    end)
    
    it("can be instantiated", function()
        local backend = GrepBackend.new()
        assert(backend ~= nil, "backend should not be nil")
    end)
    
    it("returns the correct entry structure", function()
        local backend = GrepBackend.new()
        local structure = backend:get_entry_structure()
        
        assert(structure ~= nil, "structure should not be nil")
        assert(structure.name == "string", "name should be a string")
        assert(structure.character == "string", "character should be a string")
        assert(structure.code_point == "string", "code_point should be a string")
        assert(structure.category == "string", "category should be a string")
        assert(structure.aliases == "table", "aliases should be a table")
    end)
    
    it("can parse grep output lines", function()
        local backend = GrepBackend.new()
        
        -- Use the parse_grep_line function from the backend
        local parse_grep_line = GrepBackend.parse_grep_line
        
        -- Test with a sample line
        local test_line = "→|RIGHTWARDS ARROW|U+2192|Sm|FORWARD|RIGHT ARROW"
        local entry = parse_grep_line(test_line)
        
        assert(entry ~= nil, "entry should not be nil")
        assert(entry.character == "→", "character should be →")
        assert(entry.name == "RIGHTWARDS ARROW", "name should be RIGHTWARDS ARROW")
        assert(entry.code_point == "U+2192", "code_point should be U+2192")
        assert(entry.category == "Sm", "category should be Sm")
        assert(#entry.aliases == 2, "should have 2 aliases")
        assert(entry.aliases[1] == "FORWARD", "first alias should be FORWARD")
        assert(entry.aliases[2] == "RIGHT ARROW", "second alias should be RIGHT ARROW")
    end)
    
    it("creates a valid command generator", function()
        local backend = GrepBackend.new({
            grep_command = "rg",
            data_path = "/path/to/data.txt"
        })
        
        local cmd = backend:create_command_generator("test")
        
        assert(cmd ~= nil, "cmd should not be nil")
        assert(cmd.command == "rg", "command should be rg")
        assert(type(cmd.args) == "table", "args should be a table")
        assert(#cmd.args == 5, "args should have 5 elements")
        assert(cmd.args[1] == "--no-heading", "first arg should be --no-heading")
        assert(cmd.args[2] == "--line-number", "second arg should be --line-number")
        assert(cmd.args[3] == "-i", "third arg should be -i")
        assert(cmd.args[4] == "test", "fourth arg should be test")
        assert(cmd.args[5] == "/path/to/data.txt", "fifth arg should be /path/to/data.txt")
    end)
    
    it("escapes special characters in the search prompt", function()
        local backend = GrepBackend.new({
            grep_command = "rg",
            data_path = "/path/to/data.txt"
        })
        
        local cmd = backend:create_command_generator("test*+?")
        
        assert(cmd ~= nil, "cmd should not be nil")
        assert(cmd.command == "rg", "command should be rg")
        assert(type(cmd.args) == "table", "args should be a table")
        assert(#cmd.args == 5, "args should have 5 elements")
        assert(cmd.args[1] == "--no-heading", "first arg should be --no-heading")
        assert(cmd.args[2] == "--line-number", "second arg should be --line-number")
        assert(cmd.args[3] == "-i", "third arg should be -i")
        -- Special characters should be escaped
        assert(cmd.args[4] == "test\\*\\+\\?", "fourth arg should have escaped special characters")
        assert(cmd.args[5] == "/path/to/data.txt", "fifth arg should be /path/to/data.txt")
    end)
    
    it("returns nil for empty prompt", function()
        local backend = GrepBackend.new()
        local cmd = backend:create_command_generator("")
        assert(cmd == nil, "cmd should be nil for empty prompt")
    end)
    
    it("can be configured through setup", function()
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
        assert(backend_name == "grep", "backend_name should be grep")
        
        -- Restore original config
        unifill.setup({ backend = original_backend })
    end)
end)