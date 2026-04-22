# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
RTL_DIR = $(PWD)/../rtl

# project configuration
PROJECT_SOURCES = project.v \
    ../rtl/top/simple_arm_top.v \
    ../rtl/core/alu.v \
    ../rtl/core/decode_unit.v \
    ../rtl/core/execute_unit.v \
    ../rtl/core/fetch_unit.v \
    ../rtl/core/register_file.v \
    ../rtl/memory/memory_controller.v \
    ../rtl/memory/sram_wrapper.v \
    ../rtl/debug/jtag_controller.v

ifneq ($(GATES),yes)
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
else
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v
endif

# tb
VERILOG_SOURCES += $(PWD)/tb.v

# MODULE is the basename of the Python test file
MODULE = test

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim