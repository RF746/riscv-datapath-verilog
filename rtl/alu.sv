`default_nettype none

module rv32i_alu (
    input  logic [31:0] operand_a,
    input  logic [31:0] operand_b,
    input  logic [3:0]  operation,
    output logic [31:0] result,
    output logic        zero
);
    localparam logic [3:0] ALU_ADD    = 4'h0;
    localparam logic [3:0] ALU_SUB    = 4'h1;
    localparam logic [3:0] ALU_AND    = 4'h2;
    localparam logic [3:0] ALU_OR     = 4'h3;
    localparam logic [3:0] ALU_XOR    = 4'h4;
    localparam logic [3:0] ALU_SLT    = 4'h5;
    localparam logic [3:0] ALU_SLTU   = 4'h6;
    localparam logic [3:0] ALU_SLL    = 4'h7;
    localparam logic [3:0] ALU_SRL    = 4'h8;
    localparam logic [3:0] ALU_SRA    = 4'h9;
    localparam logic [3:0] ALU_COPY_B = 4'hA;

    always_comb begin
        case (operation)
            ALU_ADD:    result = operand_a + operand_b;
            ALU_SUB:    result = operand_a - operand_b;
            ALU_AND:    result = operand_a & operand_b;
            ALU_OR:     result = operand_a | operand_b;
            ALU_XOR:    result = operand_a ^ operand_b;
            ALU_SLT:    result = {31'b0, $signed(operand_a) < $signed(operand_b)};
            ALU_SLTU:   result = {31'b0, operand_a < operand_b};
            ALU_SLL:    result = operand_a << operand_b[4:0];
            ALU_SRL:    result = operand_a >> operand_b[4:0];
            ALU_SRA:    result = $signed(operand_a) >>> operand_b[4:0];
            ALU_COPY_B: result = operand_b;
            default:    result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);
endmodule

`default_nettype wire

