`timescale 1ns/1ps
`default_nettype none

module alu_tb;
    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [3:0]  operation;
    logic [31:0] result;
    logic        zero;
    integer      failures;

    rv32i_alu dut (.*);

    task automatic check_result(
        input logic [3:0] op,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [31:0] expected,
        input string label
    );
        begin
            operation = op;
            operand_a = a;
            operand_b = b;
            #1;
            if (result !== expected) begin
                $error("%s: expected %h, got %h", label, expected, result);
                failures = failures + 1;
            end
            if (zero !== (expected == 32'b0)) begin
                $error("%s: zero flag mismatch", label);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        failures = 0;
        check_result(4'h0, 32'd12, 32'd30, 32'd42, "ADD");
        check_result(4'h1, 32'd12, 32'd30, -32'sd18, "SUB");
        check_result(4'h2, 32'hf0f0_aa55, 32'h0ff0_0f0f, 32'h00f0_0a05, "AND");
        check_result(4'h3, 32'hf000_0000, 32'h0000_00f0, 32'hf000_00f0, "OR");
        check_result(4'h4, 32'haaaa_5555, 32'hffff_0000, 32'h5555_5555, "XOR");
        check_result(4'h5, 32'hffff_ffff, 32'd1, 32'd1, "SLT signed");
        check_result(4'h6, 32'hffff_ffff, 32'd1, 32'd0, "SLTU");
        check_result(4'h7, 32'd1, 32'd8, 32'h0000_0100, "SLL");
        check_result(4'h8, 32'h8000_0000, 32'd4, 32'h0800_0000, "SRL");
        check_result(4'h9, 32'h8000_0000, 32'd4, 32'hf800_0000, "SRA");
        check_result(4'hA, 32'hdead_beef, 32'h1234_5678, 32'h1234_5678, "COPY_B");

        if (failures != 0) $fatal(1, "ALU test failed with %0d error(s)", failures);
        $display("PASS: alu_tb");
        $finish;
    end
endmodule

`default_nettype wire
