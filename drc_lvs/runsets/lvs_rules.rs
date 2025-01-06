# -----------------------------------------------------------------------------
# File: lvs_rules.rs
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Netgen LVS rule deck for Sky130 process
# -----------------------------------------------------------------------------

# Basic setup
verbose 1
lvs_prefix LVS
catch {load sky130.tech}
tech load sky130 -noundostack

# Comparison options
set compare_options {
    -abstract
    -permute
    -property
    -parallel
}

# Property rules
property_rules {
    constant {VDD VSS}
    power {VDD}
    ground {VSS}
}

# Layer mapping rules
layer_map {
    Metal1 metal1
    Metal2 metal2
    Metal3 metal3
    Metal4 metal4
    Metal5 metal5
    Metal6 metal6
    Via1   via1
    Via2   via2
    Via3   via3
    Via4   via4
    Via5   via5
}

# Device mapping rules
device_map {
    nmos nmos
    pmos pmos
    cap  cap
    res  res
    diode diode
}

# Special handling for SRAM macro
macro_handling {
    sky130_sram_8kx32_word {
        blackbox
        ports {
            clk0
            csb0
            web0
            wmask0[*]
            addr0[*]
            din0[*]
            dout0[*]
            VDD
            VSS
        }
    }
}

# Electrical equivalence rules
equivalent {
    parallel {
        devices {nmos pmos cap res}
        threshold {
            length 0.001
            width  0.001
        }
    }
    series {
        devices {res}
        combine true
    }
}

# Net equivalence rules
net_equiv {
    join_nets true
    name_nets true
    combine_implicit true
}

# Hierarchy handling
hierarchy {
    flatten_cells {
        simple_arm_top
        fetch_unit
        decode_unit
        execute_unit
        register_file
        memory_controller
        jtag_controller
    }
    preserve_cells {
        sky130_sram_8kx32_word
    }
}

# Port matching rules
port_match {
    by_name true
    by_order false
    exact_match true
}

# Element handling rules
element {
    parallel_merge true
    series_merge true
    tolerance 0.001
}

# Power handling
power {
    treat_implicit_power true
    power_nets {VDD}
    ground_nets {VSS}
}

# LVS command options
set_lvs_options {
    -max_errors 1000
    -cell_error_limit 100
    -report_unmatched true
    -max_print_errors 50
}

# Special pattern matching rules
pattern_match {
    clock_nets {
        clk*
        *_clk
        *_clock
    }
    reset_nets {
        rst*
        *_rst
        *_reset
    }
    scan_nets {
        scan*
        test*
        *_test
    }
}

# Special net handling
special_nets {
    power_nets {
        VDD
        VDD_*
        *_VDD
    }
    ground_nets {
        VSS
        VSS_*
        *_VSS
    }
    clock_nets {
        clk
        tck
    }
}

# Device parameters to compare
device_param_match {
    nmos {
        w l
        as ad
        ps pd
    }
    pmos {
        w l
        as ad
        ps pd
    }
    cap {
        w l
        value
    }
    res {
        w l
        value
    }
}

# End of rule deck