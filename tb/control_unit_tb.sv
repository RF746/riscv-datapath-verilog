`timescale 1ns/1ps
`default_nettype none

module control_unit_tb;
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

    logic [31:0] instruction;
    logic        register_write;
    logic        memory_write;
    logic        alu_source_immediate;
    logic        alu_source_pc;
    logic [1:0]  writeback_select;
    logic [2:0]  immediate_select;
    logic [3:0]  alu_operation;
    logic        branch;
    logic        jump;
    logic        jump_register;
    logic        illegal_instruction;
    integer      failures;

    rv32i_control_unit dut (.*);

    function automatic logic [31:0] encode_r(
        input logic [6:0] funct7_value,
        input logic [2:0] funct3_value
    );
        encode_r = {funct7_value, 5'd2, 5'd1, funct3_value, 5'd3, OPCODE_OP};
    endfunction

    function automatic logic [31:0] encode_i(
        input logic [11:0] immediate_value,
        input logic [2:0]  funct3_value,
        input logic [6:0]  opcode_value
    );
        encode_i = {immediate_value, 5'd1, funct3_value, 5'd3, opcode_value};
    endfunction

    function automatic logic [31:0] encode_s(
        input logic [11:0] immediate_value,
        input logic [2:0]  funct3_value
    );
        encode_s = {immediate_value[11:5], 5'd2, 5'd1, funct3_value,
                    immediate_value[4:0], OPCODE_STORE};
    endfunction

    function automatic logic [31:0] encode_b(
        input logic [12:0] immediate_value,
        input logic [2:0]  funct3_value
    );
        encode_b = {immediate_value[12], immediate_value[10:5], 5'd2, 5'd1,
                    funct3_value, immediate_value[4:1], immediate_value[11],
                    OPCODE_BRANCH};
    endfunction

    function automatic logic [31:0] encode_u(
        input logic [19:0] immediate_value,
        input logic [6:0]  opcode_value
    );
        encode_u = {immediate_value, 5'd3, opcode_value};
    endfunction

    function automatic logic [31:0] encode_j(input logic [20:0] immediate_value);
        encode_j = {immediate_value[20], immediate_value[10:1],
                    immediate_value[11], immediate_value[19:12], 5'd3,
                    OPCODE_JAL};
    endfunction

    task automatic check_instruction(
        input logic [31:0] encoded_instruction,
        input string       label,
        input logic        expected_illegal,
        input logic        expected_register_write,
        input logic        expected_memory_write,
        input logic        expected_alu_immediate,
        input logic        expected_alu_pc,
        input logic [1:0]  expected_writeback,
        input logic [2:0]  expected_immediate,
        input logic [3:0]  expected_alu_operation,
        input logic        expected_branch,
        input logic        expected_jump,
        input logic        expected_jump_register
    );
        logic [16:0] actual_controls;
        logic [16:0] expected_controls;
        begin
            instruction = encoded_instruction;
            #1;
            actual_controls = {
                illegal_instruction,
                register_write,
                memory_write,
                alu_source_immediate,
                alu_source_pc,
                writeback_select,
                immediate_select,
                alu_operation,
                branch,
                jump,
                jump_register
            };
            expected_controls = {
                expected_illegal,
                expected_register_write,
                expected_memory_write,
                expected_alu_immediate,
                expected_alu_pc,
                expected_writeback,
                expected_immediate,
                expected_alu_operation,
                expected_branch,
                expected_jump,
                expected_jump_register
            };
            if (actual_controls !== expected_controls) begin
                $error("%s: expected controls %017b, got %017b",
                       label, expected_controls, actual_controls);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        failures = 0;

        // Every register-register instruction advertised in the README.
        check_instruction(encode_r(7'b0000000, 3'b000), "ADD",  0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_ADD,  0, 0, 0);
        check_instruction(encode_r(7'b0100000, 3'b000), "SUB",  0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_SUB,  0, 0, 0);
        check_instruction(encode_r(7'b0000000, 3'b001), "SLL",  0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_SLL,  0, 0, 0);
        check_instruction(encode_r(7'b0000000, 3'b010), "SLT",  0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_SLT,  0, 0, 0);
        check_instruction(encode_r(7'b0000000, 3'b011), "SLTU", 0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_SLTU, 0, 0, 0);
        check_instruction(encode_r(7'b0000000, 3'b100), "XOR",  0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_XOR,  0, 0, 0);
        check_instruction(encode_r(7'b0000000, 3'b101), "SRL",  0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_SRL,  0, 0, 0);
        check_instruction(encode_r(7'b0100000, 3'b101), "SRA",  0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_SRA,  0, 0, 0);
        check_instruction(encode_r(7'b0000000, 3'b110), "OR",   0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_OR,   0, 0, 0);
        check_instruction(encode_r(7'b0000000, 3'b111), "AND",  0, 1, 0, 0, 0, WB_ALU, IMM_I, ALU_AND,  0, 0, 0);

        // Every immediate arithmetic and shift instruction.
        check_instruction(encode_i(12'h005, 3'b000, OPCODE_OP_IMM), "ADDI",  0, 1, 0, 1, 0, WB_ALU, IMM_I, ALU_ADD,  0, 0, 0);
        check_instruction(encode_i(12'h005, 3'b010, OPCODE_OP_IMM), "SLTI",  0, 1, 0, 1, 0, WB_ALU, IMM_I, ALU_SLT,  0, 0, 0);
        check_instruction(encode_i(12'h005, 3'b011, OPCODE_OP_IMM), "SLTIU", 0, 1, 0, 1, 0, WB_ALU, IMM_I, ALU_SLTU, 0, 0, 0);
        check_instruction(encode_i(12'h005, 3'b100, OPCODE_OP_IMM), "XORI",  0, 1, 0, 1, 0, WB_ALU, IMM_I, ALU_XOR,  0, 0, 0);
        check_instruction(encode_i(12'h005, 3'b110, OPCODE_OP_IMM), "ORI",   0, 1, 0, 1, 0, WB_ALU, IMM_I, ALU_OR,   0, 0, 0);
        check_instruction(encode_i(12'h005, 3'b111, OPCODE_OP_IMM), "ANDI",  0, 1, 0, 1, 0, WB_ALU, IMM_I, ALU_AND,  0, 0, 0);
        check_instruction(encode_i(12'h003, 3'b001, OPCODE_OP_IMM), "SLLI",  0, 1, 0, 1, 0, WB_ALU, IMM_I, ALU_SLL,  0, 0, 0);
        check_instruction(encode_i(12'h003, 3'b101, OPCODE_OP_IMM), "SRLI",  0, 1, 0, 1, 0, WB_ALU, IMM_I, ALU_SRL,  0, 0, 0);
        check_instruction(encode_i(12'h403, 3'b101, OPCODE_OP_IMM), "SRAI",  0, 1, 0, 1, 0, WB_ALU, IMM_I, ALU_SRA,  0, 0, 0);

        check_instruction(encode_u(20'h12345, OPCODE_LUI),   "LUI",   0, 1, 0, 1, 0, WB_ALU, IMM_U, ALU_COPY_B, 0, 0, 0);
        check_instruction(encode_u(20'h12345, OPCODE_AUIPC), "AUIPC", 0, 1, 0, 1, 1, WB_ALU, IMM_U, ALU_ADD,    0, 0, 0);
        check_instruction(encode_i(12'h008, 3'b010, OPCODE_LOAD), "LW", 0, 1, 0, 1, 0, WB_MEM, IMM_I, ALU_ADD, 0, 0, 0);
        check_instruction(encode_s(12'h008, 3'b010), "SW", 0, 0, 1, 1, 0, WB_ALU, IMM_S, ALU_ADD, 0, 0, 0);

        // All six supported conditional branches plus both jump forms.
        check_instruction(encode_b(13'd8, 3'b000), "BEQ",  0, 0, 0, 0, 0, WB_ALU, IMM_B, ALU_SUB, 1, 0, 0);
        check_instruction(encode_b(13'd8, 3'b001), "BNE",  0, 0, 0, 0, 0, WB_ALU, IMM_B, ALU_SUB, 1, 0, 0);
        check_instruction(encode_b(13'd8, 3'b100), "BLT",  0, 0, 0, 0, 0, WB_ALU, IMM_B, ALU_SUB, 1, 0, 0);
        check_instruction(encode_b(13'd8, 3'b101), "BGE",  0, 0, 0, 0, 0, WB_ALU, IMM_B, ALU_SUB, 1, 0, 0);
        check_instruction(encode_b(13'd8, 3'b110), "BLTU", 0, 0, 0, 0, 0, WB_ALU, IMM_B, ALU_SUB, 1, 0, 0);
        check_instruction(encode_b(13'd8, 3'b111), "BGEU", 0, 0, 0, 0, 0, WB_ALU, IMM_B, ALU_SUB, 1, 0, 0);
        check_instruction(encode_j(21'd8), "JAL", 0, 1, 0, 0, 0, WB_PC4, IMM_J, ALU_ADD, 0, 1, 0);
        check_instruction(encode_i(12'h008, 3'b000, OPCODE_JALR), "JALR", 0, 1, 0, 1, 0, WB_PC4, IMM_I, ALU_ADD, 0, 1, 1);

        // Malformed and unsupported encodings must suppress architectural writes.
        check_instruction(encode_r(7'b0000001, 3'b000), "Malformed ADD funct7", 1, 0, 0, 0, 0, WB_ALU, IMM_I, ALU_ADD, 0, 0, 0);
        check_instruction(encode_r(7'b0100000, 3'b001), "Malformed SLL funct7", 1, 0, 0, 0, 0, WB_ALU, IMM_I, ALU_ADD, 0, 0, 0);
        check_instruction(encode_i(12'h403, 3'b001, OPCODE_OP_IMM), "Malformed SLLI funct7", 1, 0, 0, 1, 0, WB_ALU, IMM_I, ALU_ADD, 0, 0, 0);
        check_instruction(encode_i(12'h023, 3'b101, OPCODE_OP_IMM), "Malformed right shift funct7", 1, 0, 0, 1, 0, WB_ALU, IMM_I, ALU_ADD, 0, 0, 0);
        check_instruction(encode_i(12'h000, 3'b000, OPCODE_LOAD), "Unsupported byte load", 1, 0, 0, 0, 0, WB_ALU, IMM_I, ALU_ADD, 0, 0, 0);
        check_instruction(encode_s(12'h000, 3'b000), "Unsupported byte store", 1, 0, 0, 0, 0, WB_ALU, IMM_I, ALU_ADD, 0, 0, 0);
        check_instruction(encode_b(13'd8, 3'b010), "Reserved branch funct3", 1, 0, 0, 0, 0, WB_ALU, IMM_I, ALU_ADD, 0, 0, 0);
        check_instruction(encode_i(12'h000, 3'b001, OPCODE_JALR), "Malformed JALR funct3", 1, 0, 0, 0, 0, WB_ALU, IMM_I, ALU_ADD, 0, 0, 0);
        check_instruction(32'hffff_ffff, "Unknown opcode", 1, 0, 0, 0, 0, WB_ALU, IMM_I, ALU_ADD, 0, 0, 0);

        if (failures != 0) $fatal(1, "Control-unit test failed with %0d error(s)", failures);
        $display("PASS: control_unit_tb");
        $finish;
    end
endmodule

`default_nettype wire
