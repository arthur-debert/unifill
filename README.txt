unifill is a vim plugin to insert unicode characters.
it leverages telescope, that is it's written as telescope extension. 

we recommend the "<leader>+  iu" (insert unicode) :-), once that is pressed you get a telescope UI that can search unicode chars by the official name, any of it's common aliases and category, once selected the UI char will be inserted into your current buffer.

the unifill-datafetch python script automates the download and setup of the unicode data, but it's not required for the plugin distribution.

Testing
-------
The plugin uses plenary.nvim for testing. To run the test suite:

1. Make sure plenary.nvim is installed
2. Run `bin/run-tests` from the project root

Tests are located in the spec/ directory and use the plenary test format.
