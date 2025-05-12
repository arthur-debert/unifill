-- Constants for unifill
local M = {}

-- Dataset names
M.DATASET = {
    EVERYDAY = "every-day",
    COMPLETE = "complete"
}

-- Default dataset
M.DEFAULT_DATASET = M.DATASET.EVERYDAY

-- Results limit constants
M.DEFAULT_RESULTS_LIMIT = 50  -- Default number of results to display
M.MAX_RESULTS_LIMIT = 200     -- Maximum allowed results to display

return M