-- tests2.0/async_operations_spec.lua
describe("async operations", function()
  it("can wait for async operations to complete", function()
    local async_completed = false
    
    -- Simulate an async operation
    vim.defer_fn(function()
      async_completed = true
    end, 100)
    
    -- Wait for the operation to complete (with timeout)
    vim.wait(1000, function()
      return async_completed
    end, 10)
    
    -- Verify the operation completed
    assert.is_true(async_completed)
  end)
  
  it("can handle multiple async operations in sequence", function()
    local step1_completed = false
    local step2_completed = false
    local step3_completed = false
    
    -- First async operation
    vim.defer_fn(function()
      step1_completed = true
      
      -- Second async operation (starts after first completes)
      vim.defer_fn(function()
        step2_completed = true
        
        -- Third async operation (starts after second completes)
        vim.defer_fn(function()
          step3_completed = true
        end, 50)
      end, 50)
    end, 50)
    
    -- Wait for all operations to complete
    vim.wait(1000, function()
      return step1_completed and step2_completed and step3_completed
    end, 10)
    
    -- Verify all operations completed
    assert.is_true(step1_completed)
    assert.is_true(step2_completed)
    assert.is_true(step3_completed)
  end)
  
  it("can handle async operations with buffer modifications", function()
    -- Create a buffer
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
    
    -- Set initial content
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"Initial content"})
    
    local modification_done = false
    
    -- Simulate an async operation that modifies the buffer
    vim.defer_fn(function()
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"Modified content"})
      modification_done = true
    end, 100)
    
    -- Wait for the operation to complete
    vim.wait(1000, function()
      return modification_done
    end, 10)
    
    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Verify content was modified
    assert.are.same({"Modified content"}, lines)
    
    -- Clean up
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)
end)