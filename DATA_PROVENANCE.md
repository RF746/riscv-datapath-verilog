# Data Provenance and Sanitization

## Source origin

The RTL, testbenches, scripts, and documentation in this repository were newly
prepared as a sanitized public reconstruction for this portfolio. They
demonstrate the architecture described in the project history, but they are not
the original historical repository or independent proof of the earlier work.
The instruction formats follow the publicly documented RISC-V base integer
encoding conventions.

## Test data

The testbenches use only synthetic operands and a short, hand-assembled
instruction sequence committed in `tb/rv32i_datapath_tb.sv`. There are no
customer records, device logs, production traces, proprietary benchmarks, or
third-party datasets.

## Sanitization statement

This repository contains no employer source code, internal URLs, private issue
identifiers, credentials, access tokens, confidential specifications, or
non-public performance data. Names in the implementation are generic hardware
design terms.

## Reproducibility

All functional claims in the README are bounded by the committed RTL and
self-checking tests. The test runner and continuous-integration workflow are
included so that results can be reproduced with Icarus Verilog. No silicon,
timing, power, area, or standards-compliance claim is made.
