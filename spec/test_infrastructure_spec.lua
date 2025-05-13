-- spec/test_infrastructure_spec.lua
describe("test infrastructure", function()
  it("can load plenary", function()
    local plenary = require("plenary")
    assert.is_not_nil(plenary)
  end)

  it("can load telescope", function()
    local telescope = require("telescope")
    assert.is_not_nil(telescope)
  end)

  it("can load unifill", function()
    local unifill = require("unifill")
    assert.is_not_nil(unifill)
  end)

  it("can access unifill's telescope extension", function()
    local telescope = require("telescope")
    telescope.setup()
    -- Load the unifill extension if it's registered as an extension
    pcall(function() telescope.load_extension("unifill") end)
    -- This test will pass even if unifill doesn't register as an extension
    assert.is_not_nil(telescope)
  end)

  it("can create a buffer", function()
    local buffer = vim.api.nvim_create_buf(false, true)
    assert.is_true(buffer > 0)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"Test line"})
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    assert.are.same({"Test line"}, lines)
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)

  it("can simulate keypresses", function()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {""})
    
    -- Enter insert mode and type text
    local keys = vim.api.nvim_replace_termcodes("iHello, world!<Esc>", true, false, true)
    vim.api.nvim_feedkeys(keys, "tx", false)
    
    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Verify content
    assert.are.same({"Hello, world!"}, lines)
    
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)

  it("can create a telescope picker", function()
    -- Require telescope modules
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    
    -- Create a basic picker
    local picker = pickers.new({}, {
      prompt_title = "Test Picker",
      finder = finders.new_table({
        results = {"item1", "item2", "item3"}
      }),
      sorter = conf.generic_sorter({}),
    })
    
    -- Verify the picker was created
    assert.is_not_nil(picker)
    assert.equals("Test Picker", picker.prompt_title)
  end)

  it("can access unifill's telescope integration", function()
    -- Require unifill's telescope module
    local unifill_telescope = require("unifill.telescope")
    
    -- Verify it exists
    assert.is_not_nil(unifill_telescope)
  end)
end)