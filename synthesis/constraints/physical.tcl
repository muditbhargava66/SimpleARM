# -----------------------------------------------------------------------------
# File: physical.tcl
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Physical constraints for synthesis and layout
# -----------------------------------------------------------------------------

# Define unit and precision for the design
set_units -time ns -capacitance pF -current mA -voltage V -resistance kOhm

# Core area and utilization
set core_width 1000
set core_height 1000
set core_margin 10
set core_utilization 0.7

set_die_area -coordinate [list 0 0 [expr $core_width + 2*$core_margin] [expr $core_height + 2*$core_margin]]
set_core_area -coordinate [list $core_margin $core_margin $core_width $core_height]

# Power ring configuration
create_power_rings -nets {VDD VSS} \
    -width 5 \
    -spacing 2 \
    -offset 2 \
    -starts_with POWER

# Power stripes configuration
create_power_stripes -nets {VDD VSS} \
    -width 2 \
    -spacing 20 \
    -layer Metal3 \
    -direction vertical

# Pin placement constraints
# Clock and reset pins
set_pin_physical_constraints -pin_name clk -layer Metal6 -location {5 500}
set_pin_physical_constraints -pin_name rst_n -layer Metal6 -location {5 480}

# JTAG interface pins
set_pin_physical_constraints -pin_name tck -layer Metal6 -location {5 450}
set_pin_physical_constraints -pin_name tms -layer Metal6 -location {5 430}
set_pin_physical_constraints -pin_name tdi -layer Metal6 -location {5 410}
set_pin_physical_constraints -pin_name tdo -layer Metal6 -location {5 390}
set_pin_physical_constraints -pin_name trst_n -layer Metal6 -location {5 370}

# Memory interface pins
# Address bus
set addr_spacing 15
set addr_start_y 300
for {set i 0} {$i < 13} {incr i} {
    set y_loc [expr $addr_start_y - ($i * $addr_spacing)]
    set_pin_physical_constraints -pin_name "sram_addr\[$i\]" -layer Metal6 -location [list 995 $y_loc]
}

# Data bus
set data_spacing 15
set data_start_y 300
for {set i 0} {$i < 32} {incr i} {
    set y_loc [expr $data_start_y - ($i * $data_spacing)]
    set_pin_physical_constraints -pin_name "sram_wdata\[$i\]" -layer Metal6 -location [list 5 $y_loc]
    set_pin_physical_constraints -pin_name "sram_rdata\[$i\]" -layer Metal6 -location [list 995 $y_loc]
}

# Control signals
set_pin_physical_constraints -pin_name sram_cs_n -layer Metal6 -location {995 150}
set_pin_physical_constraints -pin_name sram_we_n -layer Metal6 -location {995 130}
for {set i 0} {$i < 4} {incr i} {
    set y_loc [expr 110 - ($i * 20)]
    set_pin_physical_constraints -pin_name "sram_be_n\[$i\]" -layer Metal6 -location [list 995 $y_loc]
}

# Placement blockages for memory macro
create_placement_blockage -name sram_block \
    -coordinate [list 400 400 800 800]

# Routing blockages for memory macro power
create_routing_blockage -name sram_power_block \
    -coordinate [list 390 390 810 810] \
    -layers {Metal1 Metal2}

# DRC and spacing rules
set_spacing_rules -rule min_spacing -value 0.14 -layer Metal1
set_spacing_rules -rule min_spacing -value 0.14 -layer Metal2
set_spacing_rules -rule min_spacing -value 0.14 -layer Metal3
set_spacing_rules -rule min_spacing -value 0.28 -layer Metal4
set_spacing_rules -rule min_spacing -value 0.28 -layer Metal5
set_spacing_rules -rule min_spacing -value 0.28 -layer Metal6

# Wire width rules
set_wire_width_rules -rule min_width -value 0.14 -layer Metal1
set_wire_width_rules -rule min_width -value 0.14 -layer Metal2
set_wire_width_rules -rule min_width -value 0.14 -layer Metal3
set_wire_width_rules -rule min_width -value 0.28 -layer Metal4
set_wire_width_rules -rule min_width -value 0.28 -layer Metal5
set_wire_width_rules -rule min_width -value 0.28 -layer Metal6

# Antenna rules
set_antenna_rules -ratio 50 -layer Metal1
set_antenna_rules -ratio 50 -layer Metal2
set_antenna_rules -ratio 50 -layer Metal3
set_antenna_rules -ratio 100 -layer Metal4
set_antenna_rules -ratio 100 -layer Metal5
set_antenna_rules -ratio 100 -layer Metal6

# Density rules
set_density_rules -min_density 20 -max_density 80 -layer Metal1
set_density_rules -min_density 20 -max_density 80 -layer Metal2
set_density_rules -min_density 20 -max_density 80 -layer Metal3
set_density_rules -min_density 20 -max_density 80 -layer Metal4
set_density_rules -min_density 20 -max_density 80 -layer Metal5
set_density_rules -min_density 20 -max_density 80 -layer Metal6