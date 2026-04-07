`timescale 1ns / 1ps

module gpu_regs(
    input  wire       clk,
    input  wire       reset,
    input  wire       mem_write,
    input  wire       mem_read,
    input  wire [7:0] addr,
    input  wire [7:0] write_data,
    output reg  [7:0] read_data,

    // FIXED: 16-bit X
    output reg  [7:0] player_x_lo,
    output reg  [7:0] player_x_hi,
    output reg  [7:0] player_y,
    output reg  [2:0] pose,
    output reg        crouch,
    output reg        game_over,

    output reg  [7:0] ufo_x,
    output reg  [7:0] ufo_y,

    output reg  [7:0] blk0_x,
    output reg  [7:0] blk0_y,
    output reg        blk0_active,

    output reg  [7:0] blk1_x,
    output reg  [7:0] blk1_y,
    output reg        blk1_active,

    output reg        hazard_enable,
    output reg        hazard_force_spawn,
    output reg        hazard_burst_enable,
    output reg        hazard_pattern_override,
    output reg  [2:0] hazard_pattern_id,

    output reg  [7:0] difficulty_level,
    output reg  [7:0] top_intensity,
    output reg  [7:0] side_intensity,
    output reg  [7:0] burst_intensity,
    output reg  [7:0] pattern_bias,
    output reg  [7:0] random_seed
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            player_x_lo <= 8'd80;
            player_x_hi <= 8'd0;
            player_y    <= 8'd220;
            pose        <= 3'd0;
            crouch      <= 1'b0;
            game_over   <= 1'b0;

            ufo_x       <= 8'd120;
            ufo_y       <= 8'd40;

            blk0_x      <= 8'd60;
            blk0_y      <= 8'd80;
            blk0_active <= 1'b0;

            blk1_x      <= 8'd140;
            blk1_y      <= 8'd80;
            blk1_active <= 1'b0;

            hazard_enable           <= 1'b1;
            hazard_force_spawn      <= 1'b0;
            hazard_burst_enable     <= 1'b1;
            hazard_pattern_override <= 1'b0;
            hazard_pattern_id       <= 3'd0;

            difficulty_level <= 8'd0;
            top_intensity    <= 8'd6;
            side_intensity   <= 8'd6;
            burst_intensity  <= 8'd6;
            pattern_bias     <= 8'd0;
            random_seed      <= 8'hA7;
        end
        else if (mem_write) begin
            case (addr)
                // ===== PLAYER =====
                8'h40: player_x_lo <= write_data;
                8'h41: player_x_hi <= write_data;
                8'h42: player_y    <= write_data;
                8'h43: pose        <= write_data[2:0];
                8'h44: crouch      <= write_data[0];
                8'h45: game_over   <= write_data[0];

                // ===== UFO =====
                8'h46: ufo_x <= write_data;
                8'h47: ufo_y <= write_data;

                // ===== BLOCKS =====
                8'h50: blk0_x      <= write_data;
                8'h51: blk0_y      <= write_data;
                8'h52: blk0_active <= write_data[0];

                8'h53: blk1_x      <= write_data;
                8'h54: blk1_y      <= write_data;
                8'h55: blk1_active <= write_data[0];

                // ===== HAZARD CONTROL =====
                8'h58: begin
                    hazard_enable           <= write_data[0];
                    hazard_force_spawn      <= write_data[1];
                    hazard_burst_enable     <= write_data[2];
                    hazard_pattern_override <= write_data[3];
                end

                8'h59: hazard_pattern_id <= write_data[2:0];

                // ===== CPU DIFFICULTY SYSTEM =====
                8'h5A: difficulty_level <= write_data;
                8'h5B: top_intensity    <= write_data;
                8'h5C: side_intensity   <= write_data;
                8'h5D: burst_intensity  <= write_data;
                8'h5E: pattern_bias     <= write_data;
                8'h5F: random_seed      <= write_data;
            endcase
        end
    end

    always @(*) begin
        read_data = 8'h00;
        if (mem_read) begin
            case (addr)
                // ===== PLAYER =====
                8'h40: read_data = player_x_lo;
                8'h41: read_data = player_x_hi;
                8'h42: read_data = player_y;
                8'h43: read_data = {5'b0, pose};
                8'h44: read_data = {7'b0, crouch};
                8'h45: read_data = {7'b0, game_over};

                // ===== UFO =====
                8'h46: read_data = ufo_x;
                8'h47: read_data = ufo_y;

                // ===== BLOCKS =====
                8'h50: read_data = blk0_x;
                8'h51: read_data = blk0_y;
                8'h52: read_data = {7'b0, blk0_active};

                8'h53: read_data = blk1_x;
                8'h54: read_data = blk1_y;
                8'h55: read_data = {7'b0, blk1_active};

                // ===== HAZARD CONTROL =====
                8'h58: read_data = {
                    4'b0000,
                    hazard_pattern_override,
                    hazard_burst_enable,
                    hazard_force_spawn,
                    hazard_enable
                };

                8'h59: read_data = {5'b0, hazard_pattern_id};

                // ===== CPU SYSTEM =====
                8'h5A: read_data = difficulty_level;
                8'h5B: read_data = top_intensity;
                8'h5C: read_data = side_intensity;
                8'h5D: read_data = burst_intensity;
                8'h5E: read_data = pattern_bias;
                8'h5F: read_data = random_seed;
            endcase
        end
    end

endmodule