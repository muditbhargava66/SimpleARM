// -----------------------------------------------------------------------------
// File: sram_wrapper.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Synthesizable memory wrapper (for P&R flow testing)
// Note: This version uses registers instead of SRAM macro for synthesis flow
// -----------------------------------------------------------------------------

module sram_wrapper (
    input  wire        clk,           // System clock
    input  wire        rst_n,         // Active low reset
    
    // Control signals
    input  wire        cs_n,          // Chip select (active low)
    input  wire        we_n,          // Write enable (active low)
    input  wire [3:0]  byte_en_n,     // Byte enable (active low)
    
    // Address and data
    input  wire [12:0] addr,          // Address input (8KB = 13 bits)
    input  wire [31:0] wdata,         // Write data
    output wire [31:0] rdata,         // Read data
    
    // Status signals
    output reg         ready          // Data ready signal
);

    // Internal signals for active-high conversion
    wire ram_cs;
    wire ram_we;
    wire [3:0] ram_byte_en;
    
    // Convert active low to active high signals
    assign ram_cs = ~cs_n;
    assign ram_we = ~we_n;
    assign ram_byte_en = ~byte_en_n;

    // Synthesizable memory (256 words x 32 bits = 1KB for synthesis testing)
    // Note: Reduced size for synthesis flow - full 8KB would be too large
    localparam MEM_DEPTH = 256;  // 1KB
    localparam ADDR_WIDTH = 8;   // log2(256)
    
    reg [31:0] mem [0:MEM_DEPTH-1];
    reg [31:0] rdata_reg;
    
    // Truncate address for smaller memory
    wire [ADDR_WIDTH-1:0] mem_addr = addr[ADDR_WIDTH-1:0];
    
    // Assign read data output
    assign rdata = rdata_reg;
    
    // Memory read/write logic
    always @(posedge clk) begin
        if (ram_cs) begin
            if (ram_we) begin
                // Write operation with byte mask
                if (ram_byte_en[0]) mem[mem_addr][7:0]   <= wdata[7:0];
                if (ram_byte_en[1]) mem[mem_addr][15:8]  <= wdata[15:8];
                if (ram_byte_en[2]) mem[mem_addr][23:16] <= wdata[23:16];
                if (ram_byte_en[3]) mem[mem_addr][31:24] <= wdata[31:24];
            end
            // Read operation (read-first behavior)
            rdata_reg <= mem[mem_addr];
        end
    end

    // Ready signal generation
    // 1 cycle latency for reads
    reg [1:0] ready_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_counter <= 2'b00;
            ready <= 1'b0;
        end else begin
            if (ram_cs) begin
                if (ram_we) begin
                    // Write operation - ready immediately
                    ready <= 1'b1;
                    ready_counter <= 2'b00;
                end else begin
                    // Read operation - ready after 1 cycle
                    case (ready_counter)
                        2'b00: begin
                            ready <= 1'b0;
                            ready_counter <= 2'b01;
                        end
                        2'b01: begin
                            ready <= 1'b1;
                            ready_counter <= 2'b00;
                        end
                        default: begin
                            ready_counter <= 2'b00;
                        end
                    endcase
                end
            end else begin
                ready <= 1'b0;
                ready_counter <= 2'b00;
            end
        end
    end

endmodule