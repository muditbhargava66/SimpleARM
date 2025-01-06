# SimpleARM Testbench Guide

## Overview
This guide covers the testbench architecture, test development, and verification methodology for the SimpleARM processor project.

## Testbench Architecture

### Block Diagram
```
+------------------+
|   Test Cases     |
+--------+---------+
         |
+--------+---------+
| Virtual Sequence |
+--------+---------+
         |
+--------+---------+     +-------------+
|   Environment    |<--->|  Scoreboard |
+--------+---------+     +-------------+
         |
+--------+---------+     +-------------+
|    Interfaces    |<--->|  Checkers   |
+--------+---------+     +-------------+
         |
+--------+---------+
|      DUT         |
+------------------+
```

### Key Components

#### 1. Interfaces
```systemverilog
interface simple_arm_if;
    // Clock and reset
    logic        clk;
    logic        rst_n;
    
    // Memory interface
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic        mem_wr_en;
    logic        mem_rd_en;
    logic [3:0]  mem_byte_en;
    logic        mem_ready;
    
    // Clocking blocks
    clocking tb_cb @(posedge clk);
        // Test stimulus
    endclocking
    
    clocking mon_cb @(posedge clk);
        // Monitor sampling
    endclocking
    
    // Modports
    modport TB  (clocking tb_cb);
    modport MON (clocking mon_cb);
    modport DUT (/* DUT signals */);
endinterface
```

#### 2. Transaction Classes
```systemverilog
class instruction_transaction;
    // Instruction fields
    rand bit [6:0]  opcode;
    rand bit [4:0]  rd, rs1, rs2;
    rand bit [2:0]  funct3;
    rand bit [6:0]  funct7;
    rand bit [11:0] imm;
    
    // Constraints
    constraint valid_opcode {
        opcode inside {
            7'b0110011,  // R-type
            7'b0010011,  // I-type
            7'b0000011,  // Load
            7'b0100011,  // Store
            7'b1100011   // Branch
        };
    }
    
    // Methods
    function bit[31:0] encode();
        // Instruction encoding logic
    endfunction
endclass
```

#### 3. Sequence Classes
```systemverilog
class base_sequence;
    // Sequence properties
    instruction_transaction trans;
    virtual simple_arm_if vif;
    
    // Methods
    task body();
        // Sequence implementation
    endtask
endclass

class arithmetic_sequence extends base_sequence;
    task body();
        // Generate arithmetic instructions
    endtask
endclass
```

## Test Development

### 1. Basic Test Structure
```systemverilog
class test_base extends uvm_test;
    // Components
    env             m_env;
    virtual_sequencer m_vsqr;
    
    // Configuration
    function void build_phase(uvm_phase phase);
        // Build components
    endfunction
    
    // Run test
    task run_phase(uvm_phase phase);
        // Execute sequences
    endtask
endclass
```

### 2. Test Case Development
```systemverilog
class test_arithmetic extends test_base;
    task run_phase(uvm_phase phase);
        arithmetic_sequence seq;
        seq = arithmetic_sequence::type_id::create("seq");
        
        phase.raise_objection(this);
        seq.start(m_vsqr);
        phase.drop_objection(this);
    endtask
endclass
```

### 3. Assertions and Checks
```systemverilog
// Protocol checks
property valid_memory_access;
    @(posedge clk) 
    (mem_rd_en || mem_wr_en) |-> ##[1:5] mem_ready;
endproperty

// Data integrity checks
property valid_register_write;
    @(posedge clk)
    reg_write |-> !$isunknown(reg_data);
endproperty

// Instruction checks
property valid_instruction_fetch;
    @(posedge clk)
    instr_valid |-> !$isunknown(instruction);
endproperty
```

## Coverage Collection

### 1. Functional Coverage
```systemverilog
covergroup instruction_cg;
    option.per_instance = 1;
    
    cp_opcode: coverpoint opcode {
        bins r_type = {7'b0110011};
        bins i_type = {7'b0010011};
        bins load   = {7'b0000011};
        bins store  = {7'b0100011};
        bins branch = {7'b1100011};
    }
    
    cp_function: coverpoint funct3 {
        bins arithmetic = {3'b000, 3'b001};
        bins logical    = {3'b100, 3'b110, 3'b111};
        bins compare    = {3'b010, 3'b011};
    }
    
    op_x_func: cross cp_opcode, cp_function;
endgroup
```

### 2. Code Coverage
```systemverilog
// Branch coverage
covergroup branch_cg;
    cp_condition: coverpoint branch_taken {
        bins taken     = {1'b1};
        bins not_taken = {1'b0};
    }
    
    cp_type: coverpoint branch_type {
        bins beq  = {3'b000};
        bins bne  = {3'b001};
        bins blt  = {3'b100};
        bins bge  = {3'b101};
    }
endgroup
```

## Test Scenarios

### 1. Basic Instruction Tests
```systemverilog
class test_basic_instructions;
    task arithmetic_test();
        // Test ADD, SUB, etc.
    endtask
    
    task logical_test();
        // Test AND, OR, XOR
    endtask
    
    task memory_test();
        // Test
// Pending
```

---