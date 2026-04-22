#!/bin/bash
# -----------------------------------------------------------------------------
# File: run_verilator.sh
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Script to run Verilator simulation
# Usage: cd /home/mudit/Projects/SimpleARM && bash scripts/run_verilator.sh
# -----------------------------------------------------------------------------

set -e

echo "=========================================="
echo "SimpleARM Verilator Simulation"
echo "=========================================="

# Create simulation directory
mkdir -p sim_verilator
cd sim_verilator

# Verilator compilation with warning suppression
echo "Compiling with Verilator..."
verilator --cc --trace --exe \
    -Wno-IMPLICIT \
    -Wno-WIDTH \
    -Wno-UNSIGNED \
    -Wno-CMPCONST \
    -Wno-CASEINCOMPLETE \
    -I../rtl/core \
    -I../rtl/memory \
    -I../rtl/debug \
    -I../rtl/top \
    --top-module simple_arm_top \
    ../rtl/core/alu.v \
    ../rtl/core/fetch_unit.v \
    ../rtl/core/decode_unit.v \
    ../rtl/core/execute_unit.v \
    ../rtl/core/register_file.v \
    ../rtl/memory/memory_controller.v \
    ../rtl/memory/sram_wrapper.v \
    ../verification/testbench/verilator_sram_stub.v \
    ../rtl/debug/jtag_controller.v \
    ../rtl/top/simple_arm_top.v \
    ../verification/testbench/verilator_tb.cpp

# Build the executable
echo "Building simulation..."
make -j$(nproc) -C obj_dir -f Vsimple_arm_top.mk Vsimple_arm_top

# Run the simulation
echo "Running simulation..."
./obj_dir/Vsimple_arm_top

echo "=========================================="
echo "Simulation complete!"
echo "VCD trace: sim_verilator/simple_arm_trace.vcd"
echo "=========================================="
