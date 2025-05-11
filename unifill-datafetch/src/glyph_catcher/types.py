"""
Type definitions and dataclasses for the glyph-catcher package.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional


@dataclass
class UnicodeCharInfo:
    """Information about a Unicode character."""
    name: str
    category: str
    char_obj: str


@dataclass
class FetchOptions:
    """Options for fetching Unicode data files."""
    use_cache: bool = False
    cache_dir: Optional[str] = None
    use_temp_cache: bool = False  # If True, use temporary cache location


@dataclass
class ExportOptions:
    """Options for exporting Unicode data."""
    format_type: str = 'csv'
    output_dir: str = '.'
    unicode_blocks: Optional[List[str]] = None  # List of Unicode block names to include