# Tests for glyph-catcher

This directory contains tests for the glyph-catcher package.

## Running Tests

You can run the tests using pytest:

```bash
# Install development dependencies
poetry install --with dev

# Run all tests
poetry run pytest

# Run tests with coverage
poetry run pytest --cov=unifill_datafetch

# Run a specific test file
poetry run pytest tests/test_basic.py
```

## Test Structure

- `test_basic.py`: Basic tests for the fetcher module
- More test files will be added as the project grows

## Writing Tests

When writing tests, follow these guidelines:

1. Use descriptive test names that explain what is being tested
2. Test both normal and edge cases
3. Use mocks for external dependencies (e.g., HTTP requests)
4. Keep tests independent of each other
