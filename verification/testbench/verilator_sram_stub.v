// -----------------------------------------------------------------------------
// File: verilator_sram_stub.v  
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Behavioral SRAM model for Verilator simulation
// -----------------------------------------------------------------------------

module sky130_sram_8kx32_word (
    input         clk0,
    input         csb0,      // Chip select (active low)
    input         web0,      // Write enable (active low)
    input  [3:0]  wmask0,    // Write mask (active low)
    input  [12:0] addr0,
    input  [31:0] din0,
    output reg [31:0] dout0
);
    // 8KB SRAM = 2048 x 32-bit words
    reg [31:0] mem [0:2047];
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < 2048; i = i + 1) begin
            mem[i] = 32'h0;
        end
        // Initialize some test program
        mem[0] = 32'h00000000;  // NOP
        mem[1] = 32'h00000000;  // NOP
        mem[2] = 32'h00000000;  // NOP
    end
    
    always @(posedge clk0) begin
        if (!csb0) begin
            if (!web0) begin
                // Write operation with byte mask
                if (!wmask0[0]) mem[addr0[10:0]][7:0]   <= din0[7:0];
                if (!wmask0[1]) mem[addr0[10:0]][15:8]  <= din0[15:8];
                if (!wmask0[2]) mem[addr0[10:0]][23:16] <= din0[23:16];
                if (!wmask0[3]) mem[addr0[10:0]][31:24] <= din0[31:24];
            end
            // Read operation
            dout0 <= mem[addr0[10:0]];
        end
    end
    
endmodule
