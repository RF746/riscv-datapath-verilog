`timescale 1ns/1ps
`default_nettype none

module pc_tb;
    logic        clk;
    logic        reset;
    logic [31:0] next_pc;
    logic [31:0] current_pc;
    integer      failures;

    rv32i_pc #(.RESET_VECTOR(32'h0000_0100)) dut (.*);

    always #5 clk = ~clk;

    task automatic clock_once;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task automatic expect_pc(input logic [31:0] expected, input string label);
        begin
            if (current_pc !== expected) begin
                $error("%s: expected %h, got %h", label, expected, current_pc);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        next_pc = 32'b0;
        failures = 0;

        clock_once();
        expect_pc(32'h0000_0100, "reset vector");

        @(negedge clk);
        reset = 1'b0;
        next_pc = 32'h0000_0104;
        clock_once();
        expect_pc(32'h0000_0104, "sequential update");

        @(negedge clk);
        next_pc = 32'h0000_0240;
        clock_once();
        expect_pc(32'h0000_0240, "target update");

        @(negedge clk);
        reset = 1'b1;
        clock_once();
        expect_pc(32'h0000_0100, "second reset");

        if (failures != 0) $fatal(1, "PC test failed with %0d error(s)", failures);
        $display("PASS: pc_tb");
        $finish;
    end
endmodule

`default_nettype wire
