-- tests2.0/telescope_actions_spec.lua
describe("telescope actions", function()
  local actions
  local action_state
  local buffer
  local picker
  
  before_each(function()
    -- Load required modules
    actions = require("telescope.actions")
    action_state = require("telescope.actions.state")
    
    -- Create a buffer for testing
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
    
    -- Create a basic picker for testing
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    
    picker = pickers.new({}, {
      prompt_title = "Test Picker",
      finder = finders.new_table({
        results = {"item1", "item2", "item3"}
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- Add custom actions for testing
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          -- Store the selection in a global variable for testing
          _G.test_selection = selection[1]
        end)
        
        -- Add a custom action
        map("i", "<C-x>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          -- Store the selection with a prefix for testing
          _G.test_selection = "custom_action:" .. selection[1]
        end)
        
        return true
      end
    })
  end)
  
  after_each(function()
    -- Clean up
    vim.api.nvim_buf_delete(buffer, { force = true })
    _G.test_selection = nil
  end)
  
  it("can define custom actions", function()
    -- Verify the picker has custom actions
    assert.is_not_nil(picker.attach_mappings)
  end)
  
  it("can simulate action execution", function()
    -- Create a mock prompt buffer number
    local prompt_bufnr = 1
    
    -- Mock the action_state.get_selected_entry function
    local original_get_selected_entry = action_state.get_selected_entry
    action_state.get_selected_entry = function()
      return {"item2"}
    end
    
    -- Mock the actions.close function
    local original_close = actions.close
    actions.close = function() end
    
    -- Create a mock map function
    local mock_map = function() return true end
    
    -- Execute the default action by directly calling the function
    -- that would be assigned by attach_mappings
    local mappings_function = picker.attach_mappings
    mappings_function(prompt_bufnr, mock_map)
    
    -- Call the default action directly
    actions.select_default(prompt_bufnr)
    
    -- Verify the result
    assert.equals("item2", _G.test_selection)
    
    -- Restore original functions
    action_state.get_selected_entry = original_get_selected_entry
    actions.close = original_close
  end)
  
  it("can test unifill-specific actions", function()
    -- Create a mock unifill entry
    local unifill_entry = {
      character = "→",
      name = "RIGHTWARDS ARROW",
      code_point = "U+2192",
      display = "→ RIGHTWARDS ARROW (U+2192)",
      ordinal = "→ RIGHTWARDS ARROW (U+2192)"
    }
    
    -- Create a mock insert action
    local insert_action = function(entry)
      -- Simulate inserting the character into the buffer
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line = vim.api.nvim_buf_get_lines(buffer, cursor[1]-1, cursor[1], false)[1]
      local new_line = line:sub(1, cursor[2]) .. entry.character .. line:sub(cursor[2]+1)
      vim.api.nvim_buf_set_lines(buffer, cursor[1]-1, cursor[1], false, {new_line})
      
      -- Store the character for testing
      _G.test_selection = entry.character
    end
    
    -- Execute the insert action
    insert_action(unifill_entry)
    
    -- Verify the result
    assert.equals("→", _G.test_selection)
    
    -- Get the buffer content
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Verify the character was inserted
    assert.is_true(#lines > 0)
    assert.is_true(lines[1]:match("→") ~= nil)
  end)
end)