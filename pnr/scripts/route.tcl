# -----------------------------------------------------------------------------
# File: route.tcl
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: OpenROAD routing script
# -----------------------------------------------------------------------------

# Read configuration and settings
source ./scripts/config.tcl

# Print banner
puts "=========================================="
puts "Starting Routing for SimpleARM Core"
puts "=========================================="

# Read floorplan DEF
read_def $pnr_dir/floorplan.def

# Set routing layers
set_routing_layers \
    -signal_layers "Metal2-Metal6" \
    -clock_layers "Metal4-Metal6"

# Set route guides
create_route_guide \
    -layers {Metal2 Metal3 Metal4 Metal5 Metal6} \
    -spaces {0.14 0.14 0.28 0.28 0.28} \
    -widths {0.14 0.14 0.28 0.28 0.28}

# Set non-default rules
create_ndr -name "clock_ndr" \
    -width_multiplier 2 \
    -spacing_multiplier 2

create_ndr -name "reset_ndr" \
    -width_multiplier 1.5 \
    -spacing_multiplier 1.5

# Apply NDRs
set_routing_rule -rule "clock_ndr" -net "clk"
set_routing_rule -rule "reset_ndr" -net "rst_n"

# Clock routing
route_clocks \
    -nets {clk} \
    -layer_min Metal4 \
    -layer_max Metal6 \
    -max_routing_layer Metal6

# Route power nets
route_power_nets \
    -nets {VDD VSS} \
    -global_routing_layer_min Metal4 \
    -global_routing_layer_max Metal6 \
    -detail_routing_layer_min Metal1 \
    -detail_routing_layer_max Metal6

# Global routing
global_route \
    -guide_file $pnr_dir/route_guide.guide \
    -overflow_iterations 50 \
    -max_routing_layer Metal6 \
    -capacity_adjustment 0.85

# Track assignment
track_assignment \
    -overflow_iterations 50 \
    -max_routing_layer Metal6

# Detailed routing
detailed_route \
    -guide $pnr_dir/route_guide.guide \
    -max_routing_layer Metal6 \
    -via_in_pin_bottom_layer Metal1 \
    -via_in_pin_top_layer Metal6 \
    -bottom_routing_layer Metal2 \
    -top_routing_layer Metal6 \
    -via_use_rules default \
    -droute_end_iteration 50 \
    -allowDRVia true \
    -verbose 1

# Post-route optimization
optimize_routes \
    -max_routing_layer Metal6 \
    -irdrop_aware true \
    -timing_driven true

# Run DRC check
check_routes -extra_space 0

# Analyze routing congestion
analyze_congestion \
    -layers {Metal2 Metal3 Metal4 Metal5 Metal6} \
    -output $pnr_dir/congestion.rpt

# Generate reports
report_routing > $pnr_dir/routing.rpt
report_wire_lengths > $pnr_dir/wire_lengths.rpt
report_design_area > $pnr_dir/final_area.rpt

# Analyze timing
report_timing \
    -corner typical \
    -output $pnr_dir/post_route_timing.rpt

# Check IR drop
analyze_power_grid \
    -net VDD \
    -vsrc_loc top \
    -output $pnr_dir/post_route_power.rpt

# Write final outputs
write_def $pnr_dir/final.def
write_spef $pnr_dir/final.spef
write_verilog $pnr_dir/final.v
write_sdf $pnr_dir/final.sdf

# Generate GDS
write_gds $pnr_dir/final.gds \
    -units 1000 \
    -version 5.8

# Print summary
puts "=========================================="
puts "Routing Complete"
puts "----------------------------------------"
puts "Output files generated:"
puts "  - Final DEF:          $pnr_dir/final.def"
puts "  - Final SPEF:         $pnr_dir/final.spef"
puts "  - Final Verilog:      $pnr_dir/final.v"
puts "  - Final SDF:          $pnr_dir/final.sdf"
puts "  - Final GDS:          $pnr_dir/final.gds"
puts "  - Routing report:     $pnr_dir/routing.rpt"
puts "  - Wire length report: $pnr_dir/wire_lengths.rpt"
puts "  - Final area report:  $pnr_dir/final_area.rpt"
puts "  - Timing report:      $pnr_dir/post_route_timing.rpt"
puts "  - Power report:       $pnr_dir/post_route_power.rpt"
puts "  - Congestion report:  $pnr_dir/congestion.rpt"
puts "=========================================="

exit