"""
Tests for the exporter module.
"""

import os
import json
import tempfile
import unittest
from unittest.mock import patch, mock_open, MagicMock

from unifill_datafetch.types import UnicodeCharInfo, ExportOptions
from unifill_datafetch.exporter import (
    write_csv_output,
    write_json_output,
    write_lua_output,
    write_txt_output,
    export_data,
    save_source_files,
)


class TestExporter(unittest.TestCase):
    """Test the exporter module."""

    def setUp(self):
        """Set up test data."""
        # Create test Unicode data
        self.unicode_data = {
            '0041': UnicodeCharInfo(name='LATIN CAPITAL LETTER A', category='Lu', char_obj='A'),
            '0042': UnicodeCharInfo(name='LATIN CAPITAL LETTER B', category='Lu', char_obj='B'),
        }
        
        # Create test aliases data
        self.aliases_data = {
            '0041': ['LATIN LETTER A', 'first letter'],
            '0042': ['LATIN LETTER B', 'second letter'],
        }

    def test_write_csv_output(self):
        """Test writing data to CSV format."""
        # Create a temporary file
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            temp_file_path = temp_file.name
        
        try:
            # Write the data to the file
            result = write_csv_output(self.unicode_data, self.aliases_data, temp_file_path)
            
            # Check that the function returned True
            self.assertTrue(result)
            
            # Read the file and check its contents
            with open(temp_file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Check the header
            self.assertEqual(lines[0].strip(), 'code_point,character,name,category,alias_1,alias_2')
            
            # Check the data rows
            self.assertIn('U+0041,A,LATIN CAPITAL LETTER A,Lu,LATIN LETTER A,first letter', lines[1].strip())
            self.assertIn('U+0042,B,LATIN CAPITAL LETTER B,Lu,LATIN LETTER B,second letter', lines[2].strip())
        finally:
            # Clean up
            os.unlink(temp_file_path)

    def test_write_csv_output_no_data(self):
        """Test writing to CSV format with no data."""
        # Call the function with empty data
        result = write_csv_output({}, self.aliases_data, 'dummy.csv')
        
        # Check that the function returned False
        self.assertFalse(result)

    def test_write_json_output(self):
        """Test writing data to JSON format."""
        # Create a temporary file
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            temp_file_path = temp_file.name
        
        try:
            # Write the data to the file
            result = write_json_output(self.unicode_data, self.aliases_data, temp_file_path)
            
            # Check that the function returned True
            self.assertTrue(result)
            
            # Read the file and parse the JSON
            with open(temp_file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Check the data
            self.assertEqual(len(data), 2)
            
            # Check the first character
            self.assertEqual(data[0]['code_point'], 'U+0041')
            self.assertEqual(data[0]['character'], 'A')
            self.assertEqual(data[0]['name'], 'LATIN CAPITAL LETTER A')
            self.assertEqual(data[0]['category'], 'Lu')
            self.assertEqual(data[0]['aliases'], ['LATIN LETTER A', 'first letter'])
            
            # Check the second character
            self.assertEqual(data[1]['code_point'], 'U+0042')
            self.assertEqual(data[1]['character'], 'B')
            self.assertEqual(data[1]['name'], 'LATIN CAPITAL LETTER B')
            self.assertEqual(data[1]['category'], 'Lu')
            self.assertEqual(data[1]['aliases'], ['LATIN LETTER B', 'second letter'])
        finally:
            # Clean up
            os.unlink(temp_file_path)

    def test_write_json_output_no_data(self):
        """Test writing to JSON format with no data."""
        # Call the function with empty data
        result = write_json_output({}, self.aliases_data, 'dummy.json')
        
        # Check that the function returned False
        self.assertFalse(result)

    def test_write_lua_output(self):
        """Test writing data to Lua module format."""
        # Create a temporary file
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            temp_file_path = temp_file.name
        
        try:
            # Write the data to the file
            result = write_lua_output(self.unicode_data, self.aliases_data, temp_file_path)
            
            # Check that the function returned True
            self.assertTrue(result)
            
            # Read the file and check its contents
            with open(temp_file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Check that the file starts with the correct header
            self.assertTrue(content.startswith('-- Auto-generated unicode data module'))
            
            # Check that the file contains the data
            self.assertIn('code_point = "U+0041"', content)
            self.assertIn('character = "A"', content)
            self.assertIn('name = "LATIN CAPITAL LETTER A"', content)
            self.assertIn('category = "Lu"', content)
            self.assertIn('"LATIN LETTER A"', content)
            self.assertIn('"first letter"', content)
            
            self.assertIn('code_point = "U+0042"', content)
            self.assertIn('character = "B"', content)
            self.assertIn('name = "LATIN CAPITAL LETTER B"', content)
            self.assertIn('category = "Lu"', content)
            self.assertIn('"LATIN LETTER B"', content)
            self.assertIn('"second letter"', content)
        finally:
            # Clean up
            os.unlink(temp_file_path)

    def test_write_lua_output_special_chars(self):
        """Test writing data with special characters to Lua module format."""
        # Create test data with special characters
        unicode_data = {
            '000A': UnicodeCharInfo(name='LINE FEED', category='Cc', char_obj='\n'),
            '0022': UnicodeCharInfo(name='QUOTATION MARK', category='Po', char_obj='"'),
            '005C': UnicodeCharInfo(name='REVERSE SOLIDUS', category='Po', char_obj='\\'),
        }
        
        # Create a temporary file
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            temp_file_path = temp_file.name
        
        try:
            # Write the data to the file
            result = write_lua_output(unicode_data, {}, temp_file_path)
            
            # Check that the function returned True
            self.assertTrue(result)
            
            # Read the file and check its contents
            with open(temp_file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Check that special characters are properly escaped
            self.assertIn('character = "\\n"', content)
            self.assertIn('character = "\\""', content)
            self.assertIn('character = "\\\\"', content)
        finally:
            # Clean up
            os.unlink(temp_file_path)

    def test_write_lua_output_no_data(self):
        """Test writing to Lua module format with no data."""
        # Call the function with empty data
        result = write_lua_output({}, self.aliases_data, 'dummy.lua')
        
        # Check that the function returned False
        self.assertFalse(result)

    def test_write_txt_output(self):
        """Test writing data to text format."""
        # Create a temporary file
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            temp_file_path = temp_file.name
        
        try:
            # Write the data to the file
            result = write_txt_output(self.unicode_data, self.aliases_data, temp_file_path)
            
            # Check that the function returned True
            self.assertTrue(result)
            
            # Read the file and check its contents
            with open(temp_file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Check the data lines
            self.assertEqual(lines[0].strip(), 'A|LATIN CAPITAL LETTER A|U+0041|Lu|LATIN LETTER A|first letter')
            self.assertEqual(lines[1].strip(), 'B|LATIN CAPITAL LETTER B|U+0042|Lu|LATIN LETTER B|second letter')
        finally:
            # Clean up
            os.unlink(temp_file_path)

    def test_write_txt_output_no_data(self):
        """Test writing to text format with no data."""
        # Call the function with empty data
        result = write_txt_output({}, self.aliases_data, 'dummy.txt')
        
        # Check that the function returned False
        self.assertFalse(result)

    @patch('unifill_datafetch.exporter.write_csv_output')
    @patch('unifill_datafetch.exporter.write_json_output')
    @patch('unifill_datafetch.exporter.write_lua_output')
    @patch('unifill_datafetch.exporter.write_txt_output')
    def test_export_data_csv(self, mock_txt, mock_lua, mock_json, mock_csv):
        """Test exporting data to CSV format."""
        # Set up the mocks
        mock_csv.return_value = True
        
        # Call the function
        options = ExportOptions(format_type='csv', output_dir='/tmp')
        result = export_data(self.unicode_data, self.aliases_data, options)
        
        # Check the result
        self.assertEqual(result, ['/tmp/unicode_data.csv'])
        
        # Check that the correct write function was called
        mock_csv.assert_called_once_with(self.unicode_data, self.aliases_data, '/tmp/unicode_data.csv')
        mock_json.assert_not_called()
        mock_lua.assert_not_called()
        mock_txt.assert_not_called()

    @patch('unifill_datafetch.exporter.write_csv_output')
    @patch('unifill_datafetch.exporter.write_json_output')
    @patch('unifill_datafetch.exporter.write_lua_output')
    @patch('unifill_datafetch.exporter.write_txt_output')
    def test_export_data_all(self, mock_txt, mock_lua, mock_json, mock_csv):
        """Test exporting data to all formats."""
        # Set up the mocks
        mock_csv.return_value = True
        mock_json.return_value = True
        mock_lua.return_value = True
        mock_txt.return_value = True
        
        # Call the function
        options = ExportOptions(format_type='all', output_dir='/tmp')
        result = export_data(self.unicode_data, self.aliases_data, options)
        
        # Check the result
        self.assertEqual(set(result), {
            '/tmp/unicode_data.csv',
            '/tmp/unicode_data.json',
            '/tmp/unicode_data.lua',
            '/tmp/unicode_data.txt',
        })
        
        # Check that all write functions were called
        mock_csv.assert_called_once_with(self.unicode_data, self.aliases_data, '/tmp/unicode_data.csv')
        mock_json.assert_called_once_with(self.unicode_data, self.aliases_data, '/tmp/unicode_data.json')
        mock_lua.assert_called_once_with(self.unicode_data, self.aliases_data, '/tmp/unicode_data.lua')
        mock_txt.assert_called_once_with(self.unicode_data, self.aliases_data, '/tmp/unicode_data.txt')

    @patch('unifill_datafetch.exporter.write_csv_output')
    def test_export_data_write_failure(self, mock_csv):
        """Test exporting data when writing fails."""
        # Set up the mock to return False
        mock_csv.return_value = False
        
        # Call the function
        options = ExportOptions(format_type='csv', output_dir='/tmp')
        result = export_data(self.unicode_data, self.aliases_data, options)
        
        # Check the result
        self.assertEqual(result, [])

    @patch('os.makedirs')
    @patch('shutil.copy')
    def test_save_source_files(self, mock_copy, mock_makedirs):
        """Test saving source files."""
        # Create test file paths
        file_paths = {
            'unicode_data': '/tmp/UnicodeData.txt',
            'name_aliases': '/tmp/NameAliases.txt',
            'names_list': '/tmp/NamesList.txt',
        }
        
        # Call the function
        save_source_files(file_paths, '/output')
        
        # Check that the directory was created
        mock_makedirs.assert_called_once_with('/output', exist_ok=True)
        
        # Check that the files were copied
        mock_copy.assert_any_call('/tmp/UnicodeData.txt', '/output/UnicodeData.txt')
        mock_copy.assert_any_call('/tmp/NameAliases.txt', '/output/NameAliases.txt')
        mock_copy.assert_any_call('/tmp/NamesList.txt', '/output/NamesList.txt')


if __name__ == '__main__':
    unittest.main()