# SimpleARM Memory System Architecture

## Overview
The SimpleARM memory system implements a Harvard architecture with unified physical memory. It features an 8KB SRAM for both instruction and data storage, with separate interfaces for concurrent access.

## Memory Organization

### Memory Map
```
0x0000 - 0x0FFF : Instruction Memory (4KB)
0x1000 - 0x1FFF : Data Memory (4KB)
0x2000 - 0xFFFF : External Memory Interface
```

### SRAM Specifications
- Total Size: 8KB
- Word Size: 32 bits
- Number of Words: 2048
- Address Width: 13 bits
- Read Latency: 1 cycle
- Write Latency: 1 cycle

## Memory Controller

### Key Features
1. Separate instruction and data interfaces
2. Byte-enable support
3. Wait-state generation
4. Error detection
5. Debug access support

### Interface Signals

#### Instruction Interface
```verilog
input  wire [31:0] instr_addr    // Instruction address
output reg  [31:0] instr_data    // Instruction data
input  wire        instr_req     // Instruction request
output reg         instr_ready   // Instruction ready
```

#### Data Interface
```verilog
input  wire [31:0] data_addr     // Data address
input  wire [31:0] data_wdata    // Write data
output reg  [31:0] data_rdata    // Read data
input  wire        data_req      // Data request
input  wire        data_we       // Write enable
input  wire [3:0]  data_be       // Byte enable
output reg         data_ready    // Data ready
```

### Access Types
1. Word (32-bit)
2. Half-word (16-bit)
3. Byte (8-bit)

## SRAM Integration

### OpenRAM Interface
- Built using Sky130 PDK
- Single-port SRAM macro
- Synchronous operation

### Signal Mapping
```verilog
sky130_sram_8kx32_word openram_8kb (
    .clk0     (clk),
    .csb0     (sram_cs_n),
    .web0     (sram_we_n),
    .wmask0   (sram_be_n),
    .addr0    (sram_addr),
    .din0     (sram_wdata),
    .dout0    (sram_rdata)
);
```

## Access Protocol

### Read Operation
1. Assert address and read request
2. Wait for ready signal
3. Sample data on ready assertion
4. Maximum 2 cycle latency

### Write Operation
1. Assert address, data, and write enable
2. Set appropriate byte enables
3. Wait for ready signal
4. Single cycle latency

### Timing Diagrams
```
Read Operation:
Clock      : _|¯|_|¯|_|¯|_
Address    : ==X=========
Read Req   : ¯¯|_________
Ready      : ___|¯¯¯|____
Data Valid : _____|¯¯¯¯¯

Write Operation:
Clock      : _|¯|_|¯|_|¯|_
Address    : ==X=========
Write Data : ==X=========
Write Req  : ¯¯|_________
Byte Enable : ==X=========
Ready      : ___|¯¯¯|____
```

## Arbitration

### Priority Scheme
1. Debug access (highest)
2. Instruction fetch
3. Data access (lowest)

### Arbitration Rules
- No instruction fetch during debug
- Data access yields to instruction fetch
- Back-to-back access support

## Error Handling

### Error Types
1. Address out of range
2. Misaligned access
3. Invalid byte enables
4. Timeout condition

### Error Responses
- Error signal assertion
- Optional interrupt generation
- Access termination
- Error logging

## Debug Support

### Debug Features
1. Memory read/write access
2. Access breakpoints
3. Memory monitoring
4. Error injection

### Debug Interface
```verilog
input  wire [31:0] dbg_addr     // Debug address
input  wire [31:0] dbg_wdata    // Debug write data
output reg  [31:0] dbg_rdata    // Debug read data
input  wire        dbg_wr_en    // Debug write enable
input  wire        dbg_rd_en    // Debug read enable
output reg         dbg_ready    // Debug ready
```

## Performance Optimizations

### Memory Features
1. Single-cycle access (when ready)
2. Pipelined operations support
3. Burst mode capability
4. Wait state minimization

### Critical Paths
1. Address decoding
2. Data multiplexing
3. Ready generation
4. Error detection

## Power Management

### Power Saving Features
1. Clock gating
2. Memory bank selection
3. Power-down modes
4. Retention support

### Power Modes
1. Active mode
2. Sleep mode
3. Deep sleep
4. Retention mode

## Integration Guidelines

### RTL Integration
1. Clock domain considerations
2. Reset requirements
3. Error handling integration
4. Debug interface connection

### Physical Integration
1. Power planning
2. Clock distribution
3. Signal routing
4. SRAM placement

## Appendix

### Interface Timing
Detailed timing specifications for all interfaces.

### Error Codes
Complete list of error codes and their meanings.

### Verification Requirements
Key points for memory system verification.

### Power Estimation
Typical power consumption figures.

---