# How to work with the unifill project

This document outlines the key guidelines and resources for working with the
unifill project, a Telescope-based Neovim plugin for inserting Unicode
characters.

## Project Documentation

The main project documentation can be found in [README.txt](../../README.txt),
which covers:

- Basic plugin description and usage
- Installation instructions
- Dataset generation and management
- Development setup and testing

## External Documentation

The project leverages Telescope for its UI. The developer documentation is
maintained in the `tmp` directory (not under source control):

- [Telescope Developer Guide](../../tmp/telescope-developers.md) - For
  understanding the Telescope extension architecture

## Development Guidelines

1. **Code Changes**

   - All code changes must be accompanied by corresponding tests
   - Tests should verify both functionality and edge cases
   - Use the plenary.nvim testing framework (see spec/ directory)

2. **Testing**

   - Run tests locally before submitting changes: `bin/run-tests`
   - Tests are automatically run via GitHub Actions on push/PR
   - Test files should follow the plenary test format

3. **Dataset Management**

   - The Unicode dataset is stored as a Lua lookup table for performance
   - Generate updated dataset using `bin/fetch-data`
   - Dataset changes should be tested thoroughly

4. **Documentation**

   - Keep README.txt updated with any user-facing changes
   - Note that the README.txt is txxt formatted, not markdown. Just follow the
     file's convention, but do not format this as markdown.
   - Document new features and configuration options
   - Update development docs when changing core functionality
