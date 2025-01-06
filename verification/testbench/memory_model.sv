// -----------------------------------------------------------------------------
// File: memory_model.sv
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: SystemVerilog memory model for testbench
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

module memory_model (
    input  logic        clk,           // System clock
    input  logic        rst_n,         // Reset (active low)
    input  logic [31:0] addr,          // Address
    input  logic [31:0] wdata,         // Write data
    output logic [31:0] rdata,         // Read data
    input  logic        wr_en,         // Write enable
    input  logic        rd_en,         // Read enable
    input  logic [3:0]  byte_en,       // Byte enable
    output logic        ready          // Ready signal
);

    // Memory array - 8KB total (matches SRAM size)
    logic [7:0] mem[0:8191];  // Byte-addressable memory
    
    // Ready signal generation
    logic [2:0] ready_counter;
    logic       access_pending;
    
    // Read data composition
    logic [31:0] read_data;
    
    // Latency simulation
    localparam READ_LATENCY  = 2;  // 2 cycle read latency
    localparam WRITE_LATENCY = 1;  // 1 cycle write latency
    
    // Internal signals
    logic [31:0] pending_addr;
    logic [31:0] pending_wdata;
    logic [3:0]  pending_byte_en;
    logic        pending_wr_en;
    
    // Ready signal generation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_counter  <= '0;
            access_pending <= 1'b0;
            ready         <= 1'b0;
        end else begin
            if (rd_en || wr_en) begin
                if (!access_pending) begin
                    access_pending <= 1'b1;
                    ready_counter  <= rd_en ? READ_LATENCY[2:0] : WRITE_LATENCY[2:0];
                    ready         <= 1'b0;
                    
                    // Store pending access information
                    pending_addr    <= addr;
                    pending_wdata   <= wdata;
                    pending_byte_en <= byte_en;
                    pending_wr_en   <= wr_en;
                end
            end else if (access_pending) begin
                if (ready_counter > 0) begin
                    ready_counter <= ready_counter - 1;
                    ready        <= (ready_counter == 1);
                    
                    if (ready_counter == 1) begin
                        access_pending <= 1'b0;
                    end
                end
            end else begin
                ready <= 1'b0;
            end
        end
    end
    
    // Write operation
    always_ff @(posedge clk) begin
        if (access_pending && pending_wr_en && ready) begin
            if (pending_byte_en[0]) mem[pending_addr]     <= pending_wdata[7:0];
            if (pending_byte_en[1]) mem[pending_addr + 1] <= pending_wdata[15:8];
            if (pending_byte_en[2]) mem[pending_addr + 2] <= pending_wdata[23:16];
            if (pending_byte_en[3]) mem[pending_addr + 3] <= pending_wdata[31:24];
        end
    end
    
    // Read operation
    always_comb begin
        read_data = '0;
        if (access_pending && !pending_wr_en) begin
            read_data[7:0]   = mem[pending_addr];
            read_data[15:8]  = mem[pending_addr + 1];
            read_data[23:16] = mem[pending_addr + 2];
            read_data[31:24] = mem[pending_addr + 3];
        end
    end
    
    // Output read data when ready
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata <= '0;
        end else if (ready && !pending_wr_en) begin
            rdata <= read_data;
        end
    end
    
    // Memory initialization task
    task initialize_memory(input string filename);
        $readmemh(filename, mem);
    endtask
    
    // Memory dump task
    task dump_memory(input string filename, input int start_addr, input int end_addr);
        int fd;
        fd = $fopen(filename, "w");
        for (int i = start_addr; i <= end_addr; i += 4) begin
            $fdisplay(fd, "%08h: %02h%02h%02h%02h", i, 
                     mem[i+3], mem[i+2], mem[i+1], mem[i]);
        end
        $fclose(fd);
    endtask
    
    // Memory comparison task
    task compare_memory(input string filename, output bit match);
        logic [7:0] ref_mem[0:8191];
        match = 1'b1;
        
        $readmemh(filename, ref_mem);
        for (int i = 0; i < 8192; i++) begin
            if (mem[i] !== ref_mem[i]) begin
                $display("Mismatch at address %0h: Expected %0h, Got %0h",
                        i, ref_mem[i], mem[i]);
                match = 1'b0;
            end
        end
    endtask
    
    // Memory pattern generation task
    task generate_pattern(input logic [7:0] pattern);
        for (int i = 0; i < 8192; i++) begin
            mem[i] = pattern ^ i[7:0];
        end
    endtask
    
    // Error injection for testing error handling
    task inject_error(input int addr, input logic [7:0] error_data);
        mem[addr] = error_data;
    endtask

    // Memory consistency check
    function bit check_consistency(input int start_addr, input int end_addr);
        bit result = 1'b1;
        for (int i = start_addr; i < end_addr; i += 4) begin
            if (!check_word_valid(i)) begin
                result = 1'b0;
                $display("Invalid memory word at address %0h", i);
            end
        end
        return result;
    endfunction

    // Helper function to check word validity
    function bit check_word_valid(input int addr);
        // Add memory validity checks here
        return 1'b1;
    endfunction

endmodule