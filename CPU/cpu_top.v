`timescale 1ns / 1ps

module cpu_top(
    input wire clk,
    input wire reset
);
    // ====================================
    // Interconnect Wires
    // ====================================

    // Control signals
    wire        RegWrite;
    wire        MemToReg;
    wire        ALUSrc;
    wire [2:0]  ALUOp;
    wire        PCWrite;
    wire [1:0]  PCSrc;
    wire        IRWrite;
    wire        IorD;
    wire        MemWrite;
    wire        LoadAB;      // NEW
    wire        ALUOutWrite; // NEW

    // Datapath connections
    wire [15:0] mem_address;
    wire [7:0]  mem_write_data;
    wire [7:0]  data_mem_out;
    wire [15:0] instr_mem_out;
    wire        zero_flag;
    wire [3:0]  opcode;
    wire [2:0]  funct;

    // ====================================
    // Instruction Memory
    // ====================================
    Instruction_Memory IM (
        .addr(mem_address),
        .instruction(instr_mem_out)
    );

    // ====================================
    // Data Memory (8-bit)
    // ====================================
    Data_Memory DM (
        .clk(clk),
        .addr(mem_address),
        .write_data(mem_write_data),
        .read_data(data_mem_out),
        .mem_write(MemWrite),
        .mem_read(~MemWrite)
    );

    // ====================================
    // Datapath
    // ====================================
    Datapath DP (
        .clk(clk),
        .reset(reset),
        // Control
        .RegWrite(RegWrite),
        .MemToReg(MemToReg),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .PCWrite(PCWrite),
        .PCSrc(PCSrc),
        .IRWrite(IRWrite),
        .IorD(IorD),
        .LoadAB(LoadAB),           // NEW
        .ALUOutWrite(ALUOutWrite),  // NEW
        // Memory
        .instr_mem_out(instr_mem_out),
        .data_mem_out(data_mem_out),
        // Outputs
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .zero_flag(zero_flag),
        .opcode(opcode),
        .funct(funct)
    );

    // ====================================
    // Control Unit (FSM)
    // ====================================
    Control_Unit CU (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .funct(funct),
        .zero_flag(zero_flag),
        .RegWrite(RegWrite),
        .MemToReg(MemToReg),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .PCWrite(PCWrite),
        .PCSrc(PCSrc),
        .IRWrite(IRWrite),
        .IorD(IorD),
        .MemWrite(MemWrite),
        .LoadAB(LoadAB),           // NEW
        .ALUOutWrite(ALUOutWrite)   // NEW
    );

endmodule
