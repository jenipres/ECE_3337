`timescale 1ns / 1ps

module system_mem(
    input  wire       clk,
    input  wire       reset,
    input  wire       mem_read,
    input  wire       mem_write,
    input  wire [7:0] addr,
    input  wire [7:0] write_data,
    output reg  [7:0] read_data,

    input  wire       btnL_in,
    input  wire       btnR_in,
    input  wire       btnU_in,
    input  wire       btnD_in,
    input  wire       btnC_in,
    input  wire       btnA_in,
    input  wire       btnB_in,
    input  wire       btnStart_in,
    input  wire       btnX_in,

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

    reg [7:0] ram [0:63];
    reg [7:0] ram_read_data;

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 64; i = i + 1)
                ram[i] <= 8'h00;
        end
        else if (mem_write && (addr <= 8'h3F)) begin
            ram[addr] <= write_data;
        end
    end

    always @(*) begin
        if (mem_read && (addr <= 8'h3F))
            ram_read_data = ram[addr];
        else
            ram_read_data = 8'h00;
    end

    wire [7:0] gpu_read_data;

    gpu_regs u_gpu_regs (
        .clk(clk),
        .reset(reset),
        .mem_write(mem_write && (addr >= 8'h40) && (addr <= 8'h5F)),
        .mem_read (mem_read  && (addr >= 8'h40) && (addr <= 8'h5F)),
        .addr(addr),
        .write_data(write_data),
        .read_data(gpu_read_data),

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

    wire [7:0] input_read_data_0;
    wire [7:0] input_read_data_1;

    assign input_read_data_0 = {
        btnStart_in,
        btnB_in,
        btnA_in,
        btnC_in,
        btnD_in,
        btnU_in,
        btnR_in,
        btnL_in
    };

    assign input_read_data_1 = {
        7'b0000000,
        btnX_in
    };

    always @(*) begin
        if (mem_read && (addr <= 8'h3F))
            read_data = ram_read_data;
        else if (mem_read && (addr >= 8'h40) && (addr <= 8'h5F))
            read_data = gpu_read_data;
        else if (mem_read && (addr == 8'h60))
            read_data = input_read_data_0;
        else if (mem_read && (addr == 8'h61))
            read_data = input_read_data_1;
        else
            read_data = 8'h00;
    end

endmodule