// -----------------------------------------------------------------------------
// File: verilator_tb.cpp
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Verilator C++ testbench
// -----------------------------------------------------------------------------

#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsimple_arm_top.h"

#define MAX_SIM_TIME 1000
vluint64_t sim_time = 0;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsimple_arm_top* dut = new Vsimple_arm_top;
    
    // Enable VCD trace
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("simple_arm_trace.vcd");
    
    // Initialize inputs
    dut->clk = 0;
    dut->rst_n = 0;
    dut->tck = 0;
    dut->tms = 0;
    dut->tdi = 0;
    dut->trst_n = 0;
    dut->ext_rdata = 0;
    dut->ext_ready = 0;
    
    std::cout << "========================================" << std::endl;
    std::cout << "SimpleARM Verilator Simulation Starting" << std::endl;
    std::cout << "========================================" << std::endl;
    
    // Simulation loop
    while (sim_time < MAX_SIM_TIME) {
        // Toggle clock
        dut->clk = !dut->clk;
        
        // Toggle JTAG clock (slower)
        if (sim_time % 10 == 0) {
            dut->tck = !dut->tck;
        }
        
        // Release reset after some time
        if (sim_time >= 20) {
            dut->rst_n = 1;
            dut->trst_n = 1;
        }
        
        // External memory ready signal
        if (dut->ext_rd_en || dut->ext_wr_en) {
            dut->ext_ready = 1;
            dut->ext_rdata = 0x12345678;  // Dummy read data
        } else {
            dut->ext_ready = 0;
        }
        
        // Evaluate the design
        dut->eval();
        tfp->dump(sim_time);
        
        sim_time++;
    }
    
    std::cout << "========================================" << std::endl;
    std::cout << "Simulation completed at time " << sim_time << std::endl;
    std::cout << "VCD file: simple_arm_trace.vcd" << std::endl;
    std::cout << "========================================" << std::endl;
    
    tfp->close();
    delete tfp;
    delete dut;
    
    return 0;
}
