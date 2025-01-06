# SimpleARM Tools Installation Guide

## Required Tools Overview

### Core Tools
1. **Yosys** - RTL Synthesis
2. **OpenROAD** - Place and Route
3. **Magic** - Layout Viewer/DRC
4. **Verilator** - RTL Simulation
5. **OpenRAM** - Memory Compiler
6. **KLayout** - GDS Viewer

### PDK Requirements
- SkyWater 130nm PDK
- Open_PDKs

## System Requirements

### Minimum Requirements
- Linux-based operating system (Ubuntu 20.04 LTS recommended)
- 8GB RAM
- 50GB free disk space
- Python 3.8 or newer

### Recommended Requirements
- 16GB RAM
- 100GB SSD
- Multi-core processor
- Ubuntu 22.04 LTS

## Installation Steps

### 1. Basic System Setup
```bash
# Update system
sudo apt update
sudo apt upgrade

# Install basic dependencies
sudo apt install build-essential git python3 python3-pip cmake
```

### 2. PDK Installation

#### SkyWater PDK
```bash
# Clone PDK repository
git clone https://github.com/google/skywater-pdk
cd skywater-pdk

# Initialize PDK
make setup

# Install specific process node
make vendor/skywater-pdk/cells/sky130_fd_sc_hd
```

#### Open_PDKs
```bash
# Clone Open_PDKs
git clone https://github.com/RTimothyEdwards/open_pdks
cd open_pdks

# Configure and install
./configure --enable-sky130-pdk
make
sudo make install
```

### 3. Synthesis Tools

#### Yosys Installation
```bash
# Install dependencies
sudo apt install tcl-dev readline-dev libffi-dev

# Clone and build Yosys
git clone https://github.com/YosysHQ/yosys.git
cd yosys
make config-gcc
make -j$(nproc)
sudo make install
```

#### OpenROAD Installation
```bash
# Install dependencies
sudo apt install libboost-all-dev

# Clone and build OpenROAD
git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git
cd OpenROAD
mkdir build
cd build
cmake ..
make -j$(nproc)
sudo make install
```

### 4. Layout Tools

#### Magic Installation
```bash
# Install dependencies
sudo apt install m4 tcsh csh libx11-dev tcl-dev tk-dev

# Clone and build Magic
git clone https://github.com/RTimothyEdwards/magic
cd magic
./configure
make -j$(nproc)
sudo make install
```

#### KLayout Installation
```bash
# Install from package
sudo apt install klayout

# Or build from source
git clone https://github.com/KLayout/klayout.git
cd klayout
./build.sh -j$(nproc)
sudo ./build.sh install
```

### 5. Simulation Tools

#### Verilator Installation
```bash
# Install dependencies
sudo apt install perl flex bison

# Clone and build Verilator
git clone https://github.com/verilator/verilator
cd verilator
autoconf
./configure
make -j$(nproc)
sudo make install
```

### 6. OpenRAM Setup

#### OpenRAM Installation
```bash
# Clone OpenRAM
git clone https://github.com/VLSIDA/OpenRAM.git
cd OpenRAM

# Install Python dependencies
pip3 install -r requirements.txt

# Set environment variables
echo 'export OPENRAM_HOME="$HOME/OpenRAM"' >> ~/.bashrc
echo 'export OPENRAM_TECH="$HOME/OpenRAM/technology"' >> ~/.bashrc
source ~/.bashrc
```

## Environment Configuration

### 1. Tool Path Setup
```bash
# Add to ~/.bashrc
export PATH="$PATH:/usr/local/bin"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"
```

### 2. PDK Setup
```bash
# Add to ~/.bashrc
export PDK_ROOT="/usr/local/share/pdk"
export SKYWATER_PDK="$PDK_ROOT/sky130A"
```

### 3. Tool-specific Configuration
```bash
# Magic
mkdir -p ~/.magic
cp $PDK_ROOT/sky130A/libs.tech/magic/* ~/.magic/

# KLayout
mkdir -p ~/.klayout
cp $PDK_ROOT/sky130A/libs.tech/klayout/* ~/.klayout/
```

## Verification Steps

### 1. Check Tool Installation
```bash
# Verify tool versions
yosys --version
openroad -version
magic --version
verilator --version
klayout -v
```

### 2. Test PDK Setup
```bash
# Test Magic with PDK
magic -dnull -noconsole -rcfile $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc

# Test Klayout with PDK
klayout -l $PDK_ROOT/sky130A/libs.tech/klayout/sky130A.lyt
```

### 3. Verify OpenRAM
```bash
# Run OpenRAM test
cd $OPENRAM_HOME
python3 compiler/tests/01_library_drc_test.py
```

## Common Issues

### 1. Missing Dependencies
Problem: Tool fails to build with missing dependency
Solution: Check build logs and install required packages

### 2. PDK Integration Issues
Problem: Tools can't find PDK files
Solution: Verify environment variables and file permissions

### 3. Python Version Conflicts
Problem: Tool requires specific Python version
Solution: Use Python virtual environment

## Maintenance

### 1. Updating Tools
```bash
# Update all tools periodically
cd yosys && git pull && make && sudo make install
cd ../OpenROAD && git pull && make && sudo make install
# Repeat for other tools
```

### 2. PDK Updates
```bash
# Update PDK
cd skywater-pdk
git pull
make update
```

## Support Resources

### Documentation
- [Yosys Documentation](https://yosyshq.net/yosys/documentation.html)
- [OpenROAD Documentation](https://openroad.readthedocs.io/)
- [Magic Documentation](http://opencircuitdesign.com/magic/documentation.html)

### Community Resources
- OpenRoad Slack Channel
- Skywater PDK GitHub Issues
- Tool-specific mailing lists

---