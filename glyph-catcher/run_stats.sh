#!/bin/bash

# Change to the glyph-catcher directory
cd "$(dirname "$0")"

# Run the script using poetry
poetry run python bin/compare_alias_stats.py