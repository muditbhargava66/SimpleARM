# -----------------------------------------------------------------------------
# File: power.tcl
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Power analysis script
# -----------------------------------------------------------------------------

# Read configuration and settings
source ./scripts/config.tcl

# Print banner
puts "=========================================="
puts "Starting Power Analysis for SimpleARM Core"
puts "=========================================="

# Create output directory
if {[file exists $power_dir]} {
    file delete -force $power_dir
}
file mkdir $power_dir

# Read synthesized netlist
read_verilog $synth_dir/simple_arm_synth.v

# Read Liberty files
read_liberty -min $corner_dir/lib/typical.lib
read_liberty -max $corner_dir/lib/typical.lib

# Read SDC constraints
read_sdc $constraints_dir/timing.sdc

# Read SAIF or VCD file for switching activity
if {[file exists $activity_file]} {
    read_saif -input $activity_file -instance top/simple_arm_top
} else {
    puts "Warning: No switching activity file found. Using default toggle rates."
}

# Set operating conditions
set_operating_conditions -min typical -max typical

# Set analysis mode
set_power_analysis_mode \
    -reset_probability 0.05 \
    -glitch_probability 0.02 \
    -sequential_propagation true

# Clock definitions for power analysis
create_clock -name clk -period 10 [get_ports clk]
create_clock -name tck -period 100 [get_ports tck]

# Set clock activity
set_clock_activity 1.0 clk
set_clock_activity 0.1 tck

# Set default switching activity
set_switching_activity \
    -rise 0.2 \
    -fall 0.2 \
    -toggle_rate 0.2 \
    -static_probability 0.5 \
    -type inputs

# Set specific switching activities for different blocks
# Fetch Unit
set_switching_activity \
    -rise 0.3 \
    -fall 0.3 \
    -toggle_rate 0.3 \
    -type register \
    -instance fetch_unit_inst/*

# Memory Controller
set_switching_activity \
    -rise 0.25 \
    -fall 0.25 \
    -toggle_rate 0.25 \
    -type register \
    -instance memory_controller_inst/*

# JTAG Interface (low activity)
set_switching_activity \
    -rise 0.05 \
    -fall 0.05 \
    -toggle_rate 0.05 \
    -type register \
    -instance jtag_controller_inst/*

# Update power numbers
update_power

# Generate power reports
# Summary report
report_power -hierarchy > $power_dir/power_hier.rpt

# Detailed power report by instance
report_power -hierarchy -levels 3 > $power_dir/power_hier_detailed.rpt

# Power report by cell type
report_power -by_cell > $power_dir/power_by_cell.rpt

# Generate switching activity report
report_switching_activity > $power_dir/switching.rpt

# Generate clock tree power report
report_clock_power > $power_dir/clock_power.rpt

# Generate leakage power report
report_leakage_power > $power_dir/leakage.rpt

# Generate power grid analysis report
analyze_power_grid \
    -nets {VDD VSS} \
    -voltage_drop \
    -em \
    -output $power_dir/power_grid.rpt

# Temperature analysis
if {$enable_thermal_analysis} {
    analyze_thermal \
        -power_instance_list "all" \
        -ambient_temp 25 \
        -output $power_dir/thermal.rpt
}

# Write power constraints for P&R
write_power_constraints $power_dir/power_constraints.tcl

# Generate power map for visualization
generate_power_map -avg -peak -output $power_dir/power_map

# Print summary
puts "=========================================="
puts "Power Analysis Complete"
puts "----------------------------------------"
puts "Output files generated:"
puts "  - Hierarchical power report:    $power_dir/power_hier.rpt"
puts "  - Detailed power report:        $power_dir/power_hier_detailed.rpt"
puts "  - Power by cell report:         $power_dir/power_by_cell.rpt"
puts "  - Switching activity report:    $power_dir/switching.rpt"
puts "  - Clock power report:           $power_dir/clock_power.rpt"
puts "  - Leakage power report:         $power_dir/leakage.rpt"
puts "  - Power grid analysis report:   $power_dir/power_grid.rpt"
if {$enable_thermal_analysis} {
    puts "  - Thermal analysis report:      $power_dir/thermal.rpt"
}
puts "  - Power constraints:            $power_dir/power_constraints.tcl"
puts "  - Power map:                    $power_dir/power_map"
puts "=========================================="

exit