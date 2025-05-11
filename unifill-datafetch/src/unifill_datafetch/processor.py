"""
Module for processing Unicode data files.
"""

import xml.etree.ElementTree as ET
from collections import defaultdict
from typing import Dict, List, Tuple, Optional

from .types import UnicodeCharInfo


def parse_unicode_data(filename: str) -> Optional[Dict[str, UnicodeCharInfo]]:
    """
    Parse UnicodeData.txt file.
    
    Args:
        filename: Path to the UnicodeData.txt file
        
    Returns:
        Dictionary mapping code points to character info:
        {
            code_point_hex: UnicodeCharInfo(name, category, char_obj)
        }
        or None if parsing failed
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

                    # Skip character range definitions
                    if name.startswith('<') and name.endswith(', First>'):
                        continue
                    if name.startswith('<') and name.endswith(', Last>'):
                        continue

                    try:
                        char_obj = chr(int(code_point_hex, 16))
                        data[code_point_hex] = UnicodeCharInfo(
                            name=name,
                            category=category,
                            char_obj=char_obj
                        )
                    except ValueError:
                        print(f"Skipping invalid code point: {code_point_hex} - {name}")
                        continue
        return data
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return None
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return None


def parse_name_aliases(filename: str) -> Optional[Dict[str, List[str]]]:
    """
    Parse NameAliases.txt file.
    
    Args:
        filename: Path to the NameAliases.txt file
        
    Returns:
        Dictionary mapping code points to lists of aliases,
        or None if parsing failed
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
        return dict(aliases_data)
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return None
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return None


def parse_names_list(filename: str) -> Optional[Dict[str, List[str]]]:
    """
    Parse NamesList.txt file to extract informative aliases.
    
    Args:
        filename: Path to the NamesList.txt file
        
    Returns:
        Dictionary mapping code points to lists of informative aliases,
        or None if parsing failed
    """
    informative_aliases = defaultdict(list)
    current_code_point = None
    
    print(f"Starting to parse {filename}")
    
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            line_number = 0
            for line in f:
                line_number += 1
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
                            # Debug output for specific code points
                            if current_code_point == "2192":
                                print(f"Line {line_number}: Found RIGHTWARDS ARROW: {current_code_point}")
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
                    # Debug output for specific code points
                    if current_code_point == "2192":
                        print(f"Line {line_number}: Added alias for RIGHTWARDS ARROW: '{alias}'")
                # Also include cross-references as aliases (lines starting with "* ")
                elif current_code_point and '*' in line and line.lstrip().startswith('*'):
                    # Extract the descriptive note (remove the "* " prefix)
                    note = line.lstrip()[1:].strip()
                    # Only include if it's not too long and doesn't contain references to other characters
                    if len(note) < 50 and not "(" in note and not ")" in note:
                        code_point_hex = current_code_point.upper()
                        informative_aliases[code_point_hex].append(note)
                        # Debug output for specific code points
                        if current_code_point == "2192":
                            print(f"Line {line_number}: Added note for RIGHTWARDS ARROW: '{note}'")
        
        # Debug output for the final result
        if "2192" in informative_aliases:
            print(f"Final aliases for RIGHTWARDS ARROW: {informative_aliases['2192']}")
        else:
            print(f"No aliases found for RIGHTWARDS ARROW")
        
        return dict(informative_aliases)
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return None
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return None


def parse_cldr_annotations(filename: str) -> Optional[Dict[str, List[str]]]:
    """
    Parse CLDR annotations XML file.
    
    Args:
        filename: Path to the CLDR annotations XML file
        
    Returns:
        Dictionary mapping code points to lists of annotations,
        or None if parsing failed
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
                    
                    # Debug output for specific code points
                    if code_point_hex == "2192":
                        print(f"Added CLDR annotations for RIGHTWARDS ARROW: {aliases}")
        
        return dict(cldr_annotations)
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return None
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return None


def merge_aliases(
    formal_aliases: Dict[str, List[str]],
    informative_aliases: Dict[str, List[str]],
    cldr_annotations: Optional[Dict[str, List[str]]] = None
) -> Dict[str, List[str]]:
    """
    Merge aliases from different sources.
    
    Args:
        formal_aliases: Aliases from NameAliases.txt
        informative_aliases: Aliases from NamesList.txt
        cldr_annotations: Annotations from CLDR
        
    Returns:
        Dictionary mapping code points to merged lists of aliases
    """
    merged_aliases = defaultdict(list)
    
    # Add formal aliases
    for code_point, aliases in formal_aliases.items():
        merged_aliases[code_point].extend(aliases)
        if code_point == "2192":
            print(f"Added formal aliases for RIGHTWARDS ARROW: {aliases}")
    
    # Add informative aliases
    for code_point, aliases in informative_aliases.items():
        # Convert code point format to match the one used in unicode_char_info
        code_point_hex = code_point.upper()
        merged_aliases[code_point_hex].extend(aliases)
        if code_point == "2192":
            print(f"Added informative aliases for RIGHTWARDS ARROW: {aliases}")
    
    # Add CLDR annotations if available
    if cldr_annotations:
        for code_point, annotations in cldr_annotations.items():
            merged_aliases[code_point].extend(annotations)
            if code_point == "2192":
                print(f"Added CLDR annotations for RIGHTWARDS ARROW: {annotations}")
    
    # Debug output for the final result
    if "2192" in merged_aliases:
        print(f"Final aliases for RIGHTWARDS ARROW: {merged_aliases['2192']}")
    
    return dict(merged_aliases)


def process_data_files(file_paths: Dict[str, str]) -> Tuple[Optional[Dict[str, UnicodeCharInfo]], Optional[Dict[str, List[str]]]]:
    """
    Process all Unicode data files.
    
    Args:
        file_paths: Dictionary mapping file types to file paths
        
    Returns:
        Tuple of (unicode_char_info, aliases_info) or (None, None) if processing failed
    """
    # Parse UnicodeData.txt
    unicode_data = parse_unicode_data(file_paths['unicode_data'])
    if not unicode_data:
        print("Failed to parse UnicodeData.txt")
        return None, None
    
    # Parse NameAliases.txt
    formal_aliases = parse_name_aliases(file_paths['name_aliases'])
    if not formal_aliases:
        print("Failed to parse NameAliases.txt")
        return None, None
    
    # Parse NamesList.txt
    informative_aliases = parse_names_list(file_paths['names_list'])
    if not informative_aliases:
        print("Failed to parse NamesList.txt")
        return None, None
    
    # Parse CLDR annotations (optional)
    cldr_annotations = None
    if 'cldr_annotations' in file_paths:
        cldr_annotations = parse_cldr_annotations(file_paths['cldr_annotations'])
        if not cldr_annotations:
            print("Warning: Failed to parse CLDR annotations. Continuing without CLDR annotations.")
    
    # Merge aliases
    aliases_info = merge_aliases(formal_aliases, informative_aliases, cldr_annotations)
    
    return unicode_data, aliases_info