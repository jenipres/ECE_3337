`timescale 1ns / 1ps

module cpu_top(
    input wire clk,
    input wire reset,

    input wire btnL,
    input wire btnR,
    input wire btnU,
    input wire btnD,
    input wire btnC,

    input wire btnA,
    input wire btnB,
    input wire btnStart,
    input wire btnX,

    output wire [7:0] player_x_lo,
    output wire [7:0] player_x_hi,
    output wire [7:0] player_y,
    output wire [2:0] pose,
    output wire       crouch,
    output wire       game_over,

    output wire [7:0] ufo_x,
    output wire [7:0] ufo_y,

    output wire [7:0] blk0_x,
    output wire [7:0] blk0_y,
    output wire       blk0_active,

    output wire [7:0] blk1_x,
    output wire [7:0] blk1_y,
    output wire       blk1_active,

    output wire       hazard_enable,
    output wire       hazard_force_spawn,
    output wire       hazard_burst_enable,
    output wire       hazard_pattern_override,
    output wire [2:0] hazard_pattern_id,

    output wire [7:0] difficulty_level,
    output wire [7:0] top_intensity,
    output wire [7:0] side_intensity,
    output wire [7:0] burst_intensity,
    output wire [7:0] pattern_bias,
    output wire [7:0] random_seed
);

    wire        RegWrite;
    wire        MemToReg;
    wire        ALUSrc;
    wire [2:0]  ALUOp;
    wire        PCWrite;
    wire [1:0]  PCSrc;
    wire        IRWrite;
    wire        IorD;
    wire        MemWrite;
    wire        LoadAB;
    wire        ALUOutWrite;

    wire [15:0] mem_address;
    wire [7:0]  mem_write_data;
    wire [7:0]  data_mem_out;
    wire [15:0] instr_mem_out;
    wire        zero_flag;
    wire [3:0]  opcode;
    wire [2:0]  funct;

    wire mem_read;
    assign mem_read = ~MemWrite;

    Instruction_Memory IM (
        .addr(mem_address),
        .instruction(instr_mem_out)
    );

    system_mem SM (
        .clk(clk),
        .reset(reset),
        .mem_read(mem_read),
        .mem_write(MemWrite),
        .addr(mem_address[7:0]),
        .write_data(mem_write_data),
        .read_data(data_mem_out),

        .btnL_in(btnL),
        .btnR_in(btnR),
        .btnU_in(btnU),
        .btnD_in(btnD),
        .btnC_in(btnC),
        .btnA_in(btnA),
        .btnB_in(btnB),
        .btnStart_in(btnStart),
        .btnX_in(btnX),

        .player_x_lo(player_x_lo),
        .player_x_hi(player_x_hi),
        .player_y(player_y),
        .pose(pose),
        .crouch(crouch),
        .game_over(game_over),

        .ufo_x(ufo_x),
        .ufo_y(ufo_y),

        .blk0_x(blk0_x),
        .blk0_y(blk0_y),
        .blk0_active(blk0_active),

        .blk1_x(blk1_x),
        .blk1_y(blk1_y),
        .blk1_active(blk1_active),

        .hazard_enable(hazard_enable),
        .hazard_force_spawn(hazard_force_spawn),
        .hazard_burst_enable(hazard_burst_enable),
        .hazard_pattern_override(hazard_pattern_override),
        .hazard_pattern_id(hazard_pattern_id),

        .difficulty_level(difficulty_level),
        .top_intensity(top_intensity),
        .side_intensity(side_intensity),
        .burst_intensity(burst_intensity),
        .pattern_bias(pattern_bias),
        .random_seed(random_seed)
    );

    Datapath2 DP (
        .clk(clk),
        .reset(reset),

        .RegWrite(RegWrite),
        .MemToReg(MemToReg),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .PCWrite(PCWrite),
        .PCSrc(PCSrc),
        .IRWrite(IRWrite),
        .IorD(IorD),
        .LoadAB(LoadAB),
        .ALUOutWrite(ALUOutWrite),

        .instr_mem_out(instr_mem_out),
        .data_mem_out(data_mem_out),

        .mem_address(mem_address),
        .mem_write_data(mem_write_data),

        .zero_flag(zero_flag),
        .opcode(opcode),
        .funct(funct)
    );

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
        .LoadAB(LoadAB),
        .ALUOutWrite(ALUOutWrite)
    );

endmodule