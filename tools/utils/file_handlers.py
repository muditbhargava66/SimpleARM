#!/usr/bin/env python3
# -----------------------------------------------------------------------------
# File: file_handlers.py
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: File handling utilities for SRAM and GDS generation
# -----------------------------------------------------------------------------

import os
import sys
import json
import logging
from pathlib import Path
from typing import Dict, List, Union, Optional
import subprocess
import shutil

class FileHandler:
    """Utility class for handling file operations."""
    
    def __init__(self, base_dir: Union[str, Path]):
        """Initialize with base directory."""
        self.base_dir = Path(base_dir)
        self.setup_logging()

    def setup_logging(self):
        """Setup logging configuration."""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

    def ensure_directory(self, directory: Union[str, Path]) -> Path:
        """Ensure directory exists and return Path object."""
        dir_path = self.base_dir / directory
        dir_path.mkdir(parents=True, exist_ok=True)
        return dir_path

    def copy_file(self, src: Union[str, Path], dst: Union[str, Path], must_exist: bool = True) -> bool:
        """Copy file from source to destination."""
        try:
            src_path = Path(src)
            dst_path = Path(dst)
            
            if not src_path.exists():
                if must_exist:
                    self.logger.error(f"Source file does not exist: {src_path}")
                    return False
                return True
                
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dst_path)
            self.logger.info(f"Copied {src_path} to {dst_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error copying file {src} to {dst}: {str(e)}")
            return False

    def load_json(self, file_path: Union[str, Path]) -> Optional[Dict]:
        """Load JSON file and return dictionary."""
        try:
            with open(self.base_dir / file_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            self.logger.error(f"Error loading JSON file {file_path}: {str(e)}")
            return None

    def save_json(self, data: Dict, file_path: Union[str, Path]) -> bool:
        """Save dictionary to JSON file."""
        try:
            with open(self.base_dir / file_path, 'w') as f:
                json.dump(data, f, indent=2)
            return True
        except Exception as e:
            self.logger.error(f"Error saving JSON file {file_path}: {str(e)}")
            return False

    def read_file(self, file_path: Union[str, Path]) -> Optional[str]:
        """Read file contents."""
        try:
            with open(self.base_dir / file_path, 'r') as f:
                return f.read()
        except Exception as e:
            self.logger.error(f"Error reading file {file_path}: {str(e)}")
            return None

    def write_file(self, content: str, file_path: Union[str, Path]) -> bool:
        """Write content to file."""
        try:
            with open(self.base_dir / file_path, 'w') as f:
                f.write(content)
            return True
        except Exception as e:
            self.logger.error(f"Error writing file {file_path}: {str(e)}")
            return False

    def execute_command(self, command: List[str], cwd: Optional[Union[str, Path]] = None) -> bool:
        """Execute shell command."""
        try:
            result = subprocess.run(
                command,
                cwd=cwd or self.base_dir,
                capture_output=True,
                text=True,
                check=True
            )
            self.logger.info(f"Command executed successfully: {' '.join(command)}")
            return True
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Command failed: {' '.join(command)}")
            self.logger.error(f"Error output: {e.stderr}")
            return False
        except Exception as e:
            self.logger.error(f"Error executing command: {str(e)}")
            return False

    def find_files(self, pattern: str, directory: Optional[Union[str, Path]] = None) -> List[Path]:
        """Find files matching pattern in directory."""
        search_dir = self.base_dir / (directory or '')
        return list(search_dir.glob(pattern))

    def check_tool_exists(self, tool_name: str) -> bool:
        """Check if a command-line tool exists."""
        try:
            subprocess.run([tool_name, '--version'],
                         capture_output=True,
                         check=True)
            return True
        except:
            return False

    def create_backup(self, file_path: Union[str, Path]) -> bool:
        """Create backup of file with timestamp."""
        try:
            from datetime import datetime
            src_path = Path(file_path)
            if not src_path.exists():
                return False
            
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_path = src_path.with_suffix(f'.{timestamp}.bak')
            shutil.copy2(src_path, backup_path)
            self.logger.info(f"Created backup: {backup_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error creating backup of {file_path}: {str(e)}")
            return False

    def validate_file_exists(self, file_path: Union[str, Path], file_type: str) -> bool:
        """Validate file exists and has correct extension."""
        path = Path(file_path)
        if not path.exists():
            self.logger.error(f"{file_type} file not found: {path}")
            return False
        if not path.suffix.lower() == f".{file_type.lower()}":
            self.logger.error(f"Invalid {file_type} file extension: {path}")
            return False
        return True

class GDSFileHandler(FileHandler):
    """GDS-specific file handling utilities."""
    
    def validate_gds(self, gds_file: Union[str, Path]) -> bool:
        """Validate GDS file format."""
        try:
            path = Path(gds_file)
            if not path.exists():
                self.logger.error(f"GDS file not found: {path}")
                return False
                
            # Check file header
            with open(path, 'rb') as f:
                header = f.read(4)
                if header[2:4] != b'\x00\x02':
                    self.logger.error(f"Invalid GDS file format: {path}")
                    return False
                    
            return True
            
        except Exception as e:
            self.logger.error(f"Error validating GDS file {gds_file}: {str(e)}")
            return False

    def merge_gds_files(self, input_files: List[Union[str, Path]], output_file: Union[str, Path]) -> bool:
        """Merge multiple GDS files."""
        try:
            # Validate input files
            for file in input_files:
                if not self.validate_gds(file):
                    return False
            
            # Use command-line tool for merging
            command = ['klayout', '-z', '-rd', f"input_files={','.join(map(str, input_files))}",
                      '-rd', f"output_file={output_file}", '-r', 'merge_gds.rb']
            
            return self.execute_command(command)
            
        except Exception as e:
            self.logger.error(f"Error merging GDS files: {str(e)}")
            return False

class LEFFileHandler(FileHandler):
    """LEF-specific file handling utilities."""
    
    def validate_lef(self, lef_file: Union[str, Path]) -> bool:
        """Validate LEF file format."""
        try:
            content = self.read_file(lef_file)
            if not content:
                return False
                
            # Check for required LEF keywords
            required_keywords = ['VERSION', 'BUSBITCHARS', 'DIVIDERCHAR', 'MACRO']
            for keyword in required_keywords:
                if keyword not in content:
                    self.logger.error(f"Missing required LEF keyword {keyword} in {lef_file}")
                    return False
                    
            return True
            
        except Exception as e:
            self.logger.error(f"Error validating LEF file {lef_file}: {str(e)}")
            return False