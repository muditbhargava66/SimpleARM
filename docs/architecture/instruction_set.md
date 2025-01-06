# SimpleARM Instruction Set Architecture

## Overview
The SimpleARM implements a subset of the ARMv6-M instruction set, focused on essential instructions for embedded applications. The instruction set is optimized for the 3-stage pipeline architecture.

## Instruction Format

### General Format
All instructions are 32-bit aligned and follow these formats:

#### R-Type (Register)
```
31    25 24    20 19    15 14    12 11     7 6      0
+-------+--------+--------+--------+--------+--------+
| funct7|   rs2  |   rs1  | funct3|   rd   | opcode |
+-------+--------+--------+--------+--------+--------+
```

#### I-Type (Immediate)
```
31              20 19    15 14    12 11     7 6      0
+------------------+--------+--------+--------+--------+
|     imm[11:0]    |   rs1  | funct3|   rd   | opcode |
+------------------+--------+--------+--------+--------+
```

#### S-Type (Store)
```
31    25 24    20 19    15 14    12 11     7 6      0
+-------+--------+--------+--------+--------+--------+
| imm[11:5]| rs2 |   rs1  | funct3|imm[4:0]| opcode |
+-------+--------+--------+--------+--------+--------+
```

#### B-Type (Branch)
```
31 30    25 24    20 19    15 14    12 11     7 6      0
+--+------+--------+--------+--------+--------+--------+
|imm[12]|imm[10:5]| rs2 | rs1 | funct3|imm[4:1]|imm[11]| opcode |
+--+------+--------+--------+--------+--------+--------+
```

## Instruction Categories

### 1. Data Processing Instructions

#### Arithmetic Operations
| Instruction | Description | Format | Operation |
|------------|-------------|---------|-----------|
| ADD rd, rs1, rs2 | Add registers | R-type | rd = rs1 + rs2 |
| SUB rd, rs1, rs2 | Subtract registers | R-type | rd = rs1 - rs2 |
| ADDI rd, rs1, imm | Add immediate | I-type | rd = rs1 + imm |

#### Logical Operations
| Instruction | Description | Format | Operation |
|------------|-------------|---------|-----------|
| AND rd, rs1, rs2 | Bitwise AND | R-type | rd = rs1 & rs2 |
| OR rd, rs1, rs2  | Bitwise OR  | R-type | rd = rs1 \| rs2 |
| XOR rd, rs1, rs2 | Bitwise XOR | R-type | rd = rs1 ^ rs2 |

#### Shift Operations
| Instruction | Description | Format | Operation |
|------------|-------------|---------|-----------|
| SLL rd, rs1, rs2 | Logical left shift | R-type | rd = rs1 << rs2 |
| SRL rd, rs1, rs2 | Logical right shift | R-type | rd = rs1 >> rs2 |
| SRA rd, rs1, rs2 | Arithmetic right shift | R-type | rd = rs1 >>> rs2 |

### 2. Memory Instructions

#### Load Operations
| Instruction | Description | Format | Operation |
|------------|-------------|---------|-----------|
| LW rd, offset(rs1) | Load word | I-type | rd = Mem[rs1 + offset] |
| LH rd, offset(rs1) | Load halfword | I-type | rd = SignExt(Mem[rs1 + offset]) |
| LB rd, offset(rs1) | Load byte | I-type | rd = SignExt(Mem[rs1 + offset]) |

#### Store Operations
| Instruction | Description | Format | Operation |
|------------|-------------|---------|-----------|
| SW rs2, offset(rs1) | Store word | S-type | Mem[rs1 + offset] = rs2 |
| SH rs2, offset(rs1) | Store halfword | S-type | Mem[rs1 + offset] = rs2[15:0] |
| SB rs2, offset(rs1) | Store byte | S-type | Mem[rs1 + offset] = rs2[7:0] |

### 3. Control Flow Instructions

#### Branch Operations
| Instruction | Description | Format | Operation |
|------------|-------------|---------|-----------|
| BEQ rs1, rs2, offset| BEQ rs1, rs2, offset | Branch if equal | B-type | if(rs1 == rs2) PC += offset |
| BNE rs1, rs2, offset | Branch if not equal | B-type | if(rs1 != rs2) PC += offset |
| BLT rs1, rs2, offset | Branch if less than | B-type | if(rs1 < rs2) PC += offset |
| BGE rs1, rs2, offset | Branch if greater/equal | B-type | if(rs1 >= rs2) PC += offset |

### 4. Comparison Instructions

#### Compare Operations
| Instruction | Description | Format | Operation |
|------------|-------------|---------|-----------|
| SLT rd, rs1, rs2 | Set if less than | R-type | rd = (rs1 < rs2) ? 1 : 0 |
| SLTU rd, rs1, rs2 | Set if less than unsigned | R-type | rd = (rs1 < rs2) ? 1 : 0 |
| SLTI rd, rs1, imm | Set if less than immediate | I-type | rd = (rs1 < imm) ? 1 : 0 |

## Instruction Encoding

### Opcode Map
| Opcode | Type | Instruction Group |
|--------|------|------------------|
| 0110011 | R-type | Register arithmetic/logical |
| 0010011 | I-type | Immediate arithmetic/logical |
| 0000011 | I-type | Load operations |
| 0100011 | S-type | Store operations |
| 1100011 | B-type | Branch operations |

### Function Code Map (funct3)
| funct3 | R-type | I-type | Branch |
|--------|---------|---------|---------|
| 000 | ADD/SUB | ADDI | BEQ |
| 001 | SLL | SLLI | BNE |
| 010 | SLT | SLTI | - |
| 011 | SLTU | SLTIU | - |
| 100 | XOR | XORI | BLT |
| 101 | SRL/SRA | SRLI/SRAI | BGE |
| 110 | OR | ORI | BLTU |
| 111 | AND | ANDI | BGEU |

## Instruction Execution

### Pipeline Stages
1. **Fetch**: Instruction retrieval
   - PC calculation
   - Memory access
   - Instruction buffering

2. **Decode**: Instruction decoding
   - Opcode decoding
   - Register file access
   - Immediate generation
   - Control signal generation

3. **Execute**: Operation execution
   - ALU operation
   - Memory access
   - Branch resolution
   - Write-back

### Execution Timing
| Instruction Type | Cycles | Stages |
|-----------------|---------|--------|
| Register-Register | 3 | F→D→E |
| Load | 3+ | F→D→E(+Memory) |
| Store | 3 | F→D→E |
| Branch (Not Taken) | 3 | F→D→E |
| Branch (Taken) | 3+1 | F→D→E+Flush |

## Instruction Examples

### Arithmetic Example
```assembly
# Calculate: x = (a + b) - (c + d)
ADD  t0, a0, a1    # t0 = a + b
ADD  t1, a2, a3    # t1 = c + d
SUB  a0, t0, t1    # x = (a + b) - (c + d)
```

### Memory Access Example
```assembly
# Array element access: array[i] = array[i] + 1
SLLI t0, a1, 2     # t0 = i * 4 (word offset)
ADD  t1, a0, t0    # t1 = &array[i]
LW   t2, 0(t1)     # t2 = array[i]
ADDI t2, t2, 1     # t2 = array[i] + 1
SW   t2, 0(t1)     # array[i] = t2
```

### Branch Example
```assembly
# Simple loop: for(i=0; i<10; i++)
ADDI t0, zero, 0   # i = 0
ADDI t1, zero, 10  # limit = 10
loop:
    # Loop body
    ADDI t0, t0, 1    # i++
    BLT  t0, t1, loop # if(i < 10) goto loop
```

## Instruction Set Extensions

### Future Extensions
1. Multiplication/Division
   - MUL, DIV, REM instructions
   - Extended ALU support

2. Atomic Operations
   - Load-linked/Store-conditional
   - Atomic arithmetic

3. System Instructions
   - CSR access
   - Exception handling
   - Privilege levels

## Programming Guidelines

### Optimization Tips
1. Use immediate instructions when possible
2. Minimize memory access instructions
3. Optimize branch patterns
4. Utilize register allocation effectively

### Best Practices
1. Align branch targets
2. Use efficient addressing modes
3. Consider pipeline effects
4. Minimize load-use delays

## Appendix

### Instruction Encoding Table
Complete encoding table for all instructions.

### Pipeline Behavior
Detailed pipeline operation for each instruction type.

### Exception Handling
Instruction behavior during exceptions.

### Debug Support
Debug-mode instruction behavior.

---