#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# Current results:
# === Benchmark Results ===

# Backend  Init Time   Entries  arrow           right arrow           mathematical symbol   latin letter small    Median Time
# -------  ----------  -------  --------------  --------------------  --------------------  --------------------  -----------
# lua       273.21 ms  40078    638 /  0.00 ms  224 /  0.09 ms        49 /  0.07 ms         903 /  0.07 ms         0.07 ms
# csv       155.23 ms  40013    638 /  0.01 ms  224 /  0.06 ms        49 /  0.07 ms         903 /  0.06 ms         0.06 ms
# grep        0.37 ms  N/A      1 / 20.31 ms    1 (exact) /  6.96 ms  0 (exact) /  8.62 ms  1 (exact) /  6.77 ms   7.79 ms

set -e

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="${0:a:h}"

# Project root is assumed to be the current directory
PROJECT_ROOT="$(pwd)"

# Define key directories and filenames
DATA_DIR="$PROJECT_ROOT/data/glyph-catcher"

# Check if the data files exist
if [ ! -f "$DATA_DIR/unicode_data.lua" ]; then
    echo "Error: Unicode data file not found at: $DATA_DIR/unicode_data.lua"
    echo "Please run bin/gen-datasets first to generate the data files."
    exit 1
fi

if [ ! -f "$DATA_DIR/unicode_data.csv" ]; then
    echo "Error: Unicode data file not found at: $DATA_DIR/unicode_data.csv"
    echo "Please run bin/gen-datasets --format all first to generate all data formats."
    exit 1
fi

if [ ! -f "$DATA_DIR/unicode_data.txt" ]; then
    echo "Error: Unicode data file not found at: $DATA_DIR/unicode_data.txt"
    echo "Please run bin/gen-datasets --format all first to generate all data formats."
    exit 1
fi

# Run the benchmark script
echo "Running benchmark..."
nvim -c "lua dofile('benchmark.lua')" -c "q"

# Check if the benchmark results file exists
if [ -f "benchmark_results.txt" ]; then
    echo "Benchmark completed successfully."
    echo "Results saved to benchmark_results.txt"
    echo ""
    echo "=== Benchmark Results ==="
    cat benchmark_results.txt
else
    echo "Error: Benchmark failed to generate results."
    exit 1
fi
