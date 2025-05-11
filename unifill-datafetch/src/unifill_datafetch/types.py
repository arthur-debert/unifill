"""
Type definitions and dataclasses for the unifill-datafetch package.
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


@dataclass
class ExportOptions:
    """Options for exporting Unicode data."""
    format_type: str = 'csv'
    output_dir: str = '.'