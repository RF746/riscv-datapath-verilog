`default_nettype none

module rv32i_register_file (
    input  logic        clk,
    input  logic [4:0]  rs1_address,
    input  logic [4:0]  rs2_address,
    input  logic [4:0]  rd_address,
    input  logic [31:0] write_data,
    input  logic        write_enable,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);
    logic [31:0] registers [0:31];

    always_ff @(posedge clk) begin
        if (write_enable && (rd_address != 5'd0)) begin
            registers[rd_address] <= write_data;
        end
    end

    always_comb begin
        rs1_data = (rs1_address == 5'd0) ? 32'b0 : registers[rs1_address];
        rs2_data = (rs2_address == 5'd0) ? 32'b0 : registers[rs2_address];
    end
endmodule

`default_nettype wire

