# -----------------------------------------------------------------------------
# SimpleARM Project Makefile
# -----------------------------------------------------------------------------

.PHONY: all help sim test synth harden formal clean

help:
	@echo "SimpleARM Build System"
	@echo "Available targets:"
	@echo "  make sim     - Run Verilator RTL simulation (C++ testbench)"
	@echo "  make test    - Run Cocotb verification (TinyTapeout wrapper)"
	@echo "  make synth   - Run Yosys synthesis (targeting Sky130)"
	@echo "  make harden  - Run OpenLane physical implementation (Docker)"
	@echo "  make formal  - Run SymbiYosys formal verification"
	@echo "  make clean   - Remove all generated artifacts"

all: sim test formal synth

sim:
	bash scripts/run_verilator.sh

test:
	$(MAKE) -C test -B

synth:
	yosys scripts/run_sky130_synth.ys

harden:
	bash scripts/run_openlane_docker.sh

formal:
	sby -f verification/formal/simple_arm_top.sby

clean:
	rm -rf sim_verilator/
	rm -rf runs/
	rm -rf simple_arm_top/
	rm -rf test/sim_build/
	rm -f test/results.xml
	rm -f test/tb.vcd
	rm -f *.vcd
	rm -f synthesis_result.json
	rm -f simple_arm_sky130.v
	rm -f simple_arm_sky130.json
