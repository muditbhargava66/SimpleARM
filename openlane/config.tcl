# -----------------------------------------------------------------------------
# File: config.tcl
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: OpenLane configuration file
# -----------------------------------------------------------------------------

# Design
set ::env(DESIGN_NAME) "simple_arm_top"
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]
set ::env(CLOCK_PERIOD) "10"
set ::env(CLOCK_PORT) "clk"

# Core utilization and placement
set ::env(FP_CORE_UTIL) 65
set ::env(PL_TARGET_DENSITY) 0.70
set ::env(FP_ASPECT_RATIO) 1
set ::env(FP_PDN_CORE_RING) 1

# Floorplan
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 1500 1500"
set ::env(FP_PIN_ORDER_CFG) $::env(DESIGN_DIR)/pin_order.cfg

# PDN
set ::env(PDN_CFG) $::env(DESIGN_DIR)/pdn.tcl
set ::env(FP_PDN_CORE_RING) 1
set ::env(FP_PDN_ENABLE_RAILS) 1

# Clock
set ::env(CLOCK_TREE_SYNTH) 1
set ::env(CTS_TARGET_SKEW) 200
set ::env(CTS_TOLERANCE) 100
set ::env(CTS_SINK_CLUSTERING_SIZE) 25
set ::env(CTS_SINK_CLUSTERING_MAX_DIAMETER) 50

# Placement
set ::env(PL_RANDOM_GLB_PLACEMENT) 0
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 1
set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 1

# Routing
set ::env(GLB_RT_MAXLAYER) 6
set ::env(GLB_RT_MAX_DIODE_INS_ITERS) 5
set ::env(GLB_RT_ANT_ITERS) 15
set ::env(ROUTING_CORES) 8

# DRC
set ::env(MAGIC_DRC_USE_GDS) 1
set ::env(MAGIC_EXT_USE_GDS) 1

# LVS
set ::env(RUN_LVS) 1
set ::env(LVS_INSERT_POWER_PINS) 1

# Fill
set ::env(FILL_INSERTION) 1
set ::env(TAP_DECAP_INSERTION) 1

# Timing
set ::env(SYNTH_TIMING_DERATE) 0.05
set ::env(SYNTH_CLOCK_UNCERTAINTY) 0.25
set ::env(SYNTH_CLOCK_TRANSITION) 0.15

# Power
set ::env(RUN_POWER_ANALYSIS) 1
set ::env(SYNTH_MAX_FANOUT) 4

# Diode insertion
set ::env(DIODE_INSERTION_STRATEGY) 3

# SRAM Configuration
set ::env(MACRO_PLACEMENT_CFG) $::env(DESIGN_DIR)/macro_placement.cfg
set ::env(VERILOG_FILES_BLACKBOX) {
    $::env(PDK_ROOT)/sky130A/libs.ref/sky130_sram_macros/verilog/sky130_sram_8kx32.v
}
set ::env(EXTRA_LEFS) {
    $::env(PDK_ROOT)/sky130A/libs.ref/sky130_sram_macros/lef/sky130_sram_8kx32.lef
}
set ::env(EXTRA_GDS_FILES) {
    $::env(PDK_ROOT)/sky130A/libs.ref/sky130_sram_macros/gds/sky130_sram_8kx32.gds
}

# Report configurations
set ::env(CHECK_ASSIGN_STATEMENTS) 0
set ::env(CHECK_UNMAPPED_CELLS) 1
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 1

# Flow control
set ::env(RUN_KLAYOUT_XOR) 0
set ::env(RUN_KLAYOUT_DRC) 0
set ::env(RUN_MAGIC_DRC) 1
set ::env(RUN_ANTENNA_CHECK) 1

# OpenROAD configuration
set ::env(USE_ARC_ANTENNA_CHECK) 1
set ::env(OPENLANE_VERBOSE) 1

# Synthesis strategy
set ::env(SYNTH_STRATEGY) "DELAY 0"
set ::env(SYNTH_BUFFERING) 1
set ::env(SYNTH_SIZING) 1

# Cell padding and tap cell distance
set ::env(CELL_PAD) 4
set ::env(CELL_PAD_EXCLUDE) {sky130_sram_8kx32_word}
set ::env(FP_TAP_HORIZONTAL_HALO) 10
set ::env(FP_TAP_VERTICAL_HALO) 10

# Metal layer configurations
set ::env(RT_MAX_LAYER) {Metal6}
set ::env(RT_MIN_LAYER) {Metal2}

# DRC exclude cells
set ::env(MAGIC_DRC_EXCLUDE_CELL_LIST) {sky130_sram_8kx32_word}

# LVS exclude cells
set ::env(MAGIC_EXT_EXCLUDE_CELL_LIST) {sky130_sram_8kx32_word}

# Set SRAM pin order
set ::env(FP_PIN_ORDER_CFG) {
    clk {N}
    rst_n {N}
    tck {W}
    tms {W}
    tdi {W}
    tdo {E}
    trst_n {W}
    ext_addr.* {E}
    ext_wdata.* {E}
    ext_rdata.* {W}
    ext_wr_en {E}
    ext_rd_en {E}
    ext_byte_en.* {E}
    ext_ready {W}
}

# Power optimization
set ::env(PL_RESIZER_BUFFER_INPUT_PORTS) 1
set ::env(PL_RESIZER_BUFFER_OUTPUT_PORTS) 1
set ::env(PL_RESIZER_MAX_WIRE_LENGTH) 500
set ::env(PL_RESIZER_MAX_SLEW_MARGIN) 20
set ::env(PL_RESIZER_MAX_CAP_MARGIN) 20

# Hold time fixing
set ::env(GLB_RESIZER_HOLD_SLACK_MARGIN) 0.1
set ::env(GLB_RESIZER_HOLD_MAX_BUFFER_PERCENT) 50
set ::env(GLB_RESIZER_ALLOW_SETUP_VIOS) 1

# DRC checking
set ::env(MAGIC_DRC_FLAGS) "-noconsole -nowindow -dnull"
set ::env(MAGIC_EXT_FLAGS) "-noconsole -nowindow -dnull"

# Additional LVS settings
set ::env(MAGIC_EXT_USE_GDS) 1
set ::env(MAGIC_WRITE_FULL_LEF) 0

# Detailed routing settings
set ::env(GLB_RT_L1_ADJUSTMENT) 0.99
set ::env(GLB_RT_L2_ADJUSTMENT) 0.25
set ::env(GLB_RT_L3_ADJUSTMENT) 0.15
set ::env(GLB_RT_L4_ADJUSTMENT) 0.1
set ::env(GLB_RT_L5_ADJUSTMENT) 0.1
set ::env(GLB_RT_L6_ADJUSTMENT) 0.1

# Metal layer directions
set ::env(GLB_RT_LAYER_ADJUSTMENTS) {
    Metal1,0,0,0
    Metal2,0,0,1
    Metal3,0,1,0
    Metal4,0,0,1
    Metal5,0,1,0
    Metal6,0,0,1
}

# IO placement
set ::env(FP_IO_HLENGTH) 4
set ::env(FP_IO_VLENGTH) 4
set ::env(FP_IO_VTHICKNESS_MULT) 4
set ::env(FP_IO_HTHICKNESS_MULT) 4

# Placement density tweaks
set ::env(PL_WIRELENGTH_COEF) 0.25
set ::env(PL_SKIP_INITIAL_PLACEMENT) 0
set ::env(PL_RANDOM_INITIAL_PLACEMENT) 0

# Cell mapping settings
set ::env(SYNTH_ADDER_TYPE) "YOSYS"
set ::env(SYNTH_MUX_SIZE) 8
set ::env(SYNTH_MIN_BUF_PORT) "sky130_fd_sc_hd__buf_1"
set ::env(SYNTH_MAX_FANOUT_CONSTRAINT) 10

# Additional PDN settings
set ::env(PDN_STRIPE_DENSITY) 0.6
set ::env(PDN_VOLTAGE_DOMAINS) {VDD}
set ::env(PDN_GROUND_DOMAINS) {VSS}
set ::env(PDN_CFG_FILE) $::env(DESIGN_DIR)/pdn.tcl

# Macro placement
set ::env(MACRO_WS) 2
set ::env(MACRO_PLACE_HALO) {20 20}
set ::env(MACRO_BLOCKAGE_LAYERS) {Metal1 Metal2 Metal3}

# Final report settings
set ::env(GENERATE_FINAL_SUMMARY_REPORT) 1
set ::env(CHECK_WIRE_LENGTHS) 1
set ::env(QUIT_ON_TIMING_VIOLATIONS) 0
set ::env(QUIT_ON_MAGIC_DRC) 0
set ::env(QUIT_ON_LVS_ERROR) 0
set ::env(QUIT_ON_HOLD_VIOLATIONS) 0