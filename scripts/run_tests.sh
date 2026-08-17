#!/bin/sh
set -eu

SIM=${SIM:-iverilog}
VVP=${VVP:-vvp}

if ! command -v "$SIM" >/dev/null 2>&1; then
    echo "error: $SIM is required (install Icarus Verilog)" >&2
    exit 127
fi

if ! command -v "$VVP" >/dev/null 2>&1; then
    echo "error: $VVP is required (installed with Icarus Verilog)" >&2
    exit 127
fi

mkdir -p build

RTL_SOURCES="rtl/alu.sv rtl/register_file.sv rtl/control_unit.sv rtl/pc.sv rtl/rv32i_datapath.sv"
TESTS="alu register_file control_unit pc rv32i_datapath"

for test_name in $TESTS; do
    echo "[compile] ${test_name}_tb"
    # shellcheck disable=SC2086
    "$SIM" -g2012 -Wall -s "${test_name}_tb" \
        -o "build/${test_name}_tb.vvp" \
        $RTL_SOURCES "tb/${test_name}_tb.sv"
    echo "[run]     ${test_name}_tb"
    "$VVP" "build/${test_name}_tb.vvp"
done

echo "All RTL tests passed."

