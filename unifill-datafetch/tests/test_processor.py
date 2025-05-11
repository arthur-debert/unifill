"""
Tests for the processor module.
"""

import os
import tempfile
import unittest
from unittest.mock import patch, mock_open, MagicMock
from collections import defaultdict

from unifill_datafetch.types import UnicodeCharInfo
from unifill_datafetch.processor import (
    parse_unicode_data,
    parse_name_aliases,
    parse_names_list,
    parse_cldr_annotations,
    merge_aliases,
    process_data_files,
)


class TestProcessor(unittest.TestCase):
    """Test the processor module."""

    def test_parse_unicode_data(self):
        """Test parsing UnicodeData.txt."""
        # Create a temporary file with test data
        test_data = (
            "0041;LATIN CAPITAL LETTER A;Lu;0;L;;;;;N;;;;0061;\n"
            "0042;LATIN CAPITAL LETTER B;Lu;0;L;;;;;N;;;;0062;\n"
            "0043;LATIN CAPITAL LETTER C;Lu;0;L;;;;;N;;;;0063;\n"
        )
        
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file.write(test_data)
            temp_file_path = temp_file.name
        
        try:
            # Parse the test data
            result = parse_unicode_data(temp_file_path)
            
            # Check the result
            self.assertEqual(len(result), 3)
            
            # Check the first character
            self.assertIn('0041', result)
            self.assertEqual(result['0041'].name, 'LATIN CAPITAL LETTER A')
            self.assertEqual(result['0041'].category, 'Lu')
            self.assertEqual(result['0041'].char_obj, 'A')
            
            # Check the second character
            self.assertIn('0042', result)
            self.assertEqual(result['0042'].name, 'LATIN CAPITAL LETTER B')
            self.assertEqual(result['0042'].category, 'Lu')
            self.assertEqual(result['0042'].char_obj, 'B')
            
            # Check the third character
            self.assertIn('0043', result)
            self.assertEqual(result['0043'].name, 'LATIN CAPITAL LETTER C')
            self.assertEqual(result['0043'].category, 'Lu')
            self.assertEqual(result['0043'].char_obj, 'C')
        finally:
            # Clean up
            os.unlink(temp_file_path)

    def test_parse_unicode_data_with_range(self):
        """Test parsing UnicodeData.txt with character ranges."""
        # Create a temporary file with test data including ranges
        test_data = (
            "0041;LATIN CAPITAL LETTER A;Lu;0;L;;;;;N;;;;0061;\n"
            "4E00;<CJK Ideograph, First>;Lo;0;L;;;;;N;;;;;\n"
            "9FFF;<CJK Ideograph, Last>;Lo;0;L;;;;;N;;;;;\n"
            "0042;LATIN CAPITAL LETTER B;Lu;0;L;;;;;N;;;;0062;\n"
        )
        
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file.write(test_data)
            temp_file_path = temp_file.name
        
        try:
            # Parse the test data
            result = parse_unicode_data(temp_file_path)
            
            # Check the result
            self.assertEqual(len(result), 2)
            
            # Check that the range markers are skipped
            self.assertIn('0041', result)
            self.assertIn('0042', result)
            self.assertNotIn('4E00', result)
            self.assertNotIn('9FFF', result)
        finally:
            # Clean up
            os.unlink(temp_file_path)

    def test_parse_unicode_data_file_not_found(self):
        """Test parsing UnicodeData.txt when the file is not found."""
        # Call the function with a non-existent file
        result = parse_unicode_data('/non/existent/file.txt')
        
        # Check that the function returned None
        self.assertIsNone(result)

    def test_parse_name_aliases(self):
        """Test parsing NameAliases.txt."""
        # Create a temporary file with test data
        test_data = (
            "0000;NULL;control;\n"
            "0000;NUL;abbreviation;\n"
            "0041;LATIN LETTER A;correction;\n"
            "0041;LA;abbreviation;\n"
        )
        
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file.write(test_data)
            temp_file_path = temp_file.name
        
        try:
            # Parse the test data
            result = parse_name_aliases(temp_file_path)
            
            # Check the result
            self.assertEqual(len(result), 2)
            
            # Check the aliases for the first character
            self.assertIn('0000', result)
            self.assertEqual(len(result['0000']), 2)
            self.assertIn('NULL', result['0000'])
            self.assertIn('NUL', result['0000'])
            
            # Check the aliases for the second character
            self.assertIn('0041', result)
            self.assertEqual(len(result['0041']), 2)
            self.assertIn('LATIN LETTER A', result['0041'])
            self.assertIn('LA', result['0041'])
        finally:
            # Clean up
            os.unlink(temp_file_path)

    def test_parse_name_aliases_file_not_found(self):
        """Test parsing NameAliases.txt when the file is not found."""
        # Call the function with a non-existent file
        result = parse_name_aliases('/non/existent/file.txt')
        
        # Check that the function returned None
        self.assertIsNone(result)

    def test_parse_names_list(self):
        """Test parsing NamesList.txt."""
        # Create a temporary file with test data
        test_data = (
            "0041\tLATIN CAPITAL LETTER A\n"
            "\t= first letter of the Latin alphabet\n"
            "\t* used for ...\n"
            "0042\tLATIN CAPITAL LETTER B\n"
            "\t= second letter of the Latin alphabet\n"
        )
        
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file.write(test_data)
            temp_file_path = temp_file.name
        
        try:
            # Parse the test data
            result = parse_names_list(temp_file_path)
            
            # Check the result
            self.assertEqual(len(result), 2)
            
            # Check the aliases for the first character
            self.assertIn('0041', result)
            self.assertEqual(len(result['0041']), 2)
            self.assertIn('first letter of the Latin alphabet', result['0041'])
            self.assertIn('used for ...', result['0041'])
            
            # Check the aliases for the second character
            self.assertIn('0042', result)
            self.assertEqual(len(result['0042']), 1)
            self.assertIn('second letter of the Latin alphabet', result['0042'])
        finally:
            # Clean up
            os.unlink(temp_file_path)

    def test_parse_names_list_file_not_found(self):
        """Test parsing NamesList.txt when the file is not found."""
        # Call the function with a non-existent file
        result = parse_names_list('/non/existent/file.txt')
        
        # Check that the function returned None
        self.assertIsNone(result)

    @patch('xml.etree.ElementTree.parse')
    def test_parse_cldr_annotations(self, mock_parse):
        """Test parsing CLDR annotations XML file."""
        # Create a mock XML tree
        mock_root = MagicMock()
        mock_parse.return_value.getroot.return_value = mock_root
        
        # Create mock annotations
        mock_annotation1 = MagicMock()
        mock_annotation1.attrib = {'cp': 'A'}
        mock_annotation1.text = 'letter a | first letter'
        
        mock_annotation2 = MagicMock()
        mock_annotation2.attrib = {'cp': 'B'}
        mock_annotation2.text = 'letter b | second letter'
        
        mock_annotation3 = MagicMock()
        mock_annotation3.attrib = {'cp': 'A', 'type': 'tts'}
        mock_annotation3.text = 'capital a'
        
        # Set up the mock to return the annotations
        mock_root.findall.return_value = [mock_annotation1, mock_annotation2, mock_annotation3]
        
        # Parse the mock data
        result = parse_cldr_annotations('dummy.xml')
        
        # Check the result
        self.assertEqual(len(result), 2)
        
        # Check the annotations for the first character
        self.assertIn('41', result)  # 'A' -> '41' in hex
        self.assertEqual(len(result['41']), 2)
        self.assertIn('letter a', result['41'])
        self.assertIn('first letter', result['41'])
        
        # Check the annotations for the second character
        self.assertIn('42', result)  # 'B' -> '42' in hex
        self.assertEqual(len(result['42']), 2)
        self.assertIn('letter b', result['42'])
        self.assertIn('second letter', result['42'])

    @patch('xml.etree.ElementTree.parse')
    def test_parse_cldr_annotations_file_not_found(self, mock_parse):
        """Test parsing CLDR annotations XML file when the file is not found."""
        # Set up the mock to raise a FileNotFoundError
        mock_parse.side_effect = FileNotFoundError()
        
        # Call the function
        result = parse_cldr_annotations('/non/existent/file.xml')
        
        # Check that the function returned None
        self.assertIsNone(result)

    def test_merge_aliases(self):
        """Test merging aliases from different sources."""
        # Create test data
        formal_aliases = {
            '0041': ['LATIN LETTER A', 'LA'],
            '0042': ['LATIN LETTER B'],
        }
        
        informative_aliases = {
            '0041': ['first letter of the Latin alphabet'],
            '0043': ['third letter of the Latin alphabet'],
        }
        
        cldr_annotations = {
            '0041': ['letter a', 'first letter'],
            '0042': ['letter b'],
        }
        
        # Merge the aliases
        result = merge_aliases(formal_aliases, informative_aliases, cldr_annotations)
        
        # Check the result
        self.assertEqual(len(result), 3)
        
        # Check the merged aliases for the first character
        self.assertIn('0041', result)
        self.assertEqual(len(result['0041']), 5)  # Updated to match the actual count
        self.assertIn('LATIN LETTER A', result['0041'])
        self.assertIn('LA', result['0041'])
        self.assertIn('first letter of the Latin alphabet', result['0041'])
        self.assertIn('letter a', result['0041'])
        self.assertIn('first letter', result['0041'])
        
        # Check the merged aliases for the second character
        self.assertIn('0042', result)
        self.assertEqual(len(result['0042']), 2)
        self.assertIn('LATIN LETTER B', result['0042'])
        self.assertIn('letter b', result['0042'])
        
        # Check the merged aliases for the third character
        self.assertIn('0043', result)
        self.assertEqual(len(result['0043']), 1)
        self.assertIn('third letter of the Latin alphabet', result['0043'])

    def test_merge_aliases_without_cldr(self):
        """Test merging aliases without CLDR annotations."""
        # Create test data
        formal_aliases = {
            '0041': ['LATIN LETTER A', 'LA'],
            '0042': ['LATIN LETTER B'],
        }
        
        informative_aliases = {
            '0041': ['first letter of the Latin alphabet'],
            '0043': ['third letter of the Latin alphabet'],
        }
        
        # Merge the aliases without CLDR annotations
        result = merge_aliases(formal_aliases, informative_aliases)
        
        # Check the result
        self.assertEqual(len(result), 3)
        
        # Check the merged aliases for the first character
        self.assertIn('0041', result)
        self.assertEqual(len(result['0041']), 3)
        self.assertIn('LATIN LETTER A', result['0041'])
        self.assertIn('LA', result['0041'])
        self.assertIn('first letter of the Latin alphabet', result['0041'])

    @patch('unifill_datafetch.processor.parse_unicode_data')
    @patch('unifill_datafetch.processor.parse_name_aliases')
    @patch('unifill_datafetch.processor.parse_names_list')
    @patch('unifill_datafetch.processor.parse_cldr_annotations')
    @patch('unifill_datafetch.processor.merge_aliases')
    def test_process_data_files_success(
        self, mock_merge, mock_parse_cldr, mock_parse_names, mock_parse_aliases, mock_parse_unicode
    ):
        """Test processing all data files successfully."""
        # Set up the mock returns
        unicode_data = {
            '0041': UnicodeCharInfo(name='LATIN CAPITAL LETTER A', category='Lu', char_obj='A'),
            '0042': UnicodeCharInfo(name='LATIN CAPITAL LETTER B', category='Lu', char_obj='B'),
        }
        mock_parse_unicode.return_value = unicode_data
        
        formal_aliases = {'0041': ['LATIN LETTER A']}
        mock_parse_aliases.return_value = formal_aliases
        
        informative_aliases = {'0042': ['second letter']}
        mock_parse_names.return_value = informative_aliases
        
        cldr_annotations = {'0041': ['letter a']}
        mock_parse_cldr.return_value = cldr_annotations
        
        merged_aliases = {
            '0041': ['LATIN LETTER A', 'letter a'],
            '0042': ['second letter'],
        }
        mock_merge.return_value = merged_aliases
        
        # Call the function
        file_paths = {
            'unicode_data': '/path/to/UnicodeData.txt',
            'name_aliases': '/path/to/NameAliases.txt',
            'names_list': '/path/to/NamesList.txt',
            'cldr_annotations': '/path/to/en.xml',
        }
        result_unicode_data, result_aliases = process_data_files(file_paths)
        
        # Check the result
        self.assertEqual(result_unicode_data, unicode_data)
        self.assertEqual(result_aliases, merged_aliases)
        
        # Check that the parsing functions were called with the correct arguments
        mock_parse_unicode.assert_called_once_with('/path/to/UnicodeData.txt')
        mock_parse_aliases.assert_called_once_with('/path/to/NameAliases.txt')
        mock_parse_names.assert_called_once_with('/path/to/NamesList.txt')
        mock_parse_cldr.assert_called_once_with('/path/to/en.xml')
        mock_merge.assert_called_once_with(formal_aliases, informative_aliases, cldr_annotations)

    @patch('unifill_datafetch.processor.parse_unicode_data')
    def test_process_data_files_unicode_data_missing(self, mock_parse_unicode):
        """Test processing data files when UnicodeData.txt parsing fails."""
        # Set up the mock to return None
        mock_parse_unicode.return_value = None
        
        # Call the function
        file_paths = {
            'unicode_data': '/path/to/UnicodeData.txt',
            'name_aliases': '/path/to/NameAliases.txt',
            'names_list': '/path/to/NamesList.txt',
        }
        result_unicode_data, result_aliases = process_data_files(file_paths)
        
        # Check that the function returned None, None
        self.assertIsNone(result_unicode_data)
        self.assertIsNone(result_aliases)


if __name__ == '__main__':
    unittest.main()