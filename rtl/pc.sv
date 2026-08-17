`default_nettype none

module rv32i_pc #(
    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000
) (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] next_pc,
    output logic [31:0] current_pc
);
    always_ff @(posedge clk) begin
        if (reset) begin
            current_pc <= RESET_VECTOR;
        end else begin
            current_pc <= next_pc;
        end
    end
endmodule

`default_nettype wire

