#!/bin/bash

# Run the benchmark script with proper Neovim configuration
# Latest results , for ref, (as of 2025-05-12): 2023-10-01):
# === EVERY-DAY Dataset Results ===

# Backend    Init Time   Entries  arrow           right arrow           mathematical symbol   latin letter small    Median Time
# ---------  ----------  -------  --------------  --------------------  --------------------  --------------------  -----------
# lua          44.40 ms  6975     624 /  0.01 ms  222 /  0.05 ms        49 /  0.07 ms         408 /  0.06 ms         0.05 ms
# csv          85.28 ms  6910     624 /  0.00 ms  222 /  0.05 ms        49 /  0.06 ms         408 /  0.06 ms         0.05 ms
# grep          0.51 ms  N/A      1 / 15.35 ms    1 (exact) /  5.62 ms  1 (exact) /  5.75 ms  1 (exact) /  5.32 ms   5.69 ms
# fast_grep     4.50 ms  N/A      1 /  4.81 ms    1 (exact) /  5.79 ms  1 (exact) /  6.35 ms  1 (exact) /  6.17 ms   5.98 ms

# === COMPLETE Dataset Results ===

# Backend    Init Time   Entries  arrow           right arrow           mathematical symbol   latin letter small    Median Time
# ---------  ----------  -------  --------------  --------------------  --------------------  --------------------  -----------
# lua          79.94 ms  40078    657 /  0.00 ms  233 /  0.06 ms        52 /  0.06 ms         903 /  0.06 ms         0.06 ms
# csv         483.78 ms  40013    657 /  0.00 ms  233 /  0.06 ms        52 /  0.07 ms         903 /  0.07 ms         0.06 ms
# grep          0.00 ms  N/A      1 /  6.50 ms    1 (exact) /  5.25 ms  1 (exact) /  5.73 ms  1 (exact) /  4.88 ms   5.49 ms
# fast_grep     0.00 ms  N/A      1 /  5.32 ms    1 (exact) /  5.01 ms  1 (exact) /  5.25 ms  1 (exact) /  5.59 ms   5.28 ms

nvim --headless -c "luafile benchmark.lua" -c "qa!"
