#!/usr/bin/env python3
# -----------------------------------------------------------------------------
# File: run_regression.py
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Regression test runner script
# -----------------------------------------------------------------------------

import os
import sys
import argparse
import subprocess
import datetime
import json
import logging
from pathlib import Path
from typing import List, Dict, Optional

# Configuration
class Config:
    def __init__(self, config_file: str):
        self.config_file = config_file
        self.test_dir = Path("tests")
        self.log_dir = Path("logs")
        self.result_dir = Path("results")
        self.simulator = "verilator"
        self.coverage = True
        self.waves = False
        self.timeout = 3600  # 1 hour default timeout
        self.load_config()

    def load_config(self):
        try:
            with open(self.config_file, 'r') as f:
                config = json.load(f)
                self.__dict__.update(config)
        except FileNotFoundError:
            logging.warning(f"Config file {self.config_file} not found, using defaults")
        except json.JSONDecodeError:
            logging.error(f"Invalid JSON in config file {self.config_file}")
            sys.exit(1)

# Test Runner
class TestRunner:
    def __init__(self, config: Config):
        self.config = config
        self.prepare_directories()
        self.setup_logging()

    def prepare_directories(self):
        """Create necessary directories if they don't exist."""
        for directory in [self.config.log_dir, self.config.result_dir]:
            os.makedirs(directory, exist_ok=True)

    def setup_logging(self):
        """Set up logging configuration."""
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = self.config.log_dir / f"regression_{timestamp}.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )

    def run_test(self, test_file: Path) -> bool:
        """Run a single test and return True if it passes."""
        try:
            cmd = self._build_command(test_file)
            logging.info(f"Running test: {test_file.name}")
            logging.debug(f"Command: {' '.join(cmd)}")
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.config.timeout
            )
            
            success = result.returncode == 0
            self._save_test_results(test_file, result, success)
            return success
            
        except subprocess.TimeoutExpired:
            logging.error(f"Test {test_file.name} timed out")
            self._save_test_results(test_file, None, False)
            return False
        except Exception as e:
            logging.error(f"Error running test {test_file.name}: {str(e)}")
            self._save_test_results(test_file, None, False)
            return False

    def _build_command(self, test_file: Path) -> List[str]:
        """Build the command to run the test."""
        cmd = [self.config.simulator]
        
        if self.config.coverage:
            cmd.extend(["--coverage", "true"])
        
        if self.config.waves:
            cmd.extend(["--waves", "true"])
        
        cmd.extend([
            "--test", str(test_file),
            "--log", str(self.config.log_dir / f"{test_file.stem}.log"),
            "--top", "simple_arm_tb"
        ])