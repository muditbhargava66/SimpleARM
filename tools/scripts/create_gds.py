#!/usr/bin/env python3
# -----------------------------------------------------------------------------
# File: create_gds.py
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Create final GDS by merging core and SRAM
# -----------------------------------------------------------------------------

import os
import sys
import logging
import argparse
from pathlib import Path
from typing import Dict, List, Optional
import yaml
import json
from file_handlers import FileHandler, GDSFileHandler

class GDSCreator:
    """Create final GDS by merging core and SRAM."""
    
    def __init__(self, config_file: str):
        """Initialize with configuration file."""
        self.config_file = config_file
        self.config = self._load_config()
        self.file_handler = FileHandler(self.config.get('output_dir', '.'))
        self.gds_handler = GDSFileHandler(self.config.get('output_dir', '.'))
        self.setup_logging()

    def setup_logging(self):
        """Setup logging configuration."""
        log_dir = Path(self.config.get('log_dir', 'logs'))
        log_dir.mkdir(parents=True, exist_ok=True)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_dir / 'gds_creation.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)

    def _load_config(self) -> Dict:
        """Load configuration from file."""
        try:
            with open(self.config_file, 'r') as f:
                if self.config_file.endswith('.json'):
                    return json.load(f)
                elif self.config_file.endswith('.yaml'):
                    return yaml.safe_load(f)
                else:
                    raise ValueError("Unsupported config file format")
        except Exception as e:
            print(f"Error loading config file: {str(e)}")
            sys.exit(1)

    def validate_inputs(self) -> bool:
        """Validate input files and required tools."""
        try:
            # Check required tools
            required_tools = ['klayout', 'magic', 'netgen']
            for tool in required_tools:
                if not self.file_handler.check_tool_exists(tool):
                    self.logger.error(f"Required tool not found: {tool}")
                    return False
            
            # Check input files
            required_files = {
                'core_gds': self.config['core_gds'],
                'sram_gds': self.config['sram_gds'],
                'pnr_def': self.config['pnr_def']
            }
            
            # Validate all required files exist
            for name, file_path in required_files.items():
                if not Path(file_path).exists():
                    self.logger.error(f"Required file not found: {name} at {file_path}")
                    return False
                
                # Validate GDS files
                if name.endswith('_gds') and not self.gds_handler.validate_gds(file_path):
                    self.logger.error(f"Invalid GDS file: {file_path}")
                    return False
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error validating inputs: {str(e)}")
            return False

    def prepare_gds_merge(self) -> bool:
        """Prepare files for GDS merge."""
        try:
            output_dir = Path(self.config['output_dir'])
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Create KLayout merge script
            merge_script = """
# KLayout merge script
source_gds = input_files.split(',')
main_layout = RBA::Layout.new

# Read first GDS with LEF properties
main_layout.read(source_gds[0])
top_cell = main_layout.top_cell

# Read and merge additional GDS files
source_gds[1..-1].each do |gds|
  layout = RBA::Layout.new
  layout.read(gds)
  
  # Merge layouts preserving hierarchy
  layout.each_cell do |cell|
    if cell.is_top?
      top_cell.copy_tree(cell)
    end
  end
end

# Write merged layout
main_layout.write(output_file)
"""
            merge_script_file = output_dir / 'merge_gds.rb'
            return self.file_handler.write_file(merge_script, merge_script_file)
            
        except Exception as e:
            self.logger.error(f"Error preparing GDS merge: {str(e)}")
            return False

    def merge_gds_files(self) -> bool:
        """Merge core and SRAM GDS files."""
        try:
            output_dir = Path(self.config['output_dir'])
            input_files = [
                self.config['core_gds'],
                self.config['sram_gds']
            ]
            
            # Add any additional GDS files specified in config
            if 'additional_gds' in self.config:
                input_files.extend(self.config['additional_gds'])
            
            output_file = output_dir / 'simple_arm_merged.gds'
            
            return self.gds_handler.merge_gds_files(input_files, output_file)
            
        except Exception as e:
            self.logger.error(f"Error merging GDS files: {str(e)}")
            return False

    def run_drc(self, gds_file: Path) -> bool:
        """Run DRC on merged GDS."""
        try:
            output_dir = Path(self.config['output_dir'])
            
            # Create Magic DRC script
            drc_script = f"""
drc style drc(full)
drc euclidean on
drc count total
load {gds_file}
select top cell
drc check
drc catchup
drc stats
drc why
save {output_dir}/drc.log
quit -noprompt
"""
            
            drc_script_file = output_dir / 'run_drc.tcl'
            self.file_handler.write_file(drc_script, drc_script_file)
            
            # Run Magic DRC
            return self.file_handler.execute_command([
                'magic',
                '-dnull',
                '-noconsole',
                '-rcfile', self.config['magic_rc'],
                drc_script_file
            ])
            
        except Exception as e:
            self.logger.error(f"Error running DRC: {str(e)}")
            return False

    def run_lvs(self, gds_file: Path) -> bool:
        """Run LVS on merged GDS."""
        try:
            output_dir = Path(self.config['output_dir'])
            
            # Extract netlist from GDS
            extract_script = f"""
load {gds_file}
extract all
ext2spice hierarchy on
ext2spice scale off
ext2spice cthresh 0
ext2spice rthresh 0
ext2spice blackbox on
ext2spice subcircuit top on
ext2spice global off
ext2spice
quit -noprompt
"""
            
            extract_script_file = output_dir / 'extract_netlist.tcl'
            self.file_handler.write_file(extract_script, extract_script_file)
            
            # Run Magic extraction
            if not self.file_handler.execute_command([
                'magic',
                '-dnull',
                '-noconsole',
                '-rcfile', self.config['magic_rc'],
                extract_script_file
            ]):
                return False
            
            # Run Netgen LVS
            return self.file_handler.execute_command([
                'netgen',
                '-batch', 'lvs',
                f"{output_dir}/simple_arm_merged.spice",
                self.config['reference_netlist'],
                self.config['netgen_setup'],
                '-o', f"{output_dir}/lvs_report.txt"
            ])
            
        except Exception as e:
            self.logger.error(f"Error running LVS: {str(e)}")
            return False

    def create_final_gds(self) -> bool:
        """Create final GDS with cell abstracts."""
        try:
            output_dir = Path(self.config['output_dir'])
            merged_gds = output_dir / 'simple_arm_merged.gds'
            
            # Create final GDS script
            final_script = f"""
load {merged_gds}
flatten top_cell
select top_cell
expand
extract all
writeall force {output_dir}/simple_arm_final.gds
quit -noprompt
"""
            
            final_script_file = output_dir / 'create_final.tcl'
            self.file_handler.write_file(final_script, final_script_file)
            
            # Run Magic
            success = self.file_handler.execute_command([
                'magic',
                '-dnull',
                '-noconsole',
                '-rcfile', self.config['magic_rc'],
                final_script_file
            ])

            if success:
                self.logger.info("Final GDS creation completed successfully")
            return success
            
        except Exception as e:
            self.logger.error(f"Error creating final GDS: {str(e)}")
            return False

    def run(self) -> bool:
        """Run complete GDS creation flow."""
        try:
            self.logger.info("Starting GDS creation")
            
            # Validate inputs
            if not self.validate_inputs():
                return False
                
            # Create output directory
            output_dir = Path(self.config['output_dir'])
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Prepare GDS merge
            if not self.prepare_gds_merge():
                return False
                
            # Merge GDS files
            if not self.merge_gds_files():
                return False
                
            # Run DRC on merged GDS
            merged_gds = output_dir / 'simple_arm_merged.gds'
            if self.config.get('run_drc', True):
                if not self.run_drc(merged_gds):
                    return False
                    
            # Run LVS on merged GDS
            if self.config.get('run_lvs', True):
                if not self.run_lvs(merged_gds):
                    return False
                    
            # Create final GDS
            if not self.create_final_gds():
                return False
                
            self.logger.info("GDS creation completed successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Error in GDS creation: {str(e)}")
            return False

    def generate_reports(self) -> bool:
        """Generate summary reports."""
        try:
            output_dir = Path(self.config['output_dir'])
            final_gds = output_dir / 'simple_arm_final.gds'
            
            # Generate area report
            area_script = f"""
load {final_gds}
box
puts "Total cell area: [box area]"
quit -noprompt
"""
            area_script_file = output_dir / 'area_report.tcl'
            self.file_handler.write_file(area_script, area_script_file)
            self.file_handler.execute_command(['magic', '-dnull', '-noconsole', area_script_file])
            
            # Generate hierarchy report
            hier_script = f"""
load {final_gds}
expand
puts "Cell hierarchy:"
cellname list
quit -noprompt
"""
            hier_script_file = output_dir / 'hierarchy_report.tcl'
            self.file_handler.write_file(hier_script, hier_script_file)
            self.file_handler.execute_command(['magic', '-dnull', '-noconsole', hier_script_file])
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error generating reports: {str(e)}")
            return False

def main():
    parser = argparse.ArgumentParser(description="Create final GDS by merging core and SRAM")
    parser.add_argument("--config", required=True, help="Configuration file (JSON or YAML)")
    parser.add_argument("--output-dir", help="Output directory")
    parser.add_argument("--skip-drc", action="store_true", help="Skip DRC checks")
    parser.add_argument("--skip-lvs", action="store_true", help="Skip LVS checks")
    parser.add_argument("--no-reports", action="store_true", help="Skip report generation")
    
    args = parser.parse_args()
    
    # Load configuration
    creator = GDSCreator(args.config)
    
    # Override configuration with command line arguments
    if args.output_dir:
        creator.config['output_dir'] = args.output_dir
    if args.skip_drc:
        creator.config['run_drc'] = False
    if args.skip_lvs:
        creator.config['run_lvs'] = False
    
    # Run GDS creation
    success = creator.run()
    
    # Generate reports
    if success and not args.no_reports:
        creator.generate_reports()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()