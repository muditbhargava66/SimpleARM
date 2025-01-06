# -----------------------------------------------------------------------------
# File: drc_rules.rs
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Magic DRC rule deck for Sky130 process
# -----------------------------------------------------------------------------

verbose 1
drc_prefix DRC
catch {load sky130.tech}
tech load sky130 -noundostack

# Layer definitions
layers_def {
    Metal1 1
    Metal2 2
    Metal3 3
    Metal4 4
    Metal5 5
    Metal6 6
    Via1   7
    Via2   8
    Via3   9
    Via4   10
    Via5   11
}

# Basic width and spacing rules
width Metal1 0.14
width Metal2 0.14
width Metal3 0.14
width Metal4 0.28
width Metal5 0.28
width Metal6 0.28

spacing Metal1 Metal1 0.14
spacing Metal2 Metal2 0.14
spacing Metal3 Metal3 0.14
spacing Metal4 Metal4 0.28
spacing Metal5 Metal5 0.28
spacing Metal6 Metal6 0.28

# Via rules
via_size Via1 0.15 0.15
via_size Via2 0.15 0.15
via_size Via3 0.20 0.20
via_size Via4 0.20 0.20
via_size Via5 0.20 0.20

via_spacing Via1 Via1 0.17
via_spacing Via2 Via2 0.17
via_spacing Via3 Via3 0.22
via_spacing Via4 Via4 0.22
via_spacing Via5 Via5 0.22

# Special rules for power nets
width_power Metal1 0.28
width_power Metal2 0.28
width_power Metal3 0.28
width_power Metal4 0.56
width_power Metal5 0.56
width_power Metal6 0.56

spacing_power Metal1 Metal1 0.28
spacing_power Metal2 Metal2 0.28
spacing_power Metal3 Metal3 0.28
spacing_power Metal4 Metal4 0.56
spacing_power Metal5 Metal5 0.56
spacing_power Metal6 Metal6 0.56

# SRAM macro specific rules
region SRAM {
    spacing Metal1 Metal1 0.28
    spacing Metal2 Metal2 0.28
    width Metal1 0.28
    width Metal2 0.28
    edge_spacing Metal1 0.28
    edge_spacing Metal2 0.28
}

# Clock routing specific rules
region CLOCK {
    width Metal4 0.56
    width Metal5 0.56
    width Metal6 0.56
    spacing Metal4 Metal4 0.56
    spacing Metal5 Metal5 0.56
    spacing Metal6 Metal6 0.56
}

# Antenna rules
antenna_ratio Metal1 400
antenna_ratio Metal2 400
antenna_ratio Metal3 400
antenna_ratio Metal4 800
antenna_ratio Metal5 800
antenna_ratio Metal6 800

# Density rules
density_min Metal1 20
density_max Metal1 80
density_min Metal2 20
density_max Metal2 80
density_min Metal3 20
density_max Metal3 80
density_min Metal4 20
density_max Metal4 80
density_min Metal5 20
density_max Metal5 80
density_min Metal6 20
density_max Metal6 80

# End-of-line spacing rules
eol_width Metal1 0.20
eol_space Metal1 0.20
eol_width Metal2 0.20
eol_space Metal2 0.20
eol_width Metal3 0.20
eol_space Metal3 0.20

# Wide metal spacing rules
wide_metal_factor Metal1 3
wide_metal_space Metal1 0.28
wide_metal_factor Metal2 3
wide_metal_space Metal2 0.28
wide_metal_factor Metal3 3
wide_metal_space Metal3 0.28

# Contact enclosure rules
contact_enclosure Metal1 0.04
contact_enclosure Metal2 0.04
contact_enclosure Metal3 0.04
contact_enclosure Metal4 0.08
contact_enclosure Metal5 0.08
contact_enclosure Metal6 0.08

# Via enclosure rules
via_enclosure Via1 0.05
via_enclosure Via2 0.05
via_enclosure Via3 0.08
via_enclosure Via4 0.08
via_enclosure Via5 0.08

# Special spacing rules for different nets
diff_net_spacing Metal1 0.18
diff_net_spacing Metal2 0.18
diff_net_spacing Metal3 0.18
diff_net_spacing Metal4 0.36
diff_net_spacing Metal5 0.36
diff_net_spacing Metal6 0.36

# DRC command options
set_drc_options {
    -max_errors 1000
    -cell_error_limit 100
    -error_scale 5.0
    -check_only selected
}

# DRC exclude cells (SRAM macro)
exclude_cell sky130_sram_8kx32_word