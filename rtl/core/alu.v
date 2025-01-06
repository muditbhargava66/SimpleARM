// -----------------------------------------------------------------------------
// File: alu.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Arithmetic Logic Unit
// -----------------------------------------------------------------------------

module alu (
    input  wire [31:0] operand_a,    // First operand
    input  wire [31:0] operand_b,    // Second operand
    input  wire [3:0]  alu_op,       // ALU operation
    output reg  [31:0] result,       // ALU result
    output reg         zero_flag,    // Zero flag
    output reg         negative_flag,// Negative flag
    output reg         carry_flag,   // Carry flag
    output reg         overflow_flag // Overflow flag
);

    // ALU operation codes
    localparam ALU_ADD  = 4'b0000;  // Addition
    localparam ALU_SUB  = 4'b0001;  // Subtraction
    localparam ALU_SLL  = 4'b0010;  // Shift left logical
    localparam ALU_SLT  = 4'b0011;  // Set less than (signed)
    localparam ALU_SLTU = 4'b0100;  // Set less than (unsigned)
    localparam ALU_XOR  = 4'b0101;  // Bitwise XOR
    localparam ALU_SRL  = 4'b0110;  // Shift right logical
    localparam ALU_SRA  = 4'b0111;  // Shift right arithmetic
    localparam ALU_OR   = 4'b1000;  // Bitwise OR
    localparam ALU_AND  = 4'b1001;  // Bitwise AND

    // Internal signals
    reg [32:0] add_sub_result;  // 33-bit for carry detection
    wire [31:0] sra_mask;
    
    // Generate mask for arithmetic right shift
    assign sra_mask = {{32{operand_a[31]}} >> ~operand_b[4:0]};

    // Main ALU logic
    always @(*) begin
        // Default values
        result = 32'h0;
        zero_flag = 1'b0;
        negative_flag = 1'b0;
        carry_flag = 1'b0;
        overflow_flag = 1'b0;
        add_sub_result = 33'h0;

        case (alu_op)
            ALU_ADD: begin
                // Addition with carry and overflow detection
                add_sub_result = {1'b0, operand_a} + {1'b0, operand_b};
                result = add_sub_result[31:0];
                carry_flag = add_sub_result[32];
                overflow_flag = (operand_a[31] == operand_b[31]) && 
                              (result[31] != operand_a[31]);
            end

            ALU_SUB: begin
                // Subtraction with carry and overflow detection
                add_sub_result = {1'b0, operand_a} - {1'b0, operand_b};
                result = add_sub_result[31:0];
                carry_flag = ~add_sub_result[32];
                overflow_flag = (operand_a[31] != operand_b[31]) && 
                              (result[31] != operand_a[31]);
            end

            ALU_SLL: begin
                // Logical left shift
                result = operand_a << operand_b[4:0];
                carry_flag = (operand_b[4:0] != 0) ? 
                            operand_a[32-operand_b[4:0]] : 1'b0;
            end

            ALU_SLT: begin
                // Set less than (signed)
                result = ($signed(operand_a) < $signed(operand_b)) ? 32'h1 : 32'h0;
            end

            ALU_SLTU: begin
                // Set less than (unsigned)
                result = (operand_a < operand_b) ? 32'h1 : 32'h0;
            end

            ALU_XOR: begin
                // Bitwise XOR
                result = operand_a ^ operand_b;
            end

            ALU_SRL: begin
                // Logical right shift
                result = operand_a >> operand_b[4:0];
                carry_flag = (operand_b[4:0] != 0) ? 
                            operand_a[operand_b[4:0]-1] : 1'b0;
            end

            ALU_SRA: begin
                // Arithmetic right shift
                result = $signed(operand_a) >>> operand_b[4:0];
                carry_flag = (operand_b[4:0] != 0) ? 
                            operand_a[operand_b[4:0]-1] : 1'b0;
            end

            ALU_OR: begin
                // Bitwise OR
                result = operand_a | operand_b;
            end

            ALU_AND: begin
                // Bitwise AND
                result = operand_a & operand_b;
            end

            default: begin
                // Invalid operation
                result = 32'h0;
            end
        endcase

        // Update flags
        zero_flag = (result == 32'h0);
        negative_flag = result[31];
    end

endmodule