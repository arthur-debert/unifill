-- tests2.0/command_mode_spec.lua
describe("command mode operations", function()
  it("can execute commands", function()
    -- Execute a Vim command
    vim.cmd("set number")
    
    -- Verify the result
    assert.is_true(vim.opt.number:get())
  end)
  
  it("can execute plugin commands", function()
    -- Create a test command for unifill
    vim.cmd([[command! TestUnifillCommand let g:unifill_test_var = 'test_value']])
    
    -- Execute the command
    vim.cmd("TestUnifillCommand")
    
    -- Verify the expected state
    assert.equals('test_value', vim.g.unifill_test_var)
  end)
  
  it("can modify buffer content via commands", function()
    -- Create a buffer
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
    
    -- Set initial content
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"line 1", "line 2", "line 3"})
    
    -- Execute a command that modifies the buffer
    vim.cmd("normal! ggdG")  -- Delete all lines
    vim.cmd("normal! iNew content")  -- Insert new content
    
    -- Get the resulting content
    local result = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Verify the expected result
    assert.are.same({"New content"}, result)
    
    -- Clean up
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)
end)