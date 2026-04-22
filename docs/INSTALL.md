# TinyTapeout Local Hardening Setup

This guide describes how to set up the local environment to harden the SimpleARM project for TinyTapeout.

## Prerequisites
- Linux OS
- Docker (ensure your user is in the `docker` group to run containers without sudo)
- Python 3.10+
- Open-source EDA Tools: Icarus Verilog (`iverilog`), GTKWave, KLayout

## Environment Setup
1. **Set up the virtual environment:**
   ```bash
   mkdir -p ~/ttsetup
   python3 -m venv ~/ttsetup/venv
   source ~/ttsetup/venv/bin/activate
   ```

2. **Install Volare, LibreLane, and other dependencies:**
   ```bash
   pip install volare librelane==2.4.2 matplotlib gitpython chevron cairosvg gdstk python-frontmatter mistune cocotb pytest
   ```

3. **Install the Sky130 PDK:**
   ```bash
   volare fetch --pdk sky130
   volare enable --pdk sky130 $(volare ls-remote --pdk sky130 | head -1)
   ```

4. **Clone TinyTapeout Support Tools:**
   ```bash
   git clone https://github.com/TinyTapeout/tt-support-tools.git tt
   ```

5. **Configure Environment Variables:**
   Add these to your `~/.bashrc`:
   ```bash
   export PDK_ROOT=~/.volare
   export PDK=sky130A
   export LIBRELANE_TAG=2.4.2
   alias tt-activate='source ~/ttsetup/venv/bin/activate && export PDK_ROOT=~/.volare PDK=sky130A LIBRELANE_TAG=2.4.2'
   ```

## Running Simulations
- **RTL Simulation:**
  ```bash
  tt-activate
  cd test && make -B
  ```

- **Gate-Level Simulation (Post-Hardening):**
  ```bash
  cd test
  cp ../runs/wokwi/final/pnl/*.pnl.v gate_level_netlist.v
  PDK_ROOT=~/.volare make -B GATES=yes
  ```

## Local Hardening
To run the full OpenLane flow locally using LibreLane:
```bash
tt-activate
./tt/tt_tool.py --create-user-config
./tt/tt_tool.py --harden
```

## Viewing the Results
- **GDS Layout:** `./tt/tt_tool.py --open-in-klayout`
- **Render PNG:** `./tt/tt_tool.py --create-png`
- **Waveforms:** `gtkwave test/tb.vcd test/tb.gtkw`