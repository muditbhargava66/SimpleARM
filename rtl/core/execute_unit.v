// -----------------------------------------------------------------------------
// File: execute_unit.v
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Execution Unit
// -----------------------------------------------------------------------------

module execute_unit (
    input  wire        clk,           // System clock
    input  wire        rst_n,         // Active low reset
    input  wire        stall,         // Pipeline stall signal
    
    // Interface with decode stage
    input  wire [31:0] pc_in,        // Program counter
    input  wire        valid_in,      // Instruction valid signal
    input  wire [3:0]  alu_op,       // ALU operation
    input  wire [31:0] rs1_data,     // Source register 1 data
    input  wire [31:0] rs2_data,     // Source register 2 data
    input  wire [31:0] imm_val,      // Immediate value
    input  wire        use_imm,      // Use immediate value flag
    input  wire        mem_read,     // Memory read operation
    input  wire        mem_write,    // Memory write operation
    input  wire        branch_op,    // Branch operation
    input  wire        reg_write,    // Register write enable
    input  wire [3:0]  rd_addr,      // Destination register address
    
    // Memory interface
    output reg  [31:0] mem_addr,     // Memory address
    output reg  [31:0] mem_wdata,    // Memory write data
    input  wire [31:0] mem_rdata,    // Memory read data
    output reg         mem_rd_en,    // Memory read enable
    output reg         mem_wr_en,    // Memory write enable
    
    // Writeback interface
    output reg  [3:0]  wb_rd_addr,   // Writeback register address
    output reg  [31:0] wb_data,      // Writeback data
    output reg         wb_reg_write, // Writeback register write enable
    
    // Branch control
    output reg         branch_taken,  // Branch taken signal
    output reg  [31:0] branch_target // Branch target address
);

    // ALU result
    reg [31:0] alu_result;
    wire [31:0] operand_a = rs1_data;
    wire [31:0] operand_b = use_imm ? imm_val : rs2_data;

    // Branch comparison results
    reg branch_condition_met;

    // ALU operations
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;

    // Branch conditions
    localparam BR_EQ   = 3'b000;  // BEQ
    localparam BR_NE   = 3'b001;  // BNE
    localparam BR_LT   = 3'b100;  // BLT
    localparam BR_GE   = 3'b101;  // BGE
    localparam BR_LTU  = 3'b110;  // BLTU
    localparam BR_GEU  = 3'b111;  // BGEU

    // ALU implementation
    always @(*) begin
        case (alu_op)
            ALU_ADD:  alu_result = operand_a + operand_b;
            ALU_SUB:  alu_result = operand_a - operand_b;
            ALU_SLL:  alu_result = operand_a << operand_b[4:0];
            ALU_SLT:  alu_result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
            ALU_SLTU: alu_result = (operand_a < operand_b) ? 32'd1 : 32'd0;
            ALU_XOR:  alu_result = operand_a ^ operand_b;
            ALU_SRL:  alu_result = operand_a >> operand_b[4:0];
            ALU_SRA:  alu_result = $signed(operand_a) >>> operand_b[4:0];
            ALU_OR:   alu_result = operand_a | operand_b;
            ALU_AND:  alu_result = operand_a & operand_b;
            default:  alu_result = 32'h0;
        endcase
    end

    // Branch condition check
    always @(*) begin
        branch_condition_met = 1'b0;
        if (branch_op) begin
            case (alu_op[2:0])
                BR_EQ:  branch_condition_met = (rs1_data == rs2_data);
                BR_NE:  branch_condition_met = (rs1_data != rs2_data);
                BR_LT:  branch_condition_met = ($signed(rs1_data) < $signed(rs2_data));
                BR_GE:  branch_condition_met = ($signed(rs1_data) >= $signed(rs2_data));
                BR_LTU: branch_condition_met = (rs1_data < rs2_data);
                BR_GEU: branch_condition_met = (rs1_data >= rs2_data);
                default: branch_condition_met = 1'b0;
            endcase
        end
    end

    // Branch target calculation
    always @(*) begin
        if (branch_op && branch_condition_met) begin
            branch_target = pc_in + imm_val;
            branch_taken = 1'b1;
        end else begin
            branch_target = 32'h0;
            branch_taken = 1'b0;
        end
    end

    // Memory interface logic
    always @(*) begin
        mem_addr = alu_result;
        mem_wdata = rs2_data;
        mem_rd_en = mem_read & valid_in;
        mem_wr_en = mem_write & valid_in;
    end

    // Writeback logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_rd_addr <= 4'h0;
            wb_data <= 32'h0;
            wb_reg_write <= 1'b0;
        end else if (!stall) begin
            wb_rd_addr <= rd_addr;
            wb_data <= mem_read ? mem_rdata : alu_result;
            wb_reg_write <= reg_write & valid_in;
        end
    end

    // Assertions for verification
    // synthesis translate_off
    always @(posedge clk) begin
        if (valid_in) begin
            // Check ALU operation validity
            assert(alu_op <= ALU_AND) else
                $error("Invalid ALU operation: %b", alu_op);
                
            // Check branch operation validity
            if (branch_op)
                assert(alu_op[2:0] <= BR_GEU) else
                    $error("Invalid branch condition: %b", alu_op[2:0]);
                    
            // Check memory operation consistency
            assert(!(mem_read && mem_write)) else
                $error("Simultaneous memory read and write");
        end
    end
    // synthesis translate_on

endmodule