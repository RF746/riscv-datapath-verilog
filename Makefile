SIM ?= iverilog
VVP ?= vvp

RTL := \
	rtl/alu.sv \
	rtl/register_file.sv \
	rtl/control_unit.sv \
	rtl/pc.sv \
	rtl/rv32i_datapath.sv

.PHONY: all test lint clean

all: test

test:
	SIM="$(SIM)" VVP="$(VVP)" sh scripts/run_tests.sh

lint:
	@command -v "$(SIM)" >/dev/null 2>&1 || { \
		echo "error: $(SIM) is required (install Icarus Verilog)" >&2; \
		exit 127; \
	}
	@mkdir -p build
	$(SIM) -g2012 -Wall -s rv32i_datapath -tnull $(RTL)

clean:
	rm -rf build

