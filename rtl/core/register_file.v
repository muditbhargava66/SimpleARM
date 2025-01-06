// -----------------------------------------------------------------------------
// File: register_file.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Register File Implementation
// -----------------------------------------------------------------------------

module register_file (
    input  wire        clk,           // System clock
    input  wire        rst_n,         // Active low reset
    
    // Read ports
    input  wire [3:0]  rs1_addr,     // Source register 1 address
    input  wire [3:0]  rs2_addr,     // Source register 2 address
    output reg  [31:0] rs1_data,     // Source register 1 data
    output reg  [31:0] rs2_data,     // Source register 2 data
    
    // Write port
    input  wire        wr_en,        // Write enable
    input  wire [3:0]  wr_addr,      // Write address
    input  wire [31:0] wr_data       // Write data
);

    // Register file storage
    reg [31:0] registers [0:15];  // 16 32-bit registers
    integer i;

    // Asynchronous read
    always @(*) begin
        // R0 is hardwired to 0
        if (rs1_addr == 4'h0)
            rs1_data = 32'h0;
        else
            rs1_data = registers[rs1_addr];

        if (rs2_addr == 4'h0)
            rs2_data = 32'h0;
        else
            rs2_data = registers[rs2_addr];
    end

    // Synchronous write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers to 0
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 32'h0;
            end
        end else begin
            // Write operation (skip if writing to R0)
            if (wr_en && wr_addr != 4'h0) begin
                registers[wr_addr] <= wr_data;
            end
        end
    end

    // Synthesis attributes to prevent register optimization
    // synthesis attribute ram_style of registers is distributed
    // synthesis attribute ram_extract of registers is no

endmodule