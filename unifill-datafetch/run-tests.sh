#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory
cd "$SCRIPT_DIR"

# Install development dependencies
echo "Installing development dependencies..."
poetry install --with dev

# Run the tests
echo "Running tests..."
poetry run pytest "$@"

# If no arguments are provided, run with coverage
if [ $# -eq 0 ]; then
    echo "Running tests with coverage..."
    poetry run pytest --cov=unifill_datafetch
    
    # Generate coverage report
    echo "Generating coverage report..."
    poetry run pytest --cov=unifill_datafetch --cov-report=term-missing
fi

echo "Tests completed successfully!"