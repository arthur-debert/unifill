local assert = require("luassert")
local constants = require("unifill.constants")

-- Skip this test if we're not in Neovim
if not pcall(require, "telescope.pickers") then
  print("Telescope not available, skipping results_limit tests")
  return
end

describe("unifill results limit", function()
  local data = require("unifill.data")
  local unifill = require("unifill")
  
  before_each(function()
    -- Reset the configuration before each test
    unifill.setup({
      backend = "lua",
      dataset = constants.DATASET.EVERYDAY
    })
  end)
  
  it("should use default results limit when not specified", function()
    local config = data.get_config()
    assert.equals(constants.DEFAULT_RESULTS_LIMIT, config.results_limit)
  end)
  
  it("should use custom results limit when specified", function()
    local custom_limit = 100
    unifill.setup({
      results_limit = custom_limit
    })
    
    local config = data.get_config()
    assert.equals(custom_limit, config.results_limit)
  end)
  
  it("should cap results limit at maximum allowed value", function()
    local too_large_limit = constants.MAX_RESULTS_LIMIT + 100
    unifill.setup({
      results_limit = too_large_limit
    })
    
    -- The limit should be capped at the maximum allowed value
    local config = data.get_config()
    assert.equals(constants.MAX_RESULTS_LIMIT, config.results_limit)
  end)
  
  it("should pass results_limit to finder as maximum_results", function()
    -- Mock the finders.new_table function to check if maximum_results is set correctly
    local original_new_table = require("telescope.finders").new_table
    local called_with_maximum_results = nil
    
    -- Override the function to capture the maximum_results parameter
    require("telescope.finders").new_table = function(opts)
      called_with_maximum_results = opts.maximum_results
      return original_new_table(opts)
    end
    
    -- Call the unifill function with a custom results_limit
    local custom_limit = 75
    unifill.unifill({
      results_limit = custom_limit
    })
    
    -- Restore the original function
    require("telescope.finders").new_table = original_new_table
    
    -- Verify that maximum_results was set to the custom limit
    assert.equals(custom_limit, called_with_maximum_results)
  end)
end)