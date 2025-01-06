# SimpleARM Pipeline Architecture

## Overview
The SimpleARM processor implements a 3-stage pipeline architecture optimized for low power and area while maintaining reasonable performance. The pipeline stages are:
1. Fetch (F)
2. Decode (D)
3. Execute (E)

## Pipeline Stages

### 1. Fetch Stage
The fetch stage is responsible for retrieving instructions from memory and managing the program counter (PC).

#### Key Components:
- Program Counter (PC) management
- Instruction memory interface
- Branch prediction (static, always-not-taken)
- Instruction buffering

#### Timing:
- One cycle latency for instruction fetch
- Additional cycle on cache miss

#### Interfaces:
```verilog
output reg  [31:0] pc_out       // Current Program Counter
input  wire [31:0] instr_in     // Instruction from memory
output reg  [31:0] instr_out    // Instruction to decode stage
output reg         valid_out     // Instruction valid signal
```

### 2. Decode Stage
The decode stage interprets instructions and generates control signals for the execute stage.

#### Key Components:
- Instruction decoder
- Register file interface
- Immediate value generator
- Control signal generation

#### Instruction Format Support:
- R-type instructions
- I-type instructions
- S-type instructions
- B-type instructions

#### Control Signals:
```verilog
output reg  [3:0]  alu_op       // ALU operation
output reg  [31:0] imm_val      // Immediate value
output reg         use_imm      // Use immediate value flag
output reg         mem_read     // Memory read operation
output reg         mem_write    // Memory write operation
output reg         branch_op    // Branch operation
output reg         reg_write    // Register write enable
```

### 3. Execute Stage
The execute stage performs computations and handles memory operations.

#### Key Components:
- ALU
- Memory interface
- Branch resolution
- Writeback logic

#### ALU Operations:
- Arithmetic: ADD, SUB
- Logical: AND, OR, XOR
- Shifts: SLL, SRL, SRA
- Comparisons: SLT, SLTU

#### Memory Interface:
```verilog
output reg  [31:0] mem_addr     // Memory address
output reg  [31:0] mem_wdata    // Memory write data
input  wire [31:0] mem_rdata    // Memory read data
output reg         mem_rd_en    // Memory read enable
output reg         mem_wr_en    // Memory write enable
```

## Pipeline Hazards

### 1. Data Hazards
The SimpleARM implements the following hazard handling mechanisms:

#### Register Write-Read Hazard
- Forwarding from Execute to Decode stage
- One cycle stall when necessary

#### Memory Read-after-Write
- Pipeline stall for load-use hazards
- Two cycle penalty

### 2. Control Hazards
Branch handling strategy:

#### Branch Prediction
- Static prediction (always-not-taken)
- One cycle penalty on taken branches

#### Branch Resolution
- Resolved in Execute stage
- Pipeline flush on misprediction

## Pipeline Control

### Stall Conditions
1. Load-use hazard
2. Memory operation stall
3. External stall request
4. Debug halt request

### Pipeline Flush
Triggered by:
1. Branch misprediction
2. Exception
3. Debug reset

## Pipeline Timing

### Critical Paths
1. ALU operation path
2. Memory access path
3. Branch resolution path

### Cycle Time Components
```
Fetch Stage:      2.5ns
Decode Stage:     3.5ns
Execute Stage:    4.0ns
----------------------------
Total Cycle:     10.0ns (100MHz)
```

## Debug Support

### Debug Interface
- JTAG-based debug port
- Pipeline control (halt, resume, step)
- Register and memory access

### Debug Operations
1. Pipeline halt
2. Single-step execution
3. Register read/write
4. Memory read/write

## Performance Considerations

### CPI (Cycles Per Instruction)
- Basic ALU operations: 1 cycle
- Memory operations: 1-2 cycles
- Taken branches: 2 cycles
- Debug operations: Variable

### Critical Path Optimization
1. ALU operation splitting
2. Memory address calculation
3. Branch condition evaluation

## Integration Guidelines

### Clock Domain
- Single clock domain design
- Synchronous resets
- Debug clock separate (JTAG TCK)

### Interface Requirements
1. Memory interface timing
2. Debug interface protocol
3. External stall handling

### Power Management
- Clock gating support
- Pipeline stage gating
- Debug mode power reduction

## Appendix

### Signal Descriptions
Detailed description of all pipeline interface signals.

### Timing Diagrams
Examples of pipeline operation sequences.

### Verification Points
Critical areas requiring thorough verification.

---