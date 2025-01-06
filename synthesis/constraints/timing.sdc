# -----------------------------------------------------------------------------
# File: timing.sdc
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Timing constraints for synthesis
# -----------------------------------------------------------------------------

# Operating conditions
set_operating_conditions typical

# Clock definition
create_clock -name clk -period 10 [get_ports clk]
create_clock -name tck -period 100 [get_ports tck]

# Clock uncertainty
set_clock_uncertainty 0.1 [get_clocks clk]
set_clock_uncertainty 0.2 [get_clocks tck]

# Clock transition
set_clock_transition 0.12 [get_clocks clk]
set_clock_transition 0.15 [get_clocks tck]

# Input delays
set_input_delay -clock clk -max 2.0 [remove_from_collection [all_inputs] [get_ports {clk tck}]]
set_input_delay -clock clk -min 0.2 [remove_from_collection [all_inputs] [get_ports {clk tck}]]
set_input_delay -clock tck -max 5.0 [get_ports {tms tdi trst_n}]
set_input_delay -clock tck -min 0.5 [get_ports {tms tdi trst_n}]

# Output delays
set_output_delay -clock clk -max 2.0 [remove_from_collection [all_outputs] [get_ports tdo]]
set_output_delay -clock clk -min 0.2 [remove_from_collection [all_outputs] [get_ports tdo]]
set_output_delay -clock tck -max 5.0 [get_ports tdo]
set_output_delay -clock tck -min 0.5 [get_ports tdo]

# Clock groups
set_clock_groups -asynchronous -group {clk} -group {tck}

# Maximum transition time
set_max_transition 0.5 [current_design]

# Maximum fanout
set_max_fanout 20 [current_design]

# Maximum capacitance
set_max_capacitance 0.5 [current_design]

# False paths
set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports trst_n]

# Multicycle paths
# JTAG interface can be slower
set_multicycle_path -setup 4 -from [get_clocks tck] -to [get_clocks clk]
set_multicycle_path -hold 3 -from [get_clocks tck] -to [get_clocks clk]
set_multicycle_path -setup 4 -from [get_clocks clk] -to [get_clocks tck]
set_multicycle_path -hold 3 -from [get_clocks clk] -to [get_clocks tck]

# Memory interface timing
# Adjust these based on your specific SRAM timing requirements
set_input_delay -clock clk -max 2.0 [get_ports {sram_rdata[*]}]
set_input_delay -clock clk -min 0.2 [get_ports {sram_rdata[*]}]
set_output_delay -clock clk -max 2.0 [get_ports {sram_addr[*] sram_wdata[*] sram_cs_n sram_we_n sram_be_n[*]}]
set_output_delay -clock clk -min 0.2 [get_ports {sram_addr[*] sram_wdata[*] sram_cs_n sram_we_n sram_be_n[*]}]

# Register to register paths
set reg2reg_max_delay [expr 0.7 * 10.0]  
# 70% of clock period for reg2reg paths
set_max_delay $reg2reg_max_delay -from [all_registers] -to [all_registers]

# Input to register paths
set in2reg_max_delay [expr 0.3 * 10.0]   
# 30% of clock period for in2reg paths
set_max_delay $in2reg_max_delay -from [all_inputs] -to [all_registers]

# Register to output paths
set reg2out_max_delay [expr 0.3 * 10.0]  
# 30% of clock period for reg2out paths
set_max_delay $reg2out_max_delay -from [all_registers] -to [all_outputs]

# Exception paths for debugging logic
set_false_path -through [get_pins -hierarchical *debug*]

# Case analysis for reset signals
set_case_analysis 0 [get_ports rst_n]
set_case_analysis 0 [get_ports trst_n]