`timescale 1ns / 1ps

module Datapath2(
    input  wire        clk,
    input  wire        reset,

    input  wire        RegWrite,
    input  wire        MemToReg,
    input  wire        ALUSrc,
    input  wire [2:0]  ALUOp,
    input  wire        PCWrite,
    input  wire [1:0]  PCSrc,
    input  wire        IRWrite,
    input  wire        IorD,
    input  wire        LoadAB,
    input  wire        ALUOutWrite,

    input  wire [15:0] instr_mem_out,
    input  wire [7:0]  data_mem_out,

    output wire [15:0] mem_address,
    output wire [7:0]  mem_write_data,

    output wire        zero_flag,
    output wire [3:0]  opcode,
    output wire [2:0]  funct
);

    reg [15:0] PC;
    reg [15:0] IR;

    reg [7:0]  A;
    reg [7:0]  B;
    reg [7:0]  ALUOut;
    reg [7:0]  MDR;
    reg        zero_flag_reg;

    assign opcode = IR[15:12];
    assign funct  = IR[2:0];

    wire [2:0] rd = IR[11:9];
    wire [2:0] rs = IR[8:6];
    wire [2:0] rt = IR[5:3];

    wire [5:0]  imm6        = IR[5:0];
    wire [11:0] jump_addr12 = IR[11:0];

    wire [7:0]  imm6_ext    = {{2{imm6[5]}}, imm6};
    wire [15:0] imm6_ext_16 = {{10{imm6[5]}}, imm6};
    wire [15:0] jump_addr16 = {4'b0, jump_addr12};

    wire [7:0] read_data1;
    wire [7:0] read_data2;
    wire [7:0] write_back_data;

    wire isSTORE  = (opcode == 4'b0011);
    wire isBRANCH = (opcode == 4'b0100) || (opcode == 4'b0101);
    wire [2:0] read_reg2_sel = (isSTORE || isBRANCH) ? rd : rt;

    Register_File RF (
        .clk(clk),
        .reset(reset),
        .RegWrite(RegWrite),
        .read_reg1(rs),
        .read_reg2(read_reg2_sel),
        .write_reg(rd),
        .write_data(write_back_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    wire [7:0] ALU_inB;
    wire [7:0] ALU_result;
    wire       alu_zero;

    assign ALU_inB = (ALUSrc == 1'b0) ? B : imm6_ext;

    alu alu_unit (
        .A(A),
        .B(ALU_inB),
        .ALUOp(ALUOp),
        .result(ALU_result),
        .zero(alu_zero)
    );

    assign zero_flag       = zero_flag_reg;
    assign write_back_data = (MemToReg == 1'b0) ? ALUOut : MDR;
    assign mem_write_data  = B;

    wire [15:0] PC_plus_1;
    wire [15:0] branch_target;
    wire [15:0] next_PC;

    assign PC_plus_1     = PC + 16'd1;

    // ✅ FIXED: correct branch target
    assign branch_target = PC + imm6_ext_16;

    assign next_PC = (PCSrc == 2'b00) ? PC_plus_1   :
                     (PCSrc == 2'b01) ? branch_target :
                                         jump_addr16;

    assign mem_address = (IorD == 1'b0) ? PC : {8'b0, ALUOut};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC            <= 16'b0;
            IR            <= 16'b0;
            A             <= 8'b0;
            B             <= 8'b0;
            ALUOut        <= 8'b0;
            MDR           <= 8'b0;
            zero_flag_reg <= 1'b0;
        end
        else begin
            if (IRWrite)
                IR <= instr_mem_out;

            if (PCWrite)
                PC <= next_PC;

            if (LoadAB) begin
                A <= read_data1;
                B <= read_data2;
            end

            if (ALUOutWrite) begin
                ALUOut        <= ALU_result;
                zero_flag_reg <= alu_zero;
            end

            // ✅ FIXED: only load MDR during memory phase
            if (IorD)
                MDR <= data_mem_out;
        end
    end

endmodule