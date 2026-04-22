// -----------------------------------------------------------------------------
// File: sram_blackbox.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Blackbox placeholder for OpenRAM SRAM macro
// -----------------------------------------------------------------------------

(* blackbox *)
module sky130_sram_8kx32_word (
    input         clk0,
    input         csb0,
    input         web0,
    input  [3:0]  wmask0,
    input  [12:0] addr0,
    input  [31:0] din0,
    output [31:0] dout0
);
endmodule
