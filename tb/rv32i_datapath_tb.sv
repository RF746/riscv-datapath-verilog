`timescale 1ns/1ps
`default_nettype none

module rv32i_datapath_tb;
    logic        clk;
    logic        reset;
    logic [31:0] instruction;
    logic [31:0] instruction_address;
    logic [31:0] data_rdata;
    logic [31:0] data_address;
    logic [31:0] data_wdata;
    logic        data_write_enable;
    logic        illegal_instruction;
    logic [31:0] debug_writeback_data;
    logic [4:0]  debug_writeback_rd;
    logic        debug_writeback_enable;

    logic [31:0] data_memory [0:15];
    integer      failures;
    integer      stores_seen;
    integer      writebacks_seen;
    integer      index;

    rv32i_datapath dut (.*);

    always #5 clk = ~clk;

    // Synthetic program; comments show the instruction at each byte address.
    always_comb begin
        case (instruction_address)
            32'd0:  instruction = 32'h0050_0093; // addi x1, x0, 5
            32'd4:  instruction = 32'h0070_0113; // addi x2, x0, 7
            32'd8:  instruction = 32'h0020_81b3; // add  x3, x1, x2
            32'd12: instruction = 32'h0030_2023; // sw   x3, 0(x0)
            32'd16: instruction = 32'h0000_2203; // lw   x4, 0(x0)
            32'd20: instruction = 32'h0032_0463; // beq  x4, x3, +8
            32'd24: instruction = 32'h0010_0293; // addi x5, x0, 1 (skipped)
            32'd28: instruction = 32'h0080_036f; // jal  x6, +8
            32'd32: instruction = 32'h0020_0393; // addi x7, x0, 2 (skipped)
            32'd36: instruction = 32'h0060_2223; // sw   x6, 4(x0)
            32'd40: instruction = 32'hfff0_0413; // addi x8, x0, -1
            32'd44: instruction = 32'h0004_4463; // blt  x8, x0, +8
            32'd48: instruction = 32'h0090_0493; // addi x9, x0, 9 (skipped)
            32'd52: instruction = 32'h0080_2423; // sw   x8, 8(x0)
            32'd56: instruction = 32'h0000_006f; // jal  x0, 0
            default: instruction = 32'hffff_ffff;
        endcase
    end

    always_comb begin
        if ((data_address[1:0] == 2'b00) && (data_address[31:6] == 26'b0)) begin
            data_rdata = data_memory[data_address[5:2]];
        end else begin
            data_rdata = 32'b0;
        end
    end

    always @(posedge clk) begin
        if (!reset) begin
            if (illegal_instruction) begin
                $error("Illegal instruction at PC %h", instruction_address);
                failures = failures + 1;
            end

            if ((instruction_address == 32'd24) ||
                (instruction_address == 32'd32) ||
                (instruction_address == 32'd48)) begin
                $error("Control-flow instruction failed to skip PC %0d", instruction_address);
                failures = failures + 1;
            end

            if (debug_writeback_enable && (debug_writeback_rd != 5'd0)) begin
                writebacks_seen = writebacks_seen + 1;
                case (instruction_address)
                    32'd0: if ((debug_writeback_rd !== 5'd1) || (debug_writeback_data !== 32'd5)) begin
                        $error("ADDI x1 writeback: expected x1=5, got x%0d=%h", debug_writeback_rd, debug_writeback_data);
                        failures = failures + 1;
                    end
                    32'd4: if ((debug_writeback_rd !== 5'd2) || (debug_writeback_data !== 32'd7)) begin
                        $error("ADDI x2 writeback: expected x2=7, got x%0d=%h", debug_writeback_rd, debug_writeback_data);
                        failures = failures + 1;
                    end
                    32'd8: if ((debug_writeback_rd !== 5'd3) || (debug_writeback_data !== 32'd12)) begin
                        $error("ADD writeback: expected x3=12, got x%0d=%h", debug_writeback_rd, debug_writeback_data);
                        failures = failures + 1;
                    end
                    32'd16: if ((debug_writeback_rd !== 5'd4) || (debug_writeback_data !== 32'd12)) begin
                        $error("LW writeback: expected x4=12, got x%0d=%h", debug_writeback_rd, debug_writeback_data);
                        failures = failures + 1;
                    end
                    32'd28: if ((debug_writeback_rd !== 5'd6) || (debug_writeback_data !== 32'd32)) begin
                        $error("JAL writeback: expected x6=32, got x%0d=%h", debug_writeback_rd, debug_writeback_data);
                        failures = failures + 1;
                    end
                    32'd40: if ((debug_writeback_rd !== 5'd8) || (debug_writeback_data !== 32'hffff_ffff)) begin
                        $error("Signed-immediate writeback: expected x8=ffffffff, got x%0d=%h", debug_writeback_rd, debug_writeback_data);
                        failures = failures + 1;
                    end
                    default: begin
                        $error("Unexpected nonzero-register writeback at PC %0d", instruction_address);
                        failures = failures + 1;
                    end
                endcase
            end

            if (data_write_enable) begin
                stores_seen <= stores_seen + 1;
                if ((data_address[1:0] != 2'b00) || (data_address[31:6] != 26'b0)) begin
                    $error("Out-of-range or misaligned store to %h", data_address);
                    failures = failures + 1;
                end else begin
                    data_memory[data_address[5:2]] <= data_wdata;
                    case (data_address)
                        32'd0: if (data_wdata !== 32'd12) begin
                            $error("ADD/store result: expected 12, got %h", data_wdata);
                            failures = failures + 1;
                        end
                        32'd4: if (data_wdata !== 32'd32) begin
                            $error("JAL link value: expected 32, got %h", data_wdata);
                            failures = failures + 1;
                        end
                        32'd8: if (data_wdata !== 32'hffff_ffff) begin
                            $error("Signed immediate result: expected ffffffff, got %h", data_wdata);
                            failures = failures + 1;
                        end
                        default: begin
                            $error("Unexpected store address %h", data_address);
                            failures = failures + 1;
                        end
                    endcase
                end
            end
        end
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        failures = 0;
        stores_seen = 0;
        writebacks_seen = 0;
        for (index = 0; index < 16; index = index + 1) begin
            data_memory[index] = 32'b0;
        end

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        repeat (20) @(posedge clk);
        #1;

        if (stores_seen !== 3) begin
            $error("Expected 3 stores, observed %0d", stores_seen);
            failures = failures + 1;
        end
        if (writebacks_seen !== 6) begin
            $error("Expected 6 nonzero-register writebacks, observed %0d", writebacks_seen);
            failures = failures + 1;
        end
        if (data_memory[0] !== 32'd12) begin
            $error("Memory[0] expected 12, got %h", data_memory[0]);
            failures = failures + 1;
        end
        if (data_memory[1] !== 32'd32) begin
            $error("Memory[1] expected 32, got %h", data_memory[1]);
            failures = failures + 1;
        end
        if (data_memory[2] !== 32'hffff_ffff) begin
            $error("Memory[2] expected ffffffff, got %h", data_memory[2]);
            failures = failures + 1;
        end

        if (failures != 0) $fatal(1, "Integration test failed with %0d error(s)", failures);
        $display("PASS: rv32i_datapath_tb");
        $finish;
    end
endmodule

`default_nettype wire
