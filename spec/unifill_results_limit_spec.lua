-- spec/unifill_results_limit_spec.lua
-- Tests for the results limit functionality

local constants = require("unifill.constants")

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
    
    after_each(function()
        -- Reset to default configuration
        unifill.setup({
            backend = "lua",
            dataset = constants.DATASET.EVERYDAY
        })
    end)
    
    it("should use default results limit when not specified", function()
        local config = data.get_config()
        assert(config.results_limit == constants.DEFAULT_RESULTS_LIMIT, 
            "results_limit should be the default value")
    end)
    
    it("should use custom results limit when specified", function()
        local custom_limit = 100
        unifill.setup({
            results_limit = custom_limit
        })
        
        local config = data.get_config()
        assert(config.results_limit == custom_limit, 
            "results_limit should be the custom value")
    end)
    
    it("should cap results limit at maximum allowed value", function()
        local too_large_limit = constants.MAX_RESULTS_LIMIT + 100
        unifill.setup({
            results_limit = too_large_limit
        })
        
        -- The limit should be capped at the maximum allowed value
        local config = data.get_config()
        assert(config.results_limit == constants.MAX_RESULTS_LIMIT, 
            "results_limit should be capped at MAX_RESULTS_LIMIT")
    end)
    
    it("should pass results_limit to finder as maximum_results", function()
        -- Skip this test if telescope is not available
        local has_telescope, telescope_finders = pcall(require, "telescope.finders")
        if not has_telescope then
            pending("Telescope not available, skipping test")
            return
        end
        
        -- Mock the finders.new_table function to check if maximum_results is set correctly
        local original_new_table = telescope_finders.new_table
        local called_with_maximum_results = nil
        
        -- Override the function to capture the maximum_results parameter
        telescope_finders.new_table = function(opts)
            called_with_maximum_results = opts.maximum_results
            return original_new_table(opts)
        end
        
        -- Call the unifill function with a custom results_limit
        local custom_limit = 75
        unifill.unifill({
            results_limit = custom_limit
        })
        
        -- Restore the original function
        telescope_finders.new_table = original_new_table
        
        -- Verify that maximum_results was set to the custom limit
        assert(called_with_maximum_results == custom_limit, 
            "maximum_results should be set to the custom limit")
    end)
end)