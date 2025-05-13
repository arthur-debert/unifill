-- tests2.0/buffer_operations_spec.lua
describe("buffer operations", function()
  local buffer
  
  before_each(function()
    -- Create a fresh buffer for each test
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
  end)
  
  after_each(function()
    -- Clean up after each test
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)
  
  it("can set and get buffer lines", function()
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"line 1", "line 2", "line 3"})
    
    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Verify content
    assert.are.same({"line 1", "line 2", "line 3"}, lines)
  end)
  
  it("can get buffer content after operations", function()
    -- Set initial content
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"initial content"})
    
    -- Perform an operation (e.g., through unifill)
    -- This is a placeholder for actual unifill operations
    -- We'll just modify the buffer directly for this test
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"modified content"})
    
    -- Get the resulting content
    local result = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Verify the expected result
    assert.are.same({"modified content"}, result)
  end)
  
  it("can insert unicode characters into buffer", function()
    -- Set initial content
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"text before cursor"})
    
    -- Position cursor at the end of the line
    vim.api.nvim_win_set_cursor(0, {1, 17}) -- Line 1, column 17 (0-indexed)
    
    -- Insert a unicode character (simulating what unifill would do)
    vim.api.nvim_put({"→"}, "", false, true)
    
    -- Get the resulting content
    local result = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Verify the expected result
    assert.are.same({"text before cursor→"}, result)
  end)
end)