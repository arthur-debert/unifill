#!/bin/bash
# This scripts runs the benchmark for all backends and displays the results.
# Currently, the lua backend is about 3x faster than the csv backend.

# Create tmp directory for logs if it doesn't exist
mkdir -p tmp/logs

# Set log level to info
export UNIFILL_LOG_LEVEL=info

# Run the benchmark
nvim --headless -c "luafile benchmark.lua" -c "qa!"

# Display the results
echo -e "\nBenchmark results:"
echo "================="
cat benchmark_results.txt

# Also show the log file for additional timing information
echo -e "\nLog file (tmp/logs/unifill.log):"
echo "================================="
cat tmp/logs/unifill.log
