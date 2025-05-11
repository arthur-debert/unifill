#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory
cd "$SCRIPT_DIR"

# Install dependencies
echo "Installing dependencies..."
poetry install

# Run the tests
echo "Running tests..."
poetry run pytest "$@"

# Print success message
echo "Tests completed successfully!"