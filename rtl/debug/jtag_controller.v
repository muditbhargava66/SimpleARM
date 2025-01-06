// -----------------------------------------------------------------------------
// File: jtag_controller.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: JTAG Debug Interface Controller
// -----------------------------------------------------------------------------

module jtag_controller (
    input  wire        tck,           // JTAG Test Clock
    input  wire        tms,           // JTAG Test Mode Select
    input  wire        tdi,           // JTAG Test Data Input
    output reg         tdo,           // JTAG Test Data Output
    input  wire        trst_n,        // JTAG Test Reset (active low)
    
    // System interface
    input  wire        clk,           // System clock
    input  wire        rst_n,         // System reset (active low)
    
    // Debug control interface
    output reg         dbg_reset_n,   // Debug reset to processor
    output reg         dbg_halt_req,  // Request to halt processor
    input  wire        dbg_halted,    // Processor halted indicator
    
    // Debug register access interface
    output reg  [3:0]  dbg_reg_addr,  // Debug register address
    output reg  [31:0] dbg_reg_wdata, // Debug register write data
    input  wire [31:0] dbg_reg_rdata, // Debug register read data
    output reg         dbg_reg_wr_en, // Debug register write enable
    output reg         dbg_reg_rd_en, // Debug register read enable
    input  wire        dbg_reg_ready, // Debug register access ready
    
    // Debug memory access interface
    output reg  [31:0] dbg_mem_addr,  // Debug memory address
    output reg  [31:0] dbg_mem_wdata, // Debug memory write data
    input  wire [31:0] dbg_mem_rdata, // Debug memory read data
    output reg         dbg_mem_wr_en, // Debug memory write enable
    output reg         dbg_mem_rd_en, // Debug memory read enable
    input  wire        dbg_mem_ready  // Debug memory access ready
);

    // JTAG TAP controller states
    localparam TEST_LOGIC_RESET = 4'h0;
    localparam RUN_TEST_IDLE    = 4'h1;
    localparam SELECT_DR_SCAN   = 4'h2;
    localparam CAPTURE_DR       = 4'h3;
    localparam SHIFT_DR         = 4'h4;
    localparam EXIT1_DR         = 4'h5;
    localparam PAUSE_DR         = 4'h6;
    localparam EXIT2_DR         = 4'h7;
    localparam UPDATE_DR        = 4'h8;
    localparam SELECT_IR_SCAN   = 4'h9;
    localparam CAPTURE_IR       = 4'hA;
    localparam SHIFT_IR         = 4'hB;
    localparam EXIT1_IR         = 4'hC;
    localparam PAUSE_IR         = 4'hD;
    localparam EXIT2_IR         = 4'hE;
    localparam UPDATE_IR        = 4'hF;

    // JTAG instruction registers
    reg [3:0] ir;              // Instruction Register
    reg [3:0] next_ir;
    reg [3:0] tap_state;       // Current TAP state
    reg [3:0] next_tap_state;  // Next TAP state

    // JTAG data registers
    reg [39:0] dr;             // Data Register
    reg [39:0] next_dr;

    // JTAG Instructions
    localparam IDCODE      = 4'h0;  // Read IDCODE
    localparam REG_ACCESS  = 4'h1;  // Register access
    localparam MEM_ACCESS  = 4'h2;  // Memory access
    localparam CTRL_ACCESS = 4'h3;  // Control register access
    localparam BYPASS      = 4'hF;  // Bypass

    // Debug registers
    reg [31:0] ctrl_reg;        // Control register
    reg [31:0] next_ctrl_reg;

    // Synchronization registers
    reg [2:0] tms_sync;
    reg [2:0] tdi_sync;
    reg [2:0] trst_sync;

    // TAP state machine
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            tap_state <= TEST_LOGIC_RESET;
            ir <= IDCODE;
            dr <= 40'h0;
            ctrl_reg <= 32'h0;
        end else begin
            tap_state <= next_tap_state;
            ir <= next_ir;
            dr <= next_dr;
            ctrl_reg <= next_ctrl_reg;
        end
    end

    // TAP next state logic
    always @(*) begin
        next_tap_state = tap_state;
        case (tap_state)
            TEST_LOGIC_RESET: 
                next_tap_state = tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE:    
                next_tap_state = tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_DR_SCAN:   
                next_tap_state = tms ? SELECT_IR_SCAN : CAPTURE_DR;
            CAPTURE_DR:       
                next_tap_state = tms ? EXIT1_DR : SHIFT_DR;
            SHIFT_DR:         
                next_tap_state = tms ? EXIT1_DR : SHIFT_DR;
            EXIT1_DR:         
                next_tap_state = tms ? UPDATE_DR : PAUSE_DR;
            PAUSE_DR:         
                next_tap_state = tms ? EXIT2_DR : PAUSE_DR;
            EXIT2_DR:         
                next_tap_state = tms ? UPDATE_DR : SHIFT_DR;
            UPDATE_DR:        
                next_tap_state = tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_IR_SCAN:   
                next_tap_state = tms ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR:       
                next_tap_state = tms ? EXIT1_IR : SHIFT_IR;
            SHIFT_IR:         
                next_tap_state = tms ? EXIT1_IR : SHIFT_IR;
            EXIT1_IR:         
                next_tap_state = tms ? UPDATE_IR : PAUSE_IR;
            PAUSE_IR:         
                next_tap_state = tms ? EXIT2_IR : PAUSE_IR;
            EXIT2_IR:         
                next_tap_state = tms ? UPDATE_IR : SHIFT_IR;
            UPDATE_IR:        
                next_tap_state = tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            default:          
                next_tap_state = TEST_LOGIC_RESET;
        endcase
    end

    // IR logic
    always @(*) begin
        next_ir = ir;
        if (tap_state == TEST_LOGIC_RESET)
            next_ir = IDCODE;
        else if (tap_state == SHIFT_IR)
            next_ir = {tdi, ir[3:1]};
        else if (tap_state == UPDATE_IR)
            next_ir = dr[3:0];
    end

    // DR logic
    always @(*) begin
        next_dr = dr;
        if (tap_state == CAPTURE_DR) begin
            case (ir)
                IDCODE: next_dr = 32'h0A57_E5E5; // Simple ID code
                REG_ACCESS: next_dr = {dbg_reg_rdata, 8'h0};
                MEM_ACCESS: next_dr = {dbg_mem_rdata, 8'h0};
                CTRL_ACCESS: next_dr = {ctrl_reg, 8'h0};
                default: next_dr = 40'h0;
            endcase
        end else if (tap_state == SHIFT_DR) begin
            next_dr = {tdi, dr[39:1]};
        end
    end

    // TDO output logic
    always @(*) begin
        case (tap_state)
            SHIFT_DR: tdo = dr[0];
            SHIFT_IR: tdo = ir[0];
            default:  tdo = 1'b0;
        endcase
    end

    // Debug interface control signals
    always @(*) begin
        // Default values
        dbg_reset_n = 1'b1;
        dbg_halt_req = 1'b0;
        dbg_reg_addr = 4'h0;
        dbg_reg_wdata = 32'h0;
        dbg_reg_wr_en = 1'b0;
        dbg_reg_rd_en = 1'b0;
        dbg_mem_addr = 32'h0;
        dbg_mem_wdata = 32'h0;
        dbg_mem_wr_en = 1'b0;
        dbg_mem_rd_en = 1'b0;

        // Update debug signals based on IR and DR
        if (tap_state == UPDATE_DR) begin
            case (ir)
                REG_ACCESS: begin
                    dbg_reg_addr = dr[35:32];
                    dbg_reg_wdata = dr[31:0];
                    dbg_reg_wr_en = dr[36];
                    dbg_reg_rd_en = ~dr[36];
                end
                
                MEM_ACCESS: begin
                    dbg_mem_addr = dr[31:0];
                    dbg_mem_wdata = dr[31:0];
                    dbg_mem_wr_en = dr[36];
                    dbg_mem_rd_en = ~dr[36];
                end
                
                CTRL_ACCESS: begin
                    dbg_reset_n = ~dr[0];
                    dbg_halt_req = dr[1];
                end
                
                default: begin
                    // No action for other instructions
                end
            endcase
        end
    end

    // Synchronization of JTAG inputs to system clock domain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tms_sync <= 3'b0;
            tdi_sync <= 3'b0;
            trst_sync <= 3'b111;
        end else begin
            tms_sync <= {tms_sync[1:0], tms};
            tdi_sync <= {tdi_sync[1:0], tdi};
            trst_sync <= {trst_sync[1:0], trst_n};
        end
    end

endmodule