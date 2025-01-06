// -----------------------------------------------------------------------------
// File: sram_wrapper.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Wrapper for OpenRAM-generated SRAM
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

    // Internal signals
    reg [31:0] ram_wdata;
    reg [31:0] ram_rdata;
    reg        ram_cs;
    reg        ram_we;
    reg [3:0]  ram_byte_en;

    // OpenRAM instance (8KB SRAM)
    // Note: This assumes the OpenRAM generator created a memory with these ports
    sky130_sram_8kx32_word openram_8kb (
        .clk0     (clk),
        .csb0     (~ram_cs),          // Active high in OpenRAM
        .web0     (~ram_we),          // Active high in OpenRAM
        .wmask0   (~ram_byte_en),     // Active high in OpenRAM
        .addr0    (addr),
        .din0     (ram_wdata),
        .dout0    (ram_rdata)
    );

    // Convert active low to active high signals
    always @(*) begin
        ram_cs = ~cs_n;
        ram_we = ~we_n;
        ram_byte_en = ~byte_en_n;
        ram_wdata = wdata;
    end

    // Assign read data output
    assign rdata = ram_rdata;

    // Ready signal generation
    // OpenRAM has 1 cycle latency for reads
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

    // Error Detection Logic
    // synthesis translate_off
    always @(posedge clk) begin
        if (ram_cs && ram_we) begin
            // Check for write to invalid address
            if (addr >= 13'h2000) begin
                $display("Error: Write to invalid address 0x%h", addr);
                $stop;
            end
        end
    end
    // synthesis translate_on

endmodule