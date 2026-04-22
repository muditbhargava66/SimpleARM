// -----------------------------------------------------------------------------
// File: decode_unit.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Instruction Decode Unit
// -----------------------------------------------------------------------------

module decode_unit (
    input  wire        clk,           // System clock
    input  wire        rst_n,         // Active low reset
    input  wire        stall,         // Pipeline stall signal
    
    // Interface with fetch stage
    input  wire [31:0] instr_in,     // Instruction from fetch stage
    input  wire        valid_in,      // Instruction valid signal
    input  wire [31:0] pc_in,        // Program counter from fetch stage
    
    // Register file interface (address outputs)
    output wire [3:0]  rs1_addr,     // Source register 1 address
    output wire [3:0]  rs2_addr,     // Source register 2 address
    output wire [3:0]  rd_addr,      // Destination register address
    
    // Control signals to execute stage
    output reg  [3:0]  alu_op,       // ALU operation
    output reg  [31:0] imm_val,      // Immediate value
    output reg         use_imm,      // Use immediate value flag
    output reg         mem_read,     // Memory read operation
    output reg         mem_write,    // Memory write operation
    output reg         branch_op,    // Branch operation
    output reg         reg_write,    // Register write enable
    
    // Pipeline outputs
    output reg  [31:0] pc_out,      // Program counter to execute stage
    output reg         valid_out     // Instruction valid signal
);

    // Instruction fields
    wire [6:0]  opcode = instr_in[6:0];
    wire [2:0]  funct3 = instr_in[14:12];
    wire [6:0]  funct7 = instr_in[31:25];
    wire [4:0]  rd     = instr_in[11:7];
    wire [4:0]  rs1    = instr_in[19:15];
    wire [4:0]  rs2    = instr_in[24:20];

    // Register address outputs (directly from instruction)
    assign rs1_addr = rs1[3:0];
    assign rs2_addr = rs2[3:0];
    assign rd_addr  = rd[3:0];

    // Immediate value generation
    wire [31:0] i_imm; // I-type immediate
    wire [31:0] s_imm; // S-type immediate
    wire [31:0] b_imm; // B-type immediate
    wire [31:0] u_imm; // U-type immediate
    wire [31:0] j_imm; // J-type immediate

    // Immediate value generation (continuous assignments)
    assign i_imm = {{20{instr_in[31]}}, instr_in[31:20]};
    assign s_imm = {{20{instr_in[31]}}, instr_in[31:25], instr_in[11:7]};
    assign b_imm = {{20{instr_in[31]}}, instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0};
    assign u_imm = {instr_in[31:12], 12'b0};
    assign j_imm = {{12{instr_in[31]}}, instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0};

    // Main decode logic
    always @(*) begin
        // Default values
        alu_op   = 4'b0000;
        imm_val  = 32'h0;
        use_imm  = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch_op = 1'b0;
        reg_write = 1'b0;

        if (valid_in) begin
            case (opcode)
                7'b0110011: begin // R-type instructions
                    case (funct3)
                        3'b000: alu_op = (funct7[5]) ? 4'b0001 : 4'b0000; // ADD/SUB
                        3'b001: alu_op = 4'b0010; // SLL
                        3'b010: alu_op = 4'b0011; // SLT
                        3'b011: alu_op = 4'b0100; // SLTU
                        3'b100: alu_op = 4'b0101; // XOR
                        3'b101: alu_op = (funct7[5]) ? 4'b0111 : 4'b0110; // SRL/SRA
                        3'b110: alu_op = 4'b1000; // OR
                        3'b111: alu_op = 4'b1001; // AND
                        default: alu_op = 4'b0000;
                    endcase
                    reg_write = 1'b1;
                end

                7'b0010011: begin // I-type ALU instructions
                    use_imm = 1'b1;
                    imm_val = i_imm;
                    reg_write = 1'b1;
                    case (funct3)
                        3'b000: alu_op = 4'b0000; // ADDI
                        3'b010: alu_op = 4'b0011; // SLTI
                        3'b011: alu_op = 4'b0100; // SLTIU
                        3'b100: alu_op = 4'b0101; // XORI
                        3'b110: alu_op = 4'b1000; // ORI
                        3'b111: alu_op = 4'b1001; // ANDI
                        3'b001: alu_op = 4'b0010; // SLLI
                        3'b101: alu_op = (funct7[5]) ? 4'b0111 : 4'b0110; // SRLI/SRAI
                        default: alu_op = 4'b0000;
                    endcase
                end

                7'b0000011: begin // Load instructions
                    use_imm = 1'b1;
                    imm_val = i_imm;
                    mem_read = 1'b1;
                    reg_write = 1'b1;
                    alu_op = 4'b0000; // ADD for address calculation
                end

                7'b0100011: begin // Store instructions
                    use_imm = 1'b1;
                    imm_val = s_imm;
                    mem_write = 1'b1;
                    alu_op = 4'b0000; // ADD for address calculation
                end

                7'b1100011: begin // Branch instructions
                    branch_op = 1'b1;
                    imm_val = b_imm;
                    case (funct3)
                        3'b000: alu_op = 4'b0000; // BEQ
                        3'b001: alu_op = 4'b0001; // BNE
                        3'b100: alu_op = 4'b0100; // BLT
                        3'b101: alu_op = 4'b0101; // BGE
                        3'b110: alu_op = 4'b0110; // BLTU
                        3'b111: alu_op = 4'b0111; // BGEU
                        default: alu_op = 4'b0000;
                    endcase
                end

                7'b0110111: begin // LUI
                    use_imm = 1'b1;
                    imm_val = u_imm;
                    reg_write = 1'b1;
                    alu_op = 4'b1010; // Pass imm through
                end

                7'b0010111: begin // AUIPC
                    use_imm = 1'b1;
                    imm_val = u_imm;
                    reg_write = 1'b1;
                    alu_op = 4'b1011; // PC + imm
                end

                7'b1101111: begin // JAL
                    use_imm = 1'b1;
                    imm_val = j_imm;
                    branch_op = 1'b1;
                    reg_write = 1'b1;
                    alu_op = 4'b1100; // JAL operation
                end

                7'b1100111: begin // JALR
                    use_imm = 1'b1;
                    imm_val = i_imm;
                    branch_op = 1'b1;
                    reg_write = 1'b1;
                    alu_op = 4'b1101; // JALR operation
                end

                default: begin
                    // Invalid instruction or NOP
                    alu_op = 4'b0000;
                    reg_write = 1'b0;
                end
            endcase
        end
    end

    // Pipeline registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 32'h0;
            valid_out <= 1'b0;
        end else if (!stall) begin
            pc_out <= pc_in;
            valid_out <= valid_in;
        end
    end

endmodule