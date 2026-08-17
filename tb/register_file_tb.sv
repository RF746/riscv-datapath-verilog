`timescale 1ns/1ps
`default_nettype none

module register_file_tb;
    logic        clk;
    logic [4:0]  rs1_address;
    logic [4:0]  rs2_address;
    logic [4:0]  rd_address;
    logic [31:0] write_data;
    logic        write_enable;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    integer      failures;

    rv32i_register_file dut (.*);

    always #5 clk = ~clk;

    task automatic write_register(input logic [4:0] address, input logic [31:0] value);
        begin
            @(negedge clk);
            rd_address = address;
            write_data = value;
            write_enable = 1'b1;
            @(posedge clk);
            #1;
            write_enable = 1'b0;
        end
    endtask

    task automatic expect_value(input logic [31:0] actual, input logic [31:0] expected, input string label);
        begin
            if (actual !== expected) begin
                $error("%s: expected %h, got %h", label, expected, actual);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        failures = 0;
        rs1_address = 5'd0;
        rs2_address = 5'd0;
        rd_address = 5'd0;
        write_data = 32'b0;
        write_enable = 1'b0;

        write_register(5'd5, 32'h1234_5678);
        write_register(5'd9, 32'hcafe_babe);
        rs1_address = 5'd5;
        rs2_address = 5'd9;
        #1;
        expect_value(rs1_data, 32'h1234_5678, "x5 read");
        expect_value(rs2_data, 32'hcafe_babe, "x9 read");

        write_register(5'd0, 32'hffff_ffff);
        rs1_address = 5'd0;
        #1;
        expect_value(rs1_data, 32'b0, "x0 remains zero");

        if (failures != 0) $fatal(1, "Register-file test failed with %0d error(s)", failures);
        $display("PASS: register_file_tb");
        $finish;
    end
endmodule

`default_nettype wire
