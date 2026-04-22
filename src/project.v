`default_nettype none

module tt_um_simple_arm (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Tie off unused IOs
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Internal signals
    wire [31:0] ext_addr;
    wire [31:0] ext_wdata;
    wire [31:0] ext_rdata = 32'b0;
    wire        ext_wr_en;
    wire        ext_rd_en;
    wire [3:0]  ext_byte_en;
    wire        ext_ready = ui_in[6]; // Dummy external ready
    wire        tdo;

    simple_arm_top core (
        .clk(clk),
        .rst_n(rst_n),
        
        .tck(ui_in[2]),
        .tms(ui_in[3]),
        .tdi(ui_in[4]),
        .tdo(tdo),
        .trst_n(ui_in[5]),
        
        .ext_addr(ext_addr),
        .ext_wdata(ext_wdata),
        .ext_rdata(ext_rdata),
        .ext_wr_en(ext_wr_en),
        .ext_rd_en(ext_rd_en),
        .ext_byte_en(ext_byte_en),
        .ext_ready(ext_ready)
    );

    // Map outputs
    assign uo_out[0] = tdo;
    assign uo_out[1] = ext_wr_en;
    assign uo_out[2] = ext_rd_en;
    assign uo_out[3] = ext_ready;
    assign uo_out[7:4] = 4'b0;

endmodule