`default_nettype none

module rv32i_datapath #(
    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000
) (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instruction,
    output logic [31:0] instruction_address,
    input  logic [31:0] data_rdata,
    output logic [31:0] data_address,
    output logic [31:0] data_wdata,
    output logic        data_write_enable,
    output logic        illegal_instruction,
    output logic [31:0] debug_writeback_data,
    output logic [4:0]  debug_writeback_rd,
    output logic        debug_writeback_enable
);
    localparam logic [2:0] IMM_I = 3'd0;
    localparam logic [2:0] IMM_S = 3'd1;
    localparam logic [2:0] IMM_B = 3'd2;
    localparam logic [2:0] IMM_U = 3'd3;
    localparam logic [2:0] IMM_J = 3'd4;

    localparam logic [1:0] WB_ALU = 2'd0;
    localparam logic [1:0] WB_MEM = 2'd1;
    localparam logic [1:0] WB_PC4 = 2'd2;

    logic [31:0] current_pc;
    logic [31:0] next_pc;
    logic [31:0] pc_plus_four;
    logic [31:0] immediate;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] alu_operand_a;
    logic [31:0] alu_operand_b;
    logic [31:0] alu_result;
    logic [31:0] writeback_data;

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
    logic        branch_condition;
    logic        alu_zero;

    rv32i_pc #(
        .RESET_VECTOR(RESET_VECTOR)
    ) program_counter (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .current_pc(current_pc)
    );

    rv32i_control_unit control_unit (
        .instruction(instruction),
        .register_write(register_write),
        .memory_write(memory_write),
        .alu_source_immediate(alu_source_immediate),
        .alu_source_pc(alu_source_pc),
        .writeback_select(writeback_select),
        .immediate_select(immediate_select),
        .alu_operation(alu_operation),
        .branch(branch),
        .jump(jump),
        .jump_register(jump_register),
        .illegal_instruction(illegal_instruction)
    );

    rv32i_register_file register_file (
        .clk(clk),
        .rs1_address(instruction[19:15]),
        .rs2_address(instruction[24:20]),
        .rd_address(instruction[11:7]),
        .write_data(writeback_data),
        .write_enable(register_write && !illegal_instruction && !reset),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    rv32i_alu alu (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .operation(alu_operation),
        .result(alu_result),
        .zero(alu_zero)
    );

    always_comb begin
        case (immediate_select)
            IMM_I: immediate = {{20{instruction[31]}}, instruction[31:20]};
            IMM_S: immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            IMM_B: immediate = {{19{instruction[31]}}, instruction[31], instruction[7],
                                instruction[30:25], instruction[11:8], 1'b0};
            IMM_U: immediate = {instruction[31:12], 12'b0};
            IMM_J: immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                                instruction[20], instruction[30:21], 1'b0};
            default: immediate = 32'b0;
        endcase
    end

    always_comb begin
        case (instruction[14:12])
            3'b000: branch_condition = alu_zero;
            3'b001: branch_condition = !alu_zero;
            3'b100: branch_condition = ($signed(rs1_data) < $signed(rs2_data));
            3'b101: branch_condition = ($signed(rs1_data) >= $signed(rs2_data));
            3'b110: branch_condition = (rs1_data < rs2_data);
            3'b111: branch_condition = (rs1_data >= rs2_data);
            default: branch_condition = 1'b0;
        endcase
    end

    always_comb begin
        pc_plus_four = current_pc + 32'd4;
        next_pc = pc_plus_four;

        if (jump) begin
            if (jump_register) begin
                next_pc = (rs1_data + immediate) & 32'hffff_fffe;
            end else begin
                next_pc = current_pc + immediate;
            end
        end else if (branch && branch_condition) begin
            next_pc = current_pc + immediate;
        end
    end

    always_comb begin
        case (writeback_select)
            WB_ALU: writeback_data = alu_result;
            WB_MEM: writeback_data = data_rdata;
            WB_PC4: writeback_data = pc_plus_four;
            default: writeback_data = 32'b0;
        endcase
    end

    assign instruction_address = current_pc;
    assign alu_operand_a = alu_source_pc ? current_pc : rs1_data;
    assign alu_operand_b = alu_source_immediate ? immediate : rs2_data;
    assign data_address = alu_result;
    assign data_wdata = rs2_data;
    assign data_write_enable = memory_write && !illegal_instruction && !reset;

    assign debug_writeback_data = writeback_data;
    assign debug_writeback_rd = instruction[11:7];
    assign debug_writeback_enable = register_write && !illegal_instruction && !reset;
endmodule

`default_nettype wire
