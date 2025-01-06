#!/usr/bin/env python3
# -----------------------------------------------------------------------------
# File: generate_sram.py
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Generate SRAM using OpenRAM
# -----------------------------------------------------------------------------

import os
import sys
import argparse
import logging
import shutil
from pathlib import Path
from typing import Dict, Optional, List
import yaml
import json
from datetime import datetime
from file_handlers import FileHandler, LEFFileHandler

class SRAMGenerator:
    """Generate SRAM using OpenRAM."""
    
    def __init__(self, config_file: str):
        """Initialize with configuration file."""
        self.config_file = config_file
        self.config = self._load_config()
        self.file_handler = FileHandler(self.config.get('output_dir', '.'))
        self.lef_handler = LEFFileHandler(self.config.get('output_dir', '.'))
        self.setup_logging()
        self.verify_openram_setup()

    def setup_logging(self):
        """Setup logging configuration."""
        log_dir = Path(self.config.get('log_dir', 'logs'))
        log_dir.mkdir(parents=True, exist_ok=True)
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        log_file = log_dir / f'sram_generation_{timestamp}.log'
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)

    def verify_openram_setup(self):
        """Verify OpenRAM environment setup."""
        required_vars = ['OPENRAM_HOME', 'OPENRAM_TECH']
        missing_vars = [var for var in required_vars if var not in os.environ]
        
        if missing_vars:
            raise EnvironmentError(
                f"Required environment variables not set: {', '.join(missing_vars)}\n"
                "Please set these variables before running the script."
            )
        
        # Verify OpenRAM installation
        openram_home = Path(os.environ['OPENRAM_HOME'])
        if not (openram_home / 'compiler').exists():
            raise EnvironmentError(
                "OpenRAM installation not found or incomplete.\n"
                "Please verify your OpenRAM installation."
            )

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

    def validate_config(self) -> bool:
        """Validate configuration parameters."""
        required_params = {
            'word_size': (int, lambda x: x > 0 and x % 8 == 0),
            'num_words': (int, lambda x: x > 0 and (x & (x-1)) == 0),  # Power of 2
            'num_banks': (int, lambda x: x > 0),
            'process': (str, None),
            'voltage': (float, lambda x: 0 < x <= 2.0),
            'frequency': (float, lambda x: x > 0),
            'temp': (float, None)
        }

        for param, (param_type, validator) in required_params.items():
            if param not in self.config:
                self.logger.error(f"Missing required parameter: {param}")
                return False
                
            value = self.config[param]
            if not isinstance(value, param_type):
                self.logger.error(f"Invalid type for {param}: expected {param_type}, got {type(value)}")
                return False
                
            if validator and not validator(value):
                self.logger.error(f"Invalid value for {param}: {value}")
                return False

        return True

    def generate_openram_config(self) -> Optional[Path]:
        """Generate OpenRAM configuration file."""
        try:
            config_template = """
### OpenRAM SRAM Configuration ###
# Technology parameters
tech_name = "{process}"
process_corners = ["TT"]
supply_voltages = {voltage}
temperatures = {temp}

# SRAM organization parameters
num_words = {num_words}
word_size = {word_size}
num_banks = {num_banks}
num_rw_ports = 1
num_r_ports = 0
num_w_ports = 0

# Custom cell names
custom_cell_names = {custom_cells}

# Operating parameters
slew_rate = 0.001
load = 0.05
operating_temperature = {temp}
operating_voltage = {voltage}
operating_frequency = {frequency}

# Design configurations
route_supplies = True
check_lvsdrc = {check_lvsdrc}
perimeter_pins = True
inline_lvsdrc = False
uniquify = True

# Layout parameters
symmetric = True
netlist_only = False
analytical_delay = False
output_extended_config = True
output_datasheet = True
output_name = "{output_name}"
            """
            
            config = config_template.format(
                process=self.config['process'],
                voltage=self.config['voltage'],
                temp=self.config['temp'],
                num_words=self.config['num_words'],
                word_size=self.config['word_size'],
                num_banks=self.config['num_banks'],
                custom_cells=self.config.get('custom_cells', []),
                check_lvsdrc=self.config.get('check_lvsdrc', True),
                frequency=self.config.get('frequency', 100e6),
                output_name=self.config.get('ram_name', 'sky130_sram_8kx32')
            )
            
            output_dir = Path(self.config['output_dir'])
            config_file = output_dir / 'openram_config.py'
            self.file_handler.write_file(config, config_file)
            return config_file
            
        except Exception as e:
            self.logger.error(f"Error generating OpenRAM config: {str(e)}")
            return None

    def run_openram(self, config_file: Path) -> bool:
        """Run OpenRAM compiler."""
        try:
            openram_script = Path(os.environ['OPENRAM_HOME']) / 'openram.py'
            output_dir = Path(self.config['output_dir']) / 'sram_output'
            
            command = [
                sys.executable,
                str(openram_script),
                str(config_file),
                '-o', str(output_dir),
                '--quiet'
            ]
            
            if self.config.get('num_threads'):
                command.extend(['-t', str(self.config['num_threads'])])
            
            return self.file_handler.execute_command(command)
            
        except Exception as e:
            self.logger.error(f"Error running OpenRAM: {str(e)}")
            return False

    def generate_views(self) -> bool:
        """Generate various views (Verilog, LEF, Liberty) from GDS."""
        try:
            output_dir = Path(self.config['output_dir']) / 'sram_output'
            ram_name = self.config.get('ram_name', 'sky130_sram_8kx32')
            
            # Generate LEF
            lef_script = f"""
lef write {output_dir}/{ram_name}.lef -hide_empty_pins
            """
            self._run_magic_script(lef_script, "generate_lef.tcl")
            
            # Generate Liberty timing file
            self._generate_liberty_file(output_dir, ram_name)
            
            # Generate Verilog model
            self._generate_verilog_model(output_dir, ram_name)
            
            # Generate CDL netlist
            self._generate_cdl(output_dir, ram_name)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error generating views: {str(e)}")
            return False

    def _generate_liberty_file(self, output_dir: Path, ram_name: str):
        """Generate Liberty timing file."""
        liberty_template = """
library({ram_name}) {{
    delay_model : "table_lookup";
    time_unit : "1ns";
    voltage_unit : "1V";
    current_unit : "1mA";
    resistance_unit : "1kohm";
    capacitive_load_unit(1,pf);
    
    nom_process : 1.0;
    nom_temperature : {temp};
    nom_voltage : {voltage};
    
    operating_conditions(typical) {{
        process : 1.0;
        temperature : {temp};
        voltage : {voltage};
    }}
    
    cell({ram_name}) {{
        memory() {{
            type : ram;
            address_width : {addr_width};
            word_width : {word_size};
        }}
        
        interface_timing : true;
        pin(clk0) {{
            direction : input;
            clock : true;
            max_transition : 0.15;
        }}
        
        pin(csb0) {{
            direction : input;
            timing() {{
                related_pin : "clk0";
                timing_type : setup_rising;
                rise_constraint(scalar) {{
                    values("0.200");
                }}
                fall_constraint(scalar) {{
                    values("0.200");
                }}
            }}
        }}
        
        // Additional timing constraints...
    }}
}}
        """
        
        addr_width = self.config['num_words'].bit_length() - 1
        liberty_content = liberty_template.format(
            ram_name=ram_name,
            temp=self.config['temp'],
            voltage=self.config['voltage'],
            addr_width=addr_width,
            word_size=self.config['word_size']
        )
        
        liberty_file = output_dir / f'{ram_name}.lib'
        self.file_handler.write_file(liberty_content, liberty_file)

    def _generate_verilog_model(self, output_dir: Path, ram_name: str):
        """Generate Verilog behavioral model."""
        verilog_template = """
module {ram_name} (
    input wire clk0,
    input wire csb0,
    input wire web0,
    input wire [{addr_width}-1:0] addr0,
    input wire [{word_size}-1:0] din0,
    output reg [{word_size}-1:0] dout0
);
    // Memory array
    reg [{word_size}-1:0] mem[0:{num_words}-1];
    
    // Synchronous write
    always @(posedge clk0) begin
        if (!csb0 && !web0) begin
            mem[addr0] <= din0;
        end
    end
    
    // Synchronous read
    always @(posedge clk0) begin
        if (!csb0 && web0) begin
            dout0 <= mem[addr0];
        end
    end
endmodule
        """
        
        addr_width = self.config['num_words'].bit_length() - 1
        verilog_content = verilog_template.format(
            ram_name=ram_name,
            addr_width=addr_width,
            word_size=self.config['word_size'],
            num_words=self.config['num_words']
        )
        
        verilog_file = output_dir / f'{ram_name}.v'
        self.file_handler.write_file(verilog_content, verilog_file)

    def _generate_cdl(self, output_dir: Path, ram_name: str):
        """Generate CDL netlist."""
        cdl_script = f"""
ext2spice hierarchy on
ext2spice format ngspice
ext2spice subcircuit top on
ext2spice global off
extract all
ext2spice
        """
        self._run_magic_script(cdl_script, "generate_cdl.tcl")

    def _run_magic_script(self, script_content: str, script_name: str) -> bool:
        """Run Magic script."""
        try:
            output_dir = Path(self.config['output_dir'])
            script_file = output_dir / script_name
            self.file_handler.write_file(script_content, script_file)
            
            return self.file_handler.execute_command([
                'magic',
                '-dnull',
                '-noconsole',
                '-rcfile', self.config['magic_rc'],
                script_file
            ])
            
        except Exception as e:
            self.logger.error(f"Error running Magic script: {str(e)}")
            return False

    def verify_outputs(self) -> bool:
        """Verify generated outputs."""
        output_dir = Path(self.config['output_dir']) / 'sram_output'
        ram_name = self.config.get('ram_name', 'sky130_sram_8kx32')
        
        required_files = [
            f'{ram_name}.gds',
            f'{ram_name}.lef',
            f'{ram_name}.lib',
            f'{ram_name}.v',
            f'{ram_name}.spice'
        ]
        
        for file_name in required_files:
            file_path = output_dir / file_name
            if not file_path.exists():
                self.logger.error(f"Missing required output file: {file_name}")
                return False
        
        return True

    def run(self) -> bool:
        """Run complete SRAM generation flow."""
        try:
            self.logger.info("Starting SRAM generation")
            
            # Validate configuration
            if not self.validate_config():
                return False
            
            # Create output directory
            output_dir = Path(self.config['output_dir'])
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Generate OpenRAM configuration
            config_file = self.generate_openram_config()
            if not config_file:
                return False
            
            # Run OpenRAM
            if not self.run_openram(config_file):
                return False
            
            # Generate views
            if not self.generate_views():
                return False
            
            # Verify outputs
            if not self.verify_outputs():
                return False
            
            self.logger.info("SRAM generation completed successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Error in SRAM generation: {str(e)}")
            return False

def main():
    parser = argparse.ArgumentParser(description="Generate SRAM using OpenRAM")
    parser.add_argument("--config", required=True, help="Configuration file (JSON or YAML)")
    parser.add_argument("--output-dir", help="Output directory")
    parser.add_argument("--num-threads", type=int, help="Number of threads for OpenRAM")
    parser.add_argument("--skip-lvs", action="store_true", help="Skip LVS checks")
    parser.add_argument("--skip-drc", action="store_true", help="Skip DRC checks")
    parser.add_argument("--tech", help="Override technology (e.g., sky130)")
    parser.add_argument("--voltage", type=float, help="Override operating voltage")
    parser.add_argument("--frequency", type=float, help="Override operating frequency")
    parser.add_argument("--temp", type=float, help="Override operating temperature")
    parser.add_argument("--debug", action="store_true", help="Enable debug output")
    
    args = parser.parse_args()
    
    # Setup debug logging if requested
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        # Load configuration
        generator = SRAMGenerator(args.config)
        
        # Override configuration with command line arguments
        if args.output_dir:
            generator.config['output_dir'] = args.output_dir
        if args.num_threads:
            generator.config['num_threads'] = args.num_threads
        if args.skip_lvs:
            generator.config['check_lvsdrc'] = False
        if args.skip_drc:
            generator.config['check_lvsdrc'] = False
        if args.tech:
            generator.config['process'] = args.tech
        if args.voltage:
            generator.config['voltage'] = args.voltage
        if args.frequency:
            generator.config['frequency'] = args.frequency
        if args.temp:
            generator.config['temp'] = args.temp
        
        # Run SRAM generation
        success = generator.run()
        
        # Exit with appropriate status
        sys.exit(0 if success else 1)
        
    except Exception as e:
        logging.error(f"Fatal error: {str(e)}")
        if args.debug:
            raise
        sys.exit(1)

if __name__ == "__main__":
    main()