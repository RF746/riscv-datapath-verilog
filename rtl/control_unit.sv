`default_nettype none

module rv32i_control_unit (
    input  logic [31:0] instruction,
    output logic        register_write,
    output logic        memory_write,
    output logic        alu_source_immediate,
    output logic        alu_source_pc,
    output logic [1:0]  writeback_select,
    output logic [2:0]  immediate_select,
    output logic [3:0]  alu_operation,
    output logic        branch,
    output logic        jump,
    output logic        jump_register,
    output logic        illegal_instruction
);
    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
    localparam logic [6:0] OPCODE_AUIPC  = 7'b0010111;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_OP     = 7'b0110011;
    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;

    localparam logic [2:0] IMM_I = 3'd0;
    localparam logic [2:0] IMM_S = 3'd1;
    localparam logic [2:0] IMM_B = 3'd2;
    localparam logic [2:0] IMM_U = 3'd3;
    localparam logic [2:0] IMM_J = 3'd4;

    localparam logic [1:0] WB_ALU = 2'd0;
    localparam logic [1:0] WB_MEM = 2'd1;
    localparam logic [1:0] WB_PC4 = 2'd2;

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

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    always_comb begin
        opcode = instruction[6:0];
        funct3 = instruction[14:12];
        funct7 = instruction[31:25];

        register_write      = 1'b0;
        memory_write        = 1'b0;
        alu_source_immediate = 1'b0;
        alu_source_pc       = 1'b0;
        writeback_select    = WB_ALU;
        immediate_select    = IMM_I;
        alu_operation       = ALU_ADD;
        branch              = 1'b0;
        jump                = 1'b0;
        jump_register       = 1'b0;
        illegal_instruction = 1'b1;

        case (opcode)
            OPCODE_OP: begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000) begin
                            alu_operation       = ALU_ADD;
                            register_write      = 1'b1;
                            illegal_instruction = 1'b0;
                        end else if (funct7 == 7'b0100000) begin
                            alu_operation       = ALU_SUB;
                            register_write      = 1'b1;
                            illegal_instruction = 1'b0;
                        end
                    end
                    3'b001: if (funct7 == 7'b0000000) begin
                        alu_operation = ALU_SLL; register_write = 1'b1; illegal_instruction = 1'b0;
                    end
                    3'b010: if (funct7 == 7'b0000000) begin
                        alu_operation = ALU_SLT; register_write = 1'b1; illegal_instruction = 1'b0;
                    end
                    3'b011: if (funct7 == 7'b0000000) begin
                        alu_operation = ALU_SLTU; register_write = 1'b1; illegal_instruction = 1'b0;
                    end
                    3'b100: if (funct7 == 7'b0000000) begin
                        alu_operation = ALU_XOR; register_write = 1'b1; illegal_instruction = 1'b0;
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            alu_operation       = ALU_SRL;
                            register_write      = 1'b1;
                            illegal_instruction = 1'b0;
                        end else if (funct7 == 7'b0100000) begin
                            alu_operation       = ALU_SRA;
                            register_write      = 1'b1;
                            illegal_instruction = 1'b0;
                        end
                    end
                    3'b110: if (funct7 == 7'b0000000) begin
                        alu_operation = ALU_OR; register_write = 1'b1; illegal_instruction = 1'b0;
                    end
                    3'b111: if (funct7 == 7'b0000000) begin
                        alu_operation = ALU_AND; register_write = 1'b1; illegal_instruction = 1'b0;
                    end
                    default: begin end
                endcase
            end

            OPCODE_OP_IMM: begin
                case (funct3)
                    3'b000: begin alu_operation = ALU_ADD;  register_write = 1'b1; illegal_instruction = 1'b0; end
                    3'b010: begin alu_operation = ALU_SLT;  register_write = 1'b1; illegal_instruction = 1'b0; end
                    3'b011: begin alu_operation = ALU_SLTU; register_write = 1'b1; illegal_instruction = 1'b0; end
                    3'b100: begin alu_operation = ALU_XOR;  register_write = 1'b1; illegal_instruction = 1'b0; end
                    3'b110: begin alu_operation = ALU_OR;   register_write = 1'b1; illegal_instruction = 1'b0; end
                    3'b111: begin alu_operation = ALU_AND;  register_write = 1'b1; illegal_instruction = 1'b0; end
                    3'b001: if (funct7 == 7'b0000000) begin
                        alu_operation = ALU_SLL; register_write = 1'b1; illegal_instruction = 1'b0;
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            alu_operation       = ALU_SRL;
                            register_write      = 1'b1;
                            illegal_instruction = 1'b0;
                        end else if (funct7 == 7'b0100000) begin
                            alu_operation       = ALU_SRA;
                            register_write      = 1'b1;
                            illegal_instruction = 1'b0;
                        end
                    end
                    default: begin end
                endcase
                alu_source_immediate = 1'b1;
                immediate_select     = IMM_I;
            end

            OPCODE_LOAD: begin
                if (funct3 == 3'b010) begin
                    register_write       = 1'b1;
                    alu_source_immediate = 1'b1;
                    writeback_select     = WB_MEM;
                    immediate_select     = IMM_I;
                    alu_operation        = ALU_ADD;
                    illegal_instruction  = 1'b0;
                end
            end

            OPCODE_STORE: begin
                if (funct3 == 3'b010) begin
                    memory_write         = 1'b1;
                    alu_source_immediate = 1'b1;
                    immediate_select     = IMM_S;
                    alu_operation        = ALU_ADD;
                    illegal_instruction  = 1'b0;
                end
            end

            OPCODE_BRANCH: begin
                if ((funct3 == 3'b000) || (funct3 == 3'b001) ||
                    (funct3 == 3'b100) || (funct3 == 3'b101) ||
                    (funct3 == 3'b110) || (funct3 == 3'b111)) begin
                    branch              = 1'b1;
                    immediate_select    = IMM_B;
                    alu_operation       = ALU_SUB;
                    illegal_instruction = 1'b0;
                end
            end

            OPCODE_JAL: begin
                register_write      = 1'b1;
                writeback_select    = WB_PC4;
                immediate_select    = IMM_J;
                jump                = 1'b1;
                illegal_instruction = 1'b0;
            end

            OPCODE_JALR: begin
                if (funct3 == 3'b000) begin
                    register_write       = 1'b1;
                    writeback_select     = WB_PC4;
                    immediate_select     = IMM_I;
                    alu_source_immediate = 1'b1;
                    jump                 = 1'b1;
                    jump_register        = 1'b1;
                    illegal_instruction  = 1'b0;
                end
            end

            OPCODE_LUI: begin
                register_write       = 1'b1;
                alu_source_immediate = 1'b1;
                immediate_select     = IMM_U;
                alu_operation        = ALU_COPY_B;
                illegal_instruction  = 1'b0;
            end

            OPCODE_AUIPC: begin
                register_write       = 1'b1;
                alu_source_immediate = 1'b1;
                alu_source_pc        = 1'b1;
                immediate_select     = IMM_U;
                alu_operation        = ALU_ADD;
                illegal_instruction  = 1'b0;
            end

            default: begin end
        endcase
    end
endmodule

`default_nettype wire

