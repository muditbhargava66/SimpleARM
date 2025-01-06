// -----------------------------------------------------------------------------
// File: memory_controller.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Memory Controller with instruction and data interfaces
// -----------------------------------------------------------------------------

module memory_controller (
    input  wire        clk,           // System clock
    input  wire        rst_n,         // Active low reset
    
    // Instruction fetch interface
    input  wire [31:0] instr_addr,    // Instruction address
    output reg  [31:0] instr_data,    // Instruction data
    input  wire        instr_req,     // Instruction request
    output reg         instr_ready,   // Instruction ready
    
    // Data memory interface
    input  wire [31:0] data_addr,     // Data address
    input  wire [31:0] data_wdata,    // Write data
    output reg  [31:0] data_rdata,    // Read data
    input  wire        data_req,      // Data request
    input  wire        data_we,       // Write enable
    input  wire [3:0]  data_be,       // Byte enable
    output reg         data_ready,    // Data ready
    
    // SRAM interface
    output reg  [12:0] sram_addr,     // SRAM address
    output reg  [31:0] sram_wdata,    // SRAM write data
    input  wire [31:0] sram_rdata,    // SRAM read data
    output reg         sram_cs_n,     // SRAM chip select
    output reg         sram_we_n,     // SRAM write enable
    output reg  [3:0]  sram_be_n,     // SRAM byte enable
    input  wire        sram_ready     // SRAM ready
);

    // Memory map constants
    localparam INSTR_START = 13'h0000;    // Instruction memory start
    localparam INSTR_END   = 13'h0FFF;    // Instruction memory end
    localparam DATA_START  = 13'h1000;    // Data memory start
    localparam DATA_END    = 13'h1FFF;    // Data memory end

    // State machine states
    localparam IDLE     = 2'b00;
    localparam INSTR_RD = 2'b01;
    localparam DATA_RD  = 2'b10;
    localparam DATA_WR  = 2'b11;

    // State and next state
    reg [1:0] state, next_state;

    // Address translation
    wire [12:0] instr_sram_addr = instr_addr[14:2];  // Word aligned
    wire [12:0] data_sram_addr  = data_addr[14:2];   // Word aligned

    // Address validation
    wire instr_addr_valid = (instr_sram_addr >= INSTR_START && 
                            instr_sram_addr <= INSTR_END);
    wire data_addr_valid  = (data_sram_addr >= DATA_START && 
                            data_sram_addr <= DATA_END);

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (instr_req && instr_addr_valid) begin
                    next_state = INSTR_RD;
                end else if (data_req && data_addr_valid) begin
                    next_state = data_we ? DATA_WR : DATA_RD;
                end
            end
            
            INSTR_RD: begin
                if (sram_ready) begin
                    next_state = IDLE;
                end
            end
            
            DATA_RD: begin
                if (sram_ready) begin
                    next_state = IDLE;
                end
            end
            
            DATA_WR: begin
                if (sram_ready) begin
                    next_state = IDLE;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Control signals
    always @(*) begin
        // Default values
        sram_cs_n = 1'b1;
        sram_we_n = 1'b1;
        sram_be_n = 4'hF;
        sram_addr = 13'h0;
        sram_wdata = 32'h0;
        instr_ready = 1'b0;
        data_ready = 1'b0;
        instr_data = 32'h0;
        data_rdata = 32'h0;

        case (state)
            IDLE: begin
                // Keep default values
            end

            INSTR_RD: begin
                sram_cs_n = 1'b0;
                sram_we_n = 1'b1;
                sram_be_n = 4'h0;
                sram_addr = instr_sram_addr;
                instr_data = sram_rdata;
                instr_ready = sram_ready;
            end

            DATA_RD: begin
                sram_cs_n = 1'b0;
                sram_we_n = 1'b1;
                sram_be_n = ~data_be;
                sram_addr = data_sram_addr;
                data_rdata = sram_rdata;
                data_ready = sram_ready;
            end

            DATA_WR: begin
                sram_cs_n = 1'b0;
                sram_we_n = 1'b0;
                sram_be_n = ~data_be;
                sram_addr = data_sram_addr;
                sram_wdata = data_wdata;
                data_ready = sram_ready;
            end

            default: begin
                // Keep default values
            end
        endcase
    end

    // Error detection
    // synthesis translate_off
    always @(posedge clk) begin
        if (instr_req && !instr_addr_valid) begin
            $display("Error: Invalid instruction address 0x%h", instr_addr);
            $stop;
        end
        if (data_req && !data_addr_valid) begin
            $display("Error: Invalid data address 0x%h", data_addr);
            $stop;
        end
    end
    // synthesis translate_on

endmodule