"""
Module for processing Unicode data files.
"""

import os
import json
import xml.etree.ElementTree as ET
from collections import defaultdict
from typing import Dict, Tuple, List, Any, Optional
from pathlib import Path

# Dictionary mapping Unicode code points to their block names
# This is a simplified mapping for common blocks
UNICODE_BLOCKS = {
    # Basic Latin (ASCII): U+0000 to U+007F
    range(0x0000, 0x0080): "Basic Latin",
    
    # Latin-1 Supplement: U+0080 to U+00FF
    range(0x0080, 0x0100): "Latin-1 Supplement",
    
    # Latin Extended-A: U+0100 to U+017F
    range(0x0100, 0x0180): "Latin Extended-A",
    
    # Latin Extended-B: U+0180 to U+024F
    range(0x0180, 0x0250): "Latin Extended-B",
    
    # Greek and Coptic: U+0370 to U+03FF
    range(0x0370, 0x0400): "Greek and Coptic",
    
    # Cyrillic: U+0400 to U+04FF
    range(0x0400, 0x0500): "Cyrillic",
    
    # General Punctuation: U+2000 to U+206F
    range(0x2000, 0x2070): "General Punctuation",
    
    # Arrows: U+2190 to U+21FF
    range(0x2190, 0x2200): "Arrows",
    
    # Mathematical Operators: U+2200 to U+22FF
    range(0x2200, 0x2300): "Mathematical Operators",
    
    # Miscellaneous Symbols: U+2600 to U+26FF
    range(0x2600, 0x2700): "Miscellaneous Symbols",
    
    # Emoticons: U+1F600 to U+1F64F
    range(0x1F600, 0x1F650): "Emoticons",
}


def get_unicode_block(code_point: int) -> str:
    """
    Get the Unicode block name for a given code point.
    
    Args:
        code_point: Unicode code point as an integer
        
    Returns:
        Name of the Unicode block, or "Unknown Block" if not found
    """
    for block_range, block_name in UNICODE_BLOCKS.items():
        if code_point in block_range:
            return block_name
    return "Unknown Block"


def parse_unicode_data(filename: str) -> Dict[str, Dict[str, str]]:
    """
    Parse UnicodeData.txt.
    
    Args:
        filename: Path to UnicodeData.txt
        
    Returns:
        Dictionary mapping code points to character information:
        {code_point_hex: {'name': name, 'category': category, 'char_obj': char}}
    """
    data = {}
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            for line in f:
                fields = line.strip().split(';')
                if len(fields) >= 3:
                    code_point_hex = fields[0]
                    name = fields[1]
                    category = fields[2]

                    if name.startswith('<') and name.endswith(', First>'):
                        continue
                    if name.startswith('<') and name.endswith(', Last>'):
                        continue

                    try:
                        char_obj = chr(int(code_point_hex, 16))
                        data[code_point_hex] = {
                            'name': name,
                            'category': category,
                            'char_obj': char_obj,
                            'block': get_unicode_block(int(code_point_hex, 16))
                        }
                    except ValueError:
                        print(f"Skipping invalid code point: {code_point_hex} - {name}")
                        continue
        return data
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return {}
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return {}


def parse_name_aliases(filename: str) -> Dict[str, List[str]]:
    """
    Parse NameAliases.txt.
    
    Args:
        filename: Path to NameAliases.txt
        
    Returns:
        Dictionary mapping code points to lists of aliases:
        {code_point_hex: [alias1, alias2, ...]}
    """
    aliases_data = defaultdict(list)
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                fields = line.split(';')
                if len(fields) >= 2:
                    code_point_hex = fields[0]
                    alias = fields[1]
                    aliases_data[code_point_hex].append(alias)
        return aliases_data
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return {}
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return {}


def parse_names_list(filename: str) -> Dict[str, List[str]]:
    """
    Parse NamesList.txt to extract informative aliases.
    
    Args:
        filename: Path to NamesList.txt
        
    Returns:
        Dictionary mapping code points to lists of informative aliases:
        {code_point_hex: [alias1, alias2, ...]}
    """
    informative_aliases = defaultdict(list)
    current_code_point = None
    
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            for line in f:
                original_line = line
                line = line.strip()
                
                # Skip comments, headers, and empty lines
                if not line or line.startswith('@') or line.startswith(';'):
                    continue
                
                # Check if this is a new character definition
                if not original_line.startswith('\t'):
                    parts = line.split('\t', 1)
                    if len(parts) == 2:
                        try:
                            # Store the code point as a hex string
                            current_code_point = parts[0].strip()
                        except ValueError:
                            current_code_point = None
                    else:
                        current_code_point = None
                # Check if this is an informative alias (starts with "= ")
                elif current_code_point and '=' in line and line.lstrip().startswith('='):
                    # Extract the alias (remove the "= " prefix)
                    alias = line.lstrip()[1:].strip()
                    # Convert code point to uppercase hex format to match unicode_char_info keys
                    code_point_hex = current_code_point.upper()
                    informative_aliases[code_point_hex].append(alias)
                # Also include cross-references as aliases (lines starting with "* ")
                elif current_code_point and '*' in line and line.lstrip().startswith('*'):
                    # Extract the descriptive note (remove the "* " prefix)
                    note = line.lstrip()[1:].strip()
                    # Only include if it's not too long and doesn't contain references to other characters
                    if len(note) < 50 and not "(" in note and not ")" in note:
                        code_point_hex = current_code_point.upper()
                        informative_aliases[code_point_hex].append(note)
        
        return informative_aliases
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return {}
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return {}


def parse_cldr_annotations(filename: str) -> Dict[str, List[str]]:
    """
    Parse CLDR annotations XML file to extract common names and descriptions.
    
    Args:
        filename: Path to CLDR annotations XML file
        
    Returns:
        Dictionary mapping code points to lists of annotations:
        {code_point_hex: [annotation1, annotation2, ...]}
    """
    cldr_annotations = defaultdict(list)
    
    try:
        tree = ET.parse(filename)
        root = tree.getroot()
        
        # Find all annotation elements
        for annotation in root.findall(".//annotation"):
            # Skip text-to-speech annotations (type="tts")
            if 'type' in annotation.attrib:
                continue
                
            # Get the character code point
            if 'cp' in annotation.attrib:
                char = annotation.attrib['cp']
                # Convert character to code point
                if len(char) == 1:
                    code_point_hex = format(ord(char), 'X')
                else:
                    # Handle multi-character code points
                    code_point_hex = format(ord(char[0]), 'X')
                    
                # Get the annotations (pipe-separated list)
                if annotation.text:
                    # Split by pipe and strip whitespace
                    aliases = [alias.strip() for alias in annotation.text.split('|')]
                    cldr_annotations[code_point_hex].extend(aliases)
        
        return cldr_annotations
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return {}
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return {}


def process_data_files(file_paths: Dict[str, str]) -> Tuple[Dict[str, Dict[str, str]], Dict[str, List[str]]]:
    """
    Process Unicode data files.
    
    Args:
        file_paths: Dictionary mapping file types to file paths
        
    Returns:
        Tuple of (unicode_data, aliases_data) where:
        - unicode_data is a dictionary mapping code points to character information
        - aliases_data is a dictionary mapping code points to lists of aliases
    """
    # Parse the Unicode data files
    unicode_data = parse_unicode_data(file_paths['unicode_data'])
    formal_aliases = parse_name_aliases(file_paths['name_aliases'])
    informative_aliases = parse_names_list(file_paths['names_list'])
    
    # Parse CLDR annotations if available
    cldr_annotations = {}
    if 'cldr_annotations' in file_paths:
        cldr_annotations = parse_cldr_annotations(file_paths['cldr_annotations'])
    
    # Merge all aliases
    aliases_data = defaultdict(list)
    
    # Add formal aliases
    for code_point, aliases in formal_aliases.items():
        aliases_data[code_point].extend(aliases)
    
    # Add informative aliases
    for code_point, aliases in informative_aliases.items():
        code_point_hex = code_point.upper()
        aliases_data[code_point_hex].extend(aliases)
    
    # Add CLDR annotations
    for code_point, annotations in cldr_annotations.items():
        aliases_data[code_point].extend(annotations)
    
    return unicode_data, aliases_data


def filter_by_unicode_blocks(
    unicode_data: Dict[str, Dict[str, str]], 
    aliases_data: Dict[str, List[str]], 
    blocks: Optional[List[str]]
) -> Tuple[Dict[str, Dict[str, str]], Dict[str, List[str]]]:
    """
    Filter Unicode data by block names.
    
    Args:
        unicode_data: Dictionary mapping code points to character information
        aliases_data: Dictionary mapping code points to lists of aliases
        blocks: List of Unicode block names to include, or None to include all blocks
        
    Returns:
        Tuple of filtered (unicode_data, aliases_data)
    """
    if not blocks:
        return unicode_data, aliases_data
    
    filtered_unicode_data = {}
    filtered_aliases_data = {}
    
    for code_point, char_info in unicode_data.items():
        if 'block' in char_info and char_info['block'] in blocks:
            filtered_unicode_data[code_point] = char_info
            if code_point in aliases_data:
                filtered_aliases_data[code_point] = aliases_data[code_point]
    
    return filtered_unicode_data, filtered_aliases_data


def save_master_data_file(
    unicode_data: Dict[str, Dict[str, str]],
    aliases_data: Dict[str, List[str]],
    data_dir: str
) -> Optional[str]:
    """
    Save the processed Unicode data to a master JSON file.
    
    Args:
        unicode_data: Dictionary mapping code points to character information
        aliases_data: Dictionary mapping code points to lists of aliases
        data_dir: Directory to save the master data file
        
    Returns:
        Path to the saved master data file, or None if saving failed
    """
    from .config import MASTER_DATA_FILE
    
    if not unicode_data or not aliases_data:
        print("Error: No data to save to master file")
        return None
    
    try:
        # Create the data directory if it doesn't exist
        os.makedirs(data_dir, exist_ok=True)
        
        # Prepare the data for serialization
        master_data = {
            'unicode_data': {},
            'aliases_data': aliases_data
        }
        
        # Convert UnicodeCharInfo objects to dictionaries
        for code_point, char_info in unicode_data.items():
            master_data['unicode_data'][code_point] = {
                'name': char_info['name'],
                'category': char_info['category'],
                'char_obj': char_info['char_obj'],
                'block': char_info['block'] if 'block' in char_info else "Unknown Block"
            }
        
        # Save the data to the master file
        master_file_path = os.path.join(data_dir, MASTER_DATA_FILE)
        with open(master_file_path, 'w', encoding='utf-8') as f:
            json.dump(master_data, f, ensure_ascii=False, indent=2)
        
        print(f"Master data file saved to: {master_file_path}")
        return master_file_path
    
    except Exception as e:
        print(f"Error saving master data file: {e}")
        return None


def load_master_data_file(master_file_path: str) -> Tuple[Optional[Dict[str, Dict[str, str]]], Optional[Dict[str, List[str]]]]:
    """
    Load the processed Unicode data from a master JSON file.
    
    Args:
        master_file_path: Path to the master data file
        
    Returns:
        Tuple of (unicode_data, aliases_data), or (None, None) if loading failed
    """
    try:
        # Check if the master file exists
        if not os.path.exists(master_file_path):
            print(f"Master data file not found: {master_file_path}")
            return None, None
        
        # Load the data from the master file
        with open(master_file_path, 'r', encoding='utf-8') as f:
            master_data = json.load(f)
        
        # Extract the unicode_data and aliases_data
        unicode_data_dict = master_data.get('unicode_data', {})
        aliases_data = master_data.get('aliases_data', {})
        
        # Convert dictionaries to UnicodeCharInfo objects
        unicode_data = unicode_data_dict
        
        print(f"Loaded master data file: {master_file_path}")
        print(f"Loaded {len(unicode_data)} characters and {sum(len(aliases) for aliases in aliases_data.values())} aliases")
        
        return unicode_data, aliases_data
    
    except json.JSONDecodeError as e:
        print(f"Error decoding master data file: {e}")
        return None, None
    except Exception as e:
        print(f"Error loading master data file: {e}")
        return None, None


def get_master_file_path(fetch_options) -> str:
    """
    Get the path to the master data file based on the fetch options.
    
    Args:
        fetch_options: Options for fetching Unicode data files
        
    Returns:
        Path to the master data file
    """
    from .config import MASTER_DATA_FILE, DEFAULT_DATA_DIR
    
    # Determine which data directory to use
    data_dir = fetch_options.data_dir
    if not data_dir:
        data_dir = DEFAULT_DATA_DIR
    
    # Return the path to the master data file
    return os.path.join(data_dir, MASTER_DATA_FILE)