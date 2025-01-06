# SimpleARM Development Environment Setup

## Overview
This guide covers the complete setup of a development environment for the SimpleARM processor project, including directory structure, environment variables, scripts, and configuration files.

## Directory Structure

### Project Layout
```
simple-arm/
├── docs/             # Documentation
├── rtl/             # RTL source files
├── synthesis/       # Synthesis files
├── pnr/            # Place and route
├── verification/   # Verification files
├── drc_lvs/        # DRC/LVS runsets
├── openlane/       # OpenLane configuration
└── tools/          # Utility scripts
```

## Environment Setup

### 1. Environment Variables
Add to your `~/.bashrc`:
```bash
# Project root
export SIMPLEARM_ROOT="$HOME/projects/simple-arm"

# PDK setup
export PDK_ROOT="/usr/local/share/pdk"
export SKYWATER_PDK="$PDK_ROOT/sky130A"

# OpenRAM setup
export OPENRAM_HOME="$HOME/OpenRAM"
export OPENRAM_TECH="$OPENRAM_HOME/technology"

# Tool paths
export PATH="$PATH:$SIMPLEARM_ROOT/tools/scripts"
export PYTHONPATH="$PYTHONPATH:$SIMPLEARM_ROOT/tools/utils"
```

### 2. Python Virtual Environment
```bash
# Create virtual environment
python3 -m venv $SIMPLEARM_ROOT/venv

# Activate environment
source $SIMPLEARM_ROOT/venv/bin/activate

# Install requirements
pip install -r $SIMPLEARM_ROOT/requirements.txt
```

## Project Configuration

### 1. Synthesis Configuration
Create `$SIMPLEARM_ROOT/config/synth_config.json`:
```json
{
    "top_module": "simple_arm_top",
    "clock_period": 10,
    "target_library": "${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib",
    "search_path": [
        "${SIMPLEARM_ROOT}/rtl/core",
        "${SIMPLEARM_ROOT}/rtl/memory",
        "${SIMPLEARM_ROOT}/rtl/debug"
    ]
}
```

### 2. OpenLane Configuration
Create `$SIMPLEARM_ROOT/config/openlane_config.json`:
```json
{
    "DESIGN_NAME": "simple_arm_top",
    "VERILOG_FILES": [
        "dir::../rtl/core/*.v",
        "dir::../rtl/memory/*.v",
        "dir::../rtl/debug/*.v"
    ],
    "CLOCK_PORT": "clk",
    "CLOCK_PERIOD": 10.0,
    "FP_SIZING": "absolute",
    "DIE_AREA": "0 0 1500 1500",
    "PL_TARGET_DENSITY": 0.70
}
```

## Tool Configuration

### 1. Magic Setup
Create `$SIMPLEARM_ROOT/config/magic_setup.tcl`:
```tcl
# PDK configuration
tech load ${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.tech
set GDS_FILE ${SIMPLEARM_ROOT}/gds/simple_arm_final.gds
set MACROS_FILE ${PDK_ROOT}/sky130A/libs.ref/sky130_sram_macros/gds/sky130_sram_8kx32.gds

# DRC configuration
drc style drc(full)
drc euclidean on
drc report ${SIMPLEARM_ROOT}/reports/magic_drc.rpt
```

### 2. Netgen Setup
Create `$SIMPLEARM_ROOT/config/netgen_setup.tcl`:
```tcl
set NETGEN_SETUP ${PDK_ROOT}/sky130A/libs.tech/netgen/sky130A_setup.tcl
set TOP_MODULE simple_arm_top
set LAYOUT_NETLIST ${SIMPLEARM_ROOT}/netlist/layout.spice
set REFERENCE_NETLIST ${SIMPLEARM_ROOT}/netlist/reference.spice
```

## Development Workflow Setup

### 1. Git Configuration
```bash
# Initialize git repository
cd $SIMPLEARM_ROOT
git init

# Create .gitignore
cat > .gitignore << EOL
*.log
*.rpt
*.drc
*.lvs
/build/
/venv/
__pycache__/
*.pyc
*.swp
.DS_Store
EOL

# Create git hooks
mkdir -p .git/hooks
```

### 2. Pre-commit Hook
Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Run linting
verilator --lint-only rtl/core/*.v
status=$?
if [ $status -ne 0 ]; then
    echo "RTL linting failed"
    exit 1
fi

# Run Python style check
black --check tools/scripts/*.py
status=$?
if [ $status -ne 0 ]; then
    echo "Python style check failed"
    exit 1
fi

exit 0
```

## Build System Setup

### 1. Makefile Creation
Create `$SIMPLEARM_ROOT/Makefile`:
```makefile
# Default target
all: rtl synth pnr gds

# RTL simulation
rtl:
	$(MAKE) -C verification

# Synthesis
synth:
	$(MAKE) -C synthesis

# Place and route
pnr:
	$(MAKE) -C pnr

# GDS generation
gds:
	$(MAKE) -C gds

# Clean build
clean:
	rm -rf build/
	$(MAKE) -C verification clean
	$(MAKE) -C synthesis clean
	$(MAKE) -C pnr clean
```

## Verification Environment Setup

### 1. SystemVerilog Compilation Setup
Create `$SIMPLEARM_ROOT/verification/compile.f`:
```
# RTL files
${SIMPLEARM_ROOT}/rtl/core/*.v
${SIMPLEARM_ROOT}/rtl/memory/*.v
${SIMPLEARM_ROOT}/rtl/debug/*.v

# Testbench files
${SIMPLEARM_ROOT}/verification/testbench/*.sv
${SIMPLEARM_ROOT}/verification/tests/*/*.sv

# Include directories
+incdir+${SIMPLEARM_ROOT}/rtl/include
+incdir+${SIMPLEARM_ROOT}/verification/include
```

### 2. Coverage Configuration
Create `$SIMPLEARM_ROOT/verification/coverage.cfg`:
```
# Coverage configuration
-covfile ${SIMPLEARM_ROOT}/verification/coverage.ccf
+cover=bsf
+cover=fsm
+cover=branch
+cover=statement
```

## Continuous Integration Setup

### 1. GitHub Actions
Create `.github/workflows/ci.yml`:
```yaml
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Environment
      run: |
        source setup_env.sh
        
    - name: Run Tests
      run: make test
      
    - name: Run Synthesis
      run: make synth
```

## Documentation Setup

### 1. Sphinx Documentation
```bash
# Initialize Sphinx
cd $SIMPLEARM_ROOT/docs
sphinx-quickstart

# Install theme
pip install sphinx_rtd_theme
```

### 2. Doxygen Setup
Create `$SIMPLEARM_ROOT/docs/Doxyfile`:
```
PROJECT_NAME = "SimpleARM"
INPUT = ../rtl ../verification
RECURSIVE = YES
EXTRACT_ALL = YES
GENERATE_HTML = YES
GENERATE_LATEX = NO
```

## Testing the Setup

### 1. Verify Environment
```bash
# Test environment variables
echo $SIMPLEARM_ROOT
echo $PDK_ROOT

# Test tool installation
yosys -version
openroad -version
magic --version
verilator --version
```

### 2. Run Initial Build
```bash
cd $SIMPLEARM_ROOT
make clean
make all
```

## Common Issues and Solutions

### 1. PDK Integration
Problem: Tools can't find PDK files
Solution: Verify PDK_ROOT and SKYWATER_PDK paths

### 2. Python Dependencies
Problem: Missing Python packages
Solution: Reinstall requirements in virtual environment

### 3. Tool Configuration
Problem: Tool-specific setup issues
Solution: Check individual tool configuration files

## Support and Maintenance

### 1. Regular Updates
```bash
# Update project dependencies
pip install --upgrade -r requirements.txt

# Update PDK
cd $PDK_ROOT && git pull
```

### 2. Backup Procedures
```bash
# Backup configuration
tar -czf config_backup.tar.gz config/

# Backup results
tar -czf results_backup.tar.gz results/
```

---