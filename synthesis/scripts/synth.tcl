# -----------------------------------------------------------------------------
# File: synth.tcl
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Synthesis script for Yosys
# -----------------------------------------------------------------------------

# Read configuration and settings
source ./scripts/config.tcl

# Print banner
puts "=========================================="
puts "Starting Synthesis for SimpleARM Core"
puts "=========================================="

# Cleanup work directory
if {[file exists $synth_dir]} {
    file delete -force $synth_dir
}
file mkdir $synth_dir

# Read Liberty file
read_liberty $liberty_file

# Read RTL files
read_verilog $rtl_dir/core/fetch_unit.v
read_verilog $rtl_dir/core/decode_unit.v
read_verilog $rtl_dir/core/execute_unit.v
read_verilog $rtl_dir/core/register_file.v
read_verilog $rtl_dir/core/alu.v
read_verilog $rtl_dir/memory/sram_wrapper.v
read_verilog $rtl_dir/memory/memory_controller.v
read_verilog $rtl_dir/debug/jtag_controller.v
read_verilog $rtl_dir/top/simple_arm_top.v

# Read constraints
read_sdc $constraints_dir/timing.sdc

# Set top module
hierarchy -top simple_arm_top

# Generic synthesis
synth -top simple_arm_top

# Technology mapping
dfflibmap -liberty $liberty_file
abc -liberty $liberty_file

# Optimize the design
opt -purge

# Clean up the design
clean

# Flatten design (optional, commented out by default)
# flatten

# Check design
check -assert

# Write synthesized netlist
write_verilog $synth_dir/simple_arm_synth.v

# Write timing reports
write_timing_report $synth_dir/timing.rpt

# Generate area report
stat > $synth_dir/area.rpt

# Generate gate-level simulation model
write_verilog -noattr $synth_dir/simple_arm_sim.v

# Print synthesis summary
puts "=========================================="
puts "Synthesis Complete"
puts "----------------------------------------"
puts "Output files generated:"
puts "  - Synthesized netlist: $synth_dir/simple_arm_synth.v"
puts "  - Simulation model:    $synth_dir/simple_arm_sim.v"
puts "  - Timing report:       $synth_dir/timing.rpt"
puts "  - Area report:         $synth_dir/area.rpt"
puts "=========================================="