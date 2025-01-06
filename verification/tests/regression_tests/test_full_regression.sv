// -----------------------------------------------------------------------------
// File: test_full_regression.sv
// Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
// Purpose: Full regression test suite
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

class test_full_regression extends base_test;
    // Test components
    test_basic_instructions basic_test;
    test_memory_access memory_test;
    test_exceptions exception_test;
    test_pipeline pipeline_test;
    test_jtag jtag_test;
    
    // Virtual interface handle
    virtual simple_arm_if vif;
    
    // Test configuration
    int unsigned iterations = 1;
    bit enable_coverage = 1;
    bit enable_checks = 1;
    
    // Results storage
    int pass_count = 0;
    int fail_count = 0;
    
    // Constructor
    function new(virtual simple_arm_if vif);
        this.vif = vif;
        basic_test = new(vif);
        memory_test = new(vif);
        exception_test = new(vif);
        pipeline_test = new(vif);
        jtag_test = new(vif);
    endfunction
    
    // Main test execution
    task run();
        time start_time, end_time;
        start_time = $time;
        
        $display("\n=== Starting Full Regression Test at %0t ===\n", start_time);
        
        // Run all test iterations
        for (int i = 0; i < iterations; i++) begin
            $display("\n--- Starting Iteration %0d ---\n", i);
            
            // Run individual test suites
            run_basic_tests();
            run_memory_tests();
            run_exception_tests();
            run_pipeline_tests();
            run_jtag_tests();
            
            $display("\n--- Completed Iteration %0d ---\n", i);
        end
        
        end_time = $time;
        print_results(end_time - start_time);
    endtask
    
    // Individual test suite execution tasks
    task run_basic_tests();
        $display("Running Basic Instruction Tests...");
        fork
            basic_test.run();
        join_none
        wait fork;
        check_test_status();
    endtask
    
    task run_memory_tests();
        $display("Running Memory Access Tests...");
        fork
            memory_test.run();
        join_none
        wait fork;
        check_test_status();
    endtask
    
    task run_exception_tests();
        $display("Running Exception Handling Tests...");
        fork
            exception_test.run();
        join_none
        wait fork;
        check_test_status();
    endtask
    
    task run_pipeline_tests();
        $display("Running Pipeline Tests...");
        fork
            pipeline_test.run();
        join_none
        wait fork;
        check_test_status();
    endtask
    
    task run_jtag_tests();
        $display("Running JTAG Interface Tests...");
        fork
            jtag_test.run();
        join_none
        wait fork;
        check_test_status();
    endtask
    
    // Helper tasks and functions
    task check_test_status();
        if ($test$plusargs("enable_timeout")) begin
            fork: timeout_block
                begin
                    #1000000; // 1ms timeout
                    $display("ERROR: Test timeout occurred");
                    disable timeout_block;
                end
            join_none
        end
    endtask
    
    function void print_results(time duration);
        $display("\n=== Regression Test Results ===");
        $display("Total Tests Run:  %0d", pass_count + fail_count);
        $display("Tests Passed:     %0d", pass_count);
        $display("Tests Failed:     %0d", fail_count);
        $display("Total Duration:   %0t", duration);
        $display("Coverage:         %0.2f%%\n", get_coverage());
    endfunction
    
    function real get_coverage();
        if (enable_coverage) begin
            // Get coverage from coverage collector
            return 0.0; // Placeholder
        end else begin
            return 100.0;
        end
    endfunction
    
    // Error injection and recovery
    task inject_error(error_type_e error_type);
        case (error_type)
            MEMORY_ERROR: begin
                // Inject memory error
            end
            PIPELINE_ERROR: begin
                // Inject pipeline error
            end
            JTAG_ERROR: begin
                // Inject JTAG error
            end
            default: begin
                $display("ERROR: Unknown error type");
            end
        endcase
    endtask
    
    task check_error_recovery();
        // Check error recovery logic
    endtask
    
endclass