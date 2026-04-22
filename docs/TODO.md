# Architectural TODOs and Improvements

This document tracks planned and suggested improvements for the SimpleARM processor core to enhance its performance, features, and debuggability.

## 1. Instruction Set Architecture (ISA)
- [ ] **M-Extension Support:** Implement hardware multiplication (`MUL`) and division (`DIV`, `REM`) instructions from the ARMv6-M / RV32M subset.
- [ ] **Atomic Instructions:** Add support for atomic read-modify-write operations.
- [ ] **CSRs:** Implement Control and Status Registers for exception handling and performance counters.

## 2. Pipeline Enhancements
- [ ] **Data Forwarding:** Implement forwarding paths from the Execute and Memory stages back to the Decode stage to eliminate stalls for most Register-to-Register RAW hazards.
- [ ] **Load-Use Optimization:** Optimize the load-use stall logic to minimize penalties.
- [ ] **Dynamic Branch Prediction:** Replace the current static "always-not-taken" predictor with a dynamic 1-bit or 2-bit saturating counter and a Branch Target Buffer (BTB).

## 3. Memory Subsystem
- [ ] **Instruction Cache:** Implement a small (e.g., 2KB or 4KB) 2-way set associative L1 instruction cache to improve throughput.
- [ ] **Data Cache:** Implement a write-through L1 data cache.
- [ ] **Bus Matrix:** Upgrade the memory controller to a proper bus matrix supporting multi-master arbitration (e.g., AHB-Lite or TileLink).

## 4. Debug and Verification
- [ ] **Hardware Breakpoints:** Add comparison registers in the JTAG unit to support hardware-based breakpoints and watchpoints.
- [ ] **Run-Control:** Implement full run-control (Halt, Resume, Step) via JTAG.
- [ ] **Cocotb Expansion:** Expand the `test/test.py` suite to include more complex instruction sequences and randomized testing.
- [ ] **Coverage-Driven Verification:** Integrate functional coverage collection into the Cocotb flow.

## 5. Physical Design
- [ ] **Power Gating:** Add support for power domains and gating for the core logic.
- [ ] **Clock Gating:** Implement automated or manual clock gating for idle pipeline stages.
- [ ] **Area Optimization:** Refactor the register file to use more area-efficient technology-mapped macros if available.
