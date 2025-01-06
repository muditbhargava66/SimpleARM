# -----------------------------------------------------------------------------
# File: init.tcl
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: OpenROAD initialization and floorplanning script
# -----------------------------------------------------------------------------

# Read configuration and settings
source ./scripts/config.tcl

# Print banner
puts "=========================================="
puts "Starting PnR Initialization for SimpleARM Core"
puts "=========================================="

# Create output directory
if {[file exists $pnr_dir]} {
    file delete -force $pnr_dir
}
file mkdir $pnr_dir

# Read synthesized netlist
read_verilog $synth_dir/simple_arm_synth.v

# Read LEF files
read_lef $tech_dir/lef/sky130.tlef
read_lef $tech_dir/lef/sky130_sram_8kx32.lef

# Read Liberty files
read_liberty $corner_dir/lib/typical.lib
read_liberty $corner_dir/lib/sky130_sram_8kx32_typical.lib

# Initialize floorplan
initialize_floorplan \
    -die_area "0 0 1500 1500" \
    -core_area "100 100 1400 1400" \
    -site "unit" \
    -tracks $tech_dir/tracks.info

# Place ports
place_pins -hor_layers Metal3 -ver_layers Metal2

# Place SRAM macro
place_macro \
    -macro_name sky130_sram_8kx32_word_0 \
    -location "400 400"

# Create power grid
# Horizontal straps
create_power_straps \
    -direction horizontal \
    -nets {VDD VSS} \
    -layer Metal4 \
    -width 2.0 \
    -pitch 40.0 \
    -spacing 5.0 \
    -start 20.0 \
    -extend_to design_boundary

# Vertical straps
create_power_straps \
    -direction vertical \
    -nets {VDD VSS} \
    -layer Metal5 \
    -width 2.0 \
    -pitch 40.0 \
    -spacing 5.0 \
    -start 20.0 \
    -extend_to design_boundary

# Connect power straps to macro
connect_macro_power_pins \
    -macro_name sky130_sram_8kx32_word_0 \
    -nets {VDD VSS}

# Create placement blockages around SRAM
create_placement_blockage \
    -name sram_blockage \
    -boundary "390 390 810 810"

# Create routing blockages for SRAM power
create_routing_blockage \
    -name sram_power_blockage \
    -layers {Metal1 Metal2} \
    -boundary "390 390 810 810"

# Add tap cells
add_tap_cells \
    -distance 20 \
    -pattern every_row \
    -prefix TAP

# Add well taps
add_well_taps \
    -cell_name WELL_TAP \
    -prefix WELL \
    -distance 40 \
    -pattern every_row

# Add decap cells
add_decap_cells \
    -cells {DECAP_CELL} \
    -prefix DECAP \
    -fill_gaps true

# Add tie cells
add_tie_cells \
    -cells {TIE_CELL} \
    -prefix TIE

# Create placement constraints
create_placement_constraint \
    -type region \
    -name core_region \
    -boundary "120 120 1380 1380"

# Set placement density
set_placement_density \
    -density 0.7 \
    -target_density 0.75

# Global placement
global_placement \
    -density 0.7 \
    -pad_left 2 \
    -pad_right 2

# Optimize power grid
analyze_power_grid \
    -net VDD \
    -vsrc_loc top \
    -output $pnr_dir/power_analysis.rpt

# Write initial DEF
write_def $pnr_dir/floorplan.def

# Generate reports
report_design_area > $pnr_dir/design_area.rpt
report_placement_density > $pnr_dir/placement_density.rpt
report_power_grid > $pnr_dir/power_grid.rpt

# Print summary
puts "=========================================="
puts "PnR Initialization Complete"
puts "----------------------------------------"
puts "Output files generated:"
puts "  - Floorplan DEF:            $pnr_dir/floorplan.def"
puts "  - Design area report:       $pnr_dir/design_area.rpt"
puts "  - Placement density report: $pnr_dir/placement_density.rpt"
puts "  - Power grid report:        $pnr_dir/power_grid.rpt"
puts "=========================================="