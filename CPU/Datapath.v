`timescale 1ns / 1ps

module Datapath(
    input  wire        clk,
    input  wire        reset,

    // Control signals
    input  wire        RegWrite,
    input  wire        MemToReg,
    input  wire        ALUSrc,
    input  wire [2:0]  ALUOp,
    input  wire        PCWrite,
    input  wire [1:0]  PCSrc,        // 0 = PC+1, 1 = branch target, 2 = Jump address
    input  wire        IRWrite,
    input  wire        IorD,
    input  wire        LoadAB,       // NEW: gate A/B latching
    input  wire        ALUOutWrite,  // NEW: gate ALUOut latching

    // Memory interface
    input  wire [15:0] instr_mem_out,
    input  wire [7:0]  data_mem_out,

    output wire [15:0] mem_address,
    output wire [7:0]  mem_write_data,

    // To control unit
    output wire        zero_flag,
    output wire [3:0]  opcode,
    output wire [2:0]  funct
);

    // ====================================
    //  Core Registers
    // ====================================

    reg [15:0] PC;
    reg [15:0] IR;

    reg [7:0]  A;
    reg [7:0]  B;
    reg [7:0]  ALUOut;
    reg [7:0]  MDR;
    reg        zero_flag_reg; // NEW: registered zero flag, stable through S_BRANCH

    // ====================================
    // Instruction Decode
    // ====================================

    assign opcode = IR[15:12];
    assign funct  = IR[2:0];

    wire [2:0] rd = IR[11:9];
    wire [2:0] rs = IR[8:6];
    wire [2:0] rt = IR[5:3];

    wire [5:0]  imm6       = IR[5:0];
    wire [11:0] jump_addr12 = IR[11:0];

    // 6-bit → 8-bit sign extend
    wire [7:0] imm6_ext = {{2{imm6[5]}}, imm6};

    // 6-bit → 16-bit sign extend (for branch)
    wire [15:0] imm6_ext_16 = {{10{imm6[5]}}, imm6};

    // Zero ext 12-bit to 16-bit for jump
    wire [15:0] jump_addr16 = {4'b0, jump_addr12};

    // ====================================
    //  Register File (8-bit)
    // ====================================

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

    // ====================================
    //  8-bit ALU Section
    // ====================================

    wire [7:0] ALU_inB;
    wire [7:0] ALU_result;

    assign ALU_inB = (ALUSrc == 1'b0) ? B : imm6_ext;

    wire alu_zero; // NEW: raw combinational zero from ALU

    alu alu_unit (
        .A(A),
        .B(ALU_inB),
        .ALUOp(ALUOp),
        .result(ALU_result),
        .zero(alu_zero)
    );

    // Registered zero flag — frozen at end of S_EXECUTE, stable in S_BRANCH
    assign zero_flag = zero_flag_reg;

    assign write_back_data = (MemToReg == 1'b0) ? ALUOut : MDR;
    assign mem_write_data  = B;

    // ====================================
    //  16-bit PC Adder Section
    // ====================================

    wire [15:0] PC_plus_1;
    wire [15:0] branch_target;
    wire [15:0] next_PC;

    assign PC_plus_1    = PC + 16'd1;
    assign branch_target = PC + imm6_ext_16; // (PC+1) + imm6 effectively

    assign next_PC = (PCSrc == 2'b00) ? PC_plus_1
                   : (PCSrc == 2'b01) ? branch_target
                   :                    jump_addr16;  // 2'b10 = JUMP

    // ====================================
    //  Memory Address MUX
    // ====================================

    assign mem_address = (IorD == 1'b0) ? PC : {8'b0, ALUOut};

    // ====================================
    // Sequential Logic
    // ====================================

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC           <= 16'b0;
            IR           <= 16'b0;
            A            <= 8'b0;
            B            <= 8'b0;
            ALUOut       <= 8'b0;
            MDR          <= 8'b0;
            zero_flag_reg <= 1'b0; // NEW
        end
        else begin

            // FETCH
            if (IRWrite)
                IR <= instr_mem_out;

            if (PCWrite)
                PC <= next_PC;

            // DECODE — only latch A/B when control unit permits
            if (LoadAB) begin
                A <= read_data1;
                B <= read_data2;
            end

            // EXECUTE — only latch ALUOut and zero_flag when control unit permits
            if (ALUOutWrite) begin
                ALUOut        <= ALU_result;
                zero_flag_reg <= alu_zero; // NEW: freeze zero flag here
            end

            // MEMORY READ
            MDR <= data_mem_out;
        end
    end

endmodule
