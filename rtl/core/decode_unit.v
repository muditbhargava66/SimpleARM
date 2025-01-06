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
    
    // Register file interface
    output reg  [3:0]  rs1_addr,     // Source register 1 address
    output reg  [3:0]  rs2_addr,     // Source register 2 address
    output reg  [3:0]  rd_addr,      // Destination register address
    input  wire [31:0] rs1_data,     // Source register 1 data
    input  wire [31:0] rs2_data,     // Source register 2 data
    
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

    // Immediate value generation
    reg [31:0] i_imm; // I-type immediate
    reg [31:0] s_imm; // S-type immediate
    reg [31:0] b_imm; // B-type immediate
    reg [31:0] u_imm; // U-type immediate
    reg [31:0] j_imm; // J-type immediate

    // Immediate value generation logic
    always @(*) begin
        // I-type immediate
        i_imm = {{20{instr_in[31]}}, instr_in[31:20]};
        
        // S-type immediate
        s_imm = {{20{instr_in[31]}}, instr_in[31:25], instr_in[11:7]};
        
        // B-type immediate
        b_imm = {{20{instr_in[31]}}, instr_in[7], instr_in[30:25], 
                 instr_in[11:8], 1'b0};
        
        // U-type immediate
        u_imm = {instr_in[31:12], 12'b0};
        
        // J-type immediate
        j_imm = {{12{instr_in[31]}}, instr_in[19:12], instr_in[20], 
                 instr_in[30:21], 1'b0};
    end

    // Main decode logic
    always @(*) begin
        // Default values
        rs1_addr = rs1[3:0];
        rs2_addr = rs2[3:0];
        rd_addr  = rd[3:0];
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
                    endcase
                end

                // Additional instruction decoding will be implemented here
                // Including load/store, branches, and jumps
                
                default: begin
                    // Invalid instruction handling
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