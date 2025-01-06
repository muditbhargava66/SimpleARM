// -----------------------------------------------------------------------------
// File: simple_arm_top.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Top-level integration of all components
// -----------------------------------------------------------------------------

module simple_arm_top (
    // Clock and Reset
    input  wire        clk,           // System clock
    input  wire        rst_n,         // System reset (active low)
    
    // JTAG interface
    input  wire        tck,           // JTAG Test Clock
    input  wire        tms,           // JTAG Test Mode Select
    input  wire        tdi,           // JTAG Test Data Input
    output wire        tdo,           // JTAG Test Data Output
    input  wire        trst_n,        // JTAG Test Reset
    
    // External memory interface (optional)
    output wire [31:0] ext_addr,      // External address
    output wire [31:0] ext_wdata,     // External write data
    input  wire [31:0] ext_rdata,     // External read data
    output wire        ext_wr_en,     // External write enable
    output wire        ext_rd_en,     // External read enable
    output wire [3:0]  ext_byte_en,   // External byte enable
    input  wire        ext_ready      // External ready signal
);

    // Internal signals - CPU core to memory controller
    wire [31:0] core_instr_addr;
    wire [31:0] core_instr_data;
    wire        core_instr_req;
    wire        core_instr_ready;
    
    wire [31:0] core_data_addr;
    wire [31:0] core_data_wdata;
    wire [31:0] core_data_rdata;
    wire        core_data_req;
    wire        core_data_we;
    wire [3:0]  core_data_be;
    wire        core_data_ready;

    // Internal signals - Memory controller to SRAM
    wire [12:0] sram_addr;
    wire [31:0] sram_wdata;
    wire [31:0] sram_rdata;
    wire        sram_cs_n;
    wire        sram_we_n;
    wire [3:0]  sram_be_n;
    wire        sram_ready;

    // Debug interface signals
    wire        dbg_reset_n;
    wire        dbg_halt_req;
    wire        dbg_halted;
    wire [3:0]  dbg_reg_addr;
    wire [31:0] dbg_reg_wdata;
    wire [31:0] dbg_reg_rdata;
    wire        dbg_reg_wr_en;
    wire        dbg_reg_rd_en;
    wire        dbg_reg_ready;
    wire [31:0] dbg_mem_addr;
    wire [31:0] dbg_mem_wdata;
    wire [31:0] dbg_mem_rdata;
    wire        dbg_mem_wr_en;
    wire        dbg_mem_rd_en;
    wire        dbg_mem_ready;

    // System reset generation
    wire system_rst_n = rst_n & dbg_reset_n;

    // CPU Core instantiation
    // Fetch Unit
    fetch_unit fetch_unit_inst (
        .clk          (clk),
        .rst_n        (system_rst_n),
        .stall        (dbg_halt_req),
        .branch_taken (/* from execute */),
        .branch_target(/* from execute */),
        .pc_out       (core_instr_addr),
        .instr_in     (core_instr_data),
        .instr_out    (/* to decode */),
        .valid_out    (fetch_valid)
    );

    // Decode Unit
    wire [31:0] decode_instr;
    wire [31:0] decode_pc;
    wire        decode_valid;
    wire [3:0]  decode_rs1_addr;
    wire [3:0]  decode_rs2_addr;
    wire [3:0]  decode_rd_addr;
    wire [31:0] decode_rs1_data;
    wire [31:0] decode_rs2_data;
    wire [3:0]  decode_alu_op;
    wire [31:0] decode_imm_val;
    wire        decode_use_imm;
    wire        decode_mem_read;
    wire        decode_mem_write;
    wire        decode_branch_op;
    wire        decode_reg_write;

    decode_unit decode_unit_inst (
        .clk          (clk),
        .rst_n        (system_rst_n),
        .stall        (dbg_halt_req),
        .instr_in     (decode_instr),
        .valid_in     (fetch_valid),
        .pc_in        (core_instr_addr),
        .rs1_addr     (decode_rs1_addr),
        .rs2_addr     (decode_rs2_addr),
        .rd_addr      (decode_rd_addr),
        .rs1_data     (decode_rs1_data),
        .rs2_data     (decode_rs2_data),
        .alu_op       (decode_alu_op),
        .imm_val      (decode_imm_val),
        .use_imm      (decode_use_imm),
        .mem_read     (decode_mem_read),
        .mem_write    (decode_mem_write),
        .branch_op    (decode_branch_op),
        .reg_write    (decode_reg_write),
        .pc_out       (decode_pc),
        .valid_out    (decode_valid)
    );

    // Register File
    register_file register_file_inst (
        .clk          (clk),
        .rst_n        (system_rst_n),
        .rs1_addr     (decode_rs1_addr),
        .rs2_addr     (decode_rs2_addr),
        .rs1_data     (decode_rs1_data),
        .rs2_data     (decode_rs2_data),
        .wr_en        (execute_reg_write),
        .wr_addr      (execute_rd_addr),
        .wr_data      (execute_result)
    );

    // Execute Unit
    wire [31:0] execute_result;
    wire [3:0]  execute_rd_addr;
    wire        execute_reg_write;
    wire        execute_branch_taken;
    wire [31:0] execute_branch_target;

    execute_unit execute_unit_inst (
        .clk          (clk),
        .rst_n        (system_rst_n),
        .stall        (dbg_halt_req),
        .pc_in        (decode_pc),
        .valid_in     (decode_valid),
        .alu_op       (decode_alu_op),
        .rs1_data     (decode_rs1_data),
        .rs2_data     (decode_rs2_data),
        .imm_val      (decode_imm_val),
        .use_imm      (decode_use_imm),
        .mem_read     (decode_mem_read),
        .mem_write    (decode_mem_write),
        .branch_op    (decode_branch_op),
        .reg_write    (decode_reg_write),
        .rd_addr      (decode_rd_addr),
        .mem_addr     (core_data_addr),
        .mem_wdata    (core_data_wdata),
        .mem_rdata    (core_data_rdata),
        .mem_rd_en    (core_data_req),
        .mem_wr_en    (core_data_we),
        .wb_rd_addr   (execute_rd_addr),
        .wb_data      (execute_result),
        .wb_reg_write (execute_reg_write),
        .branch_taken (execute_branch_taken),
        .branch_target(execute_branch_target)
    );

    // Memory Controller
    memory_controller memory_controller_inst (
        .clk          (clk),
        .rst_n        (system_rst_n),
        .instr_addr   (core_instr_addr),
        .instr_data   (core_instr_data),
        .instr_req    (core_instr_req),
        .instr_ready  (core_instr_ready),
        .data_addr    (core_data_addr),
        .data_wdata   (core_data_wdata),
        .data_rdata   (core_data_rdata),
        .data_req     (core_data_req),
        .data_we      (core_data_we),
        .data_be      (core_data_be),
        .data_ready   (core_data_ready),
        .sram_addr    (sram_addr),
        .sram_wdata   (sram_wdata),
        .sram_rdata   (sram_rdata),
        .sram_cs_n    (sram_cs_n),
        .sram_we_n    (sram_we_n),
        .sram_be_n    (sram_be_n),
        .sram_ready   (sram_ready)
    );

    // SRAM
    sram_wrapper sram_wrapper_inst (
        .clk          (clk),
        .rst_n        (system_rst_n),
        .cs_n         (sram_cs_n),
        .we_n         (sram_we_n),
        .byte_en_n    (sram_be_n),
        .addr         (sram_addr),
        .wdata        (sram_wdata),
        .rdata        (sram_rdata),
        .ready        (sram_ready)
    );

    // JTAG Debug Controller
    jtag_controller jtag_controller_inst (
        .tck          (tck),
        .tms          (tms),
        .tdi          (tdi),
        .tdo          (tdo),
        .trst_n       (trst_n),
        .clk          (clk),
        .rst_n        (rst_n),
        .dbg_reset_n  (dbg_reset_n),
        .dbg_halt_req (dbg_halt_req),
        .dbg_halted   (dbg_halted),
        .dbg_reg_addr (dbg_reg_addr),
        .dbg_reg_wdata(dbg_reg_wdata),
        .dbg_reg_rdata(dbg_reg_rdata),
        .dbg_reg_wr_en(dbg_reg_wr_en),
        .dbg_reg_rd_en(dbg_reg_rd_en),
        .dbg_reg_ready(dbg_reg_ready),
        .dbg_mem_addr (dbg_mem_addr),
        .dbg_mem_wdata(dbg_mem_wdata),
        .dbg_mem_rdata(dbg_mem_rdata),
        .dbg_mem_wr_en(dbg_mem_wr_en),
        .dbg_mem_rd_en(dbg_mem_rd_en),
        .dbg_mem_ready(dbg_mem_ready)
    );

    // External Memory Interface (optional)
    assign ext_addr    = core_data_addr;
    assign ext_wdata   = core_data_wdata;
    assign ext_wr_en   = core_data_we;
    assign ext_rd_en   = core_data_req & ~core_data_we;
    assign ext_byte_en = core_data_be;

endmodule