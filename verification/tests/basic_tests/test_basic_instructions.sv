// -----------------------------------------------------------------------------
// File: test_basic_instructions.sv
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Basic instruction test suite
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

class test_basic_instructions extends base_test;
    // Test sequence storage
    instruction_sequence test_seq;
    
    // Virtual interface handle
    virtual simple_arm_if vif;

    // Constructor
    function new(virtual simple_arm_if vif);
        this.vif = vif;
        test_seq = new();
    endfunction

    // Test execution
    task run();
        $display("Starting Basic Instruction Test at %0t", $time);

        // Initialize processor
        init_processor();

        // Test arithmetic instructions
        test_arithmetic();
        check_results();

        // Test logical instructions
        test_logical();
        check_results();

        // Test memory instructions
        test_memory();
        check_results();

        // Test branch instructions
        test_branch();
        check_results();

        $display("Basic Instruction Test Completed at %0t", $time);
    endtask

    // Processor initialization
    task init_processor();
        // Reset sequence
        @(posedge vif.clk);
        vif.tb_cb.rst_n <= 0;
        repeat(5) @(posedge vif.clk);
        vif.tb_cb.rst_n <= 1;

        // Wait for processor ready
        wait_for_processor_ready();
    endtask

    // Arithmetic instruction tests
    task test_arithmetic();
        // ADD instruction test
        test_seq.add_instruction(ADD_INSTRUCTION, 32'h00000001, 32'h00000002);
        test_seq.add_check(REGISTER_CHECK, 32'h00000003);

        // SUB instruction test
        test_seq.add_instruction(SUB_INSTRUCTION, 32'h00000005, 32'h00000002);
        test_seq.add_check(REGISTER_CHECK, 32'h00000003);

        // Execute sequence
        test_seq.execute(vif);
    endtask

    // Logical instruction tests
    task test_logical();
        // AND instruction test
        test_seq.add_instruction(AND_INSTRUCTION, 32'h0000000F, 32'h00000003);
        test_seq.add_check(REGISTER_CHECK, 32'h00000003);

        // OR instruction test
        test_seq.add_instruction(OR_INSTRUCTION, 32'h0000000F, 32'h00000030);
        test_seq.add_check(REGISTER_CHECK, 32'h0000003F);

        // Execute sequence
        test_seq.execute(vif);
    endtask

    // Memory instruction tests
    task test_memory();
        // Store word test
        test_seq.add_instruction(STR_INSTRUCTION, 32'h00001000, 32'h12345678);
        test_seq.add_check(MEMORY_CHECK, 32'h00001000, 32'h12345678);

        // Load word test
        test_seq.add_instruction(LDR_INSTRUCTION, 32'h00001000, 0);
        test_seq.add_check(REGISTER_CHECK, 32'h12345678);

        // Execute sequence
        test_seq.execute(vif);
    endtask

    // Branch instruction tests
    task test_branch();
        // Branch if equal test
        test_seq.add_instruction(CMP_INSTRUCTION, 32'h00000001, 32'h00000001);
        test_seq.add_instruction(BEQ_INSTRUCTION, 32'h00000010, 0);
        test_seq.add_check(PC_CHECK, 32'h00000010);

        // Execute sequence
        test_seq.execute(vif);
    endtask

    // Helper functions
    task wait_for_processor_ready();
        int timeout = 0;
        while (!is_processor_ready() && timeout < 1000) begin
            @(posedge vif.clk);
            timeout++;
        end
        assert(timeout < 1000) else
            $error("Timeout waiting for processor ready");
    endtask

    function bit is_processor_ready();
        // Add processor ready check logic
        return 1'b1;
    endfunction

    task check_results();
        // Add result checking logic
    endtask

endclass