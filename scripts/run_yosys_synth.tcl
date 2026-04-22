# -----------------------------------------------------------------------------
# File: run_yosys_synth.tcl
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Working Yosys synthesis script (simplified, no external dependencies)
# Usage: cd /home/mudit/Projects/SimpleARM && yosys scripts/run_yosys_synth.tcl
# -----------------------------------------------------------------------------

# Print banner
puts "=========================================="
puts "Starting Synthesis for SimpleARM Core"
puts "=========================================="

# Read RTL files
read_verilog rtl/core/fetch_unit.v
read_verilog rtl/core/decode_unit.v
read_verilog rtl/core/execute_unit.v
read_verilog rtl/core/register_file.v
read_verilog rtl/core/alu.v
read_verilog rtl/memory/memory_controller.v

# Create a blackbox for SRAM (since we don't have actual OpenRAM macro)
read_verilog -defer <<EOF
(* blackbox *)
module sky130_sram_8kx32_word (
    input         clk0,
    input         csb0,
    input         web0,
    input  [3:0]  wmask0,
    input  [12:0] addr0,
    input  [31:0] din0,
    output [31:0] dout0
);
endmodule
EOF

read_verilog rtl/memory/sram_wrapper.v
read_verilog rtl/debug/jtag_controller.v
read_verilog rtl/top/simple_arm_top.v

# Set top module
hierarchy -check -top simple_arm_top

# Generic synthesis
proc
opt
memory
opt

# Perform synthesis
synth -top simple_arm_top

# Check design for issues
check

# Generate area statistics
tee -o synthesis_stats.txt stat

puts "=========================================="
puts "Synthesis Complete - Statistics above"
puts "=========================================="
