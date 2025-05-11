"""
Basic tests for the unifill-datafetch package.
"""

import os
import tempfile
import unittest
from unittest.mock import patch

from unifill_datafetch.types import FetchOptions, ExportOptions
from unifill_datafetch.fetcher import download_file
from unifill_datafetch.config import UNICODE_DATA_FILE_URL


class TestFetcher(unittest.TestCase):
    """Test the fetcher module."""

    @patch('requests.get')
    def test_download_file_with_cache(self, mock_get):
        """Test downloading a file with cache enabled."""
        # Create a temporary directory for the cache
        with tempfile.TemporaryDirectory() as temp_dir:
            # Set up the mock response
            mock_response = mock_get.return_value
            mock_response.iter_content.return_value = [b'test data']
            
            # Call the function
            options = FetchOptions(use_cache=True, cache_dir=temp_dir)
            result = download_file(UNICODE_DATA_FILE_URL, options)
            
            # Check that the file was downloaded
            self.assertIsNotNone(result)
            
            # Check that the file exists in the cache
            cache_file = os.path.join(temp_dir, os.path.basename(UNICODE_DATA_FILE_URL))
            self.assertTrue(os.path.exists(cache_file))
            
            # Call the function again to use the cached file
            result2 = download_file(UNICODE_DATA_FILE_URL, options)
            
            # Check that the same file was returned
            self.assertEqual(result, result2)
            
            # Check that the request was only made once
            mock_get.assert_called_once()


if __name__ == '__main__':
    unittest.main()