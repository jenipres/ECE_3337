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
    input  wire        PCSrc,        // 0 = PC+1, 1 = branch target
    input  wire        IRWrite,
    input  wire        IorD,

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

    // ====================================
    // Instruction Decode
    // ====================================

    assign opcode = IR[15:12];
    assign funct =  IR[2:0]; //NEW, funct bits

    wire [2:0] rd = IR[11:9];
    wire [2:0] rs = IR[8:6];
    wire [2:0] rt = IR[5:3];

    wire [5:0] imm6 = IR[5:0];

    // 6-bit → 8-bit sign extend
    wire [7:0] imm6_ext = {{2{imm6[5]}}, imm6};

    // 6-bit → 16-bit sign extend (for branch) 
    wire [15:0] imm6_ext_16 = {{10{imm6[5]}}, imm6};

    // ====================================
    //  Register File (8-bit)
    // ====================================

    wire [7:0] read_data1;
    wire [7:0] read_data2;
    wire [7:0] write_back_data;
    
    wire isSTORE = (opcode == 4'b0011); //updated, isSTORE opcode specifically
    wire [2:0] read_reg2_sel = isSTORE ? rd : rt;

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

    assign ALU_inB = (ALUSrc == 1'b0) ? B : imm6_ext; //ALU B mux

    alu alu_unit (
        .A(A),
        .B(ALU_inB),
        .ALUOp(ALUOp),
        .result(ALU_result),
        .zero(zero_flag)
    );

    assign write_back_data = (MemToReg == 1'b0) ? ALUOut
                                                : MDR;

    assign mem_write_data = B; //IMPORTANT LINE

    // ====================================
    //  16-bit PC Adder Section (NEW)
    // ====================================

    wire [15:0] PC_plus_1;
    wire [15:0] branch_target;
    wire [15:0] next_PC;

    assign PC_plus_1     = PC + 16'd1;
    assign branch_target = PC + imm6_ext_16; //NEEDS UPDATE

    assign next_PC = (PCSrc == 1'b0) ? PC_plus_1
                                     : branch_target;

    // ====================================
    //  Memory Address MUX
    // ====================================

    // Instruction fetch uses PC
    // Data memory uses ALUOut (zero extended)

    assign mem_address = (IorD == 1'b0)
                       ? PC
                       : {8'b0, ALUOut};

    // ====================================
    // Sequential Logic
    // ====================================

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC     <= 16'b0;
            IR     <= 16'b0;
            A      <= 8'b0;
            B      <= 8'b0;
            ALUOut <= 8'b0;
            MDR    <= 8'b0;
        end
        else begin

            // FETCH
            if (IRWrite)
                IR <= instr_mem_out;

            if (PCWrite)
                PC <= next_PC;

            // DECODE
            A <= read_data1;
            B <= read_data2;

            // EXECUTE
            ALUOut <= ALU_result;

            // MEMORY READ
            MDR <= data_mem_out;
        end
    end

endmodule
