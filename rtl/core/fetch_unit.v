// -----------------------------------------------------------------------------
// File: fetch_unit.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Instruction Fetch Unit
// -----------------------------------------------------------------------------

module fetch_unit (
    input  wire        clk,           // System clock
    input  wire        rst_n,         // Active low reset
    input  wire        stall,         // Pipeline stall signal
    input  wire        branch_taken,  // Branch taken signal from execute stage
    input  wire [31:0] branch_target, // Branch target address
    
    // Memory interface
    output reg  [31:0] pc_out,       // Current Program Counter
    input  wire [31:0] instr_in,     // Instruction from memory
    output reg  [31:0] instr_out,    // Instruction to decode stage
    
    // Pipeline control
    output reg         valid_out      // Instruction valid signal
);

    // Internal signals
    reg [31:0] next_pc;
    reg        branch_taken_r;

    // Program Counter update logic
    always @(*) begin
        if (branch_taken) begin
            next_pc = branch_target;
        end else if (!stall) begin
            next_pc = pc_out + 32'd4;
        end else begin
            next_pc = pc_out;
        end
    end

    // Sequential logic for PC and instruction register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 32'h0000_0000;
            instr_out <= 32'h0000_0000;
            valid_out <= 1'b0;
            branch_taken_r <= 1'b0;
        end else begin
            if (!stall) begin
                pc_out <= next_pc;
                instr_out <= instr_in;
                valid_out <= 1'b1;
                branch_taken_r <= branch_taken;
            end
        end
    end

endmodule