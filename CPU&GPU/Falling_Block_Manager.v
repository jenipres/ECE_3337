`timescale 1ns / 1ps

module Falling_Block_Manager(
    input  wire       clk,
    input  wire       rst,
    input  wire       game_tick,

    input  wire [9:0] ufo_x,
    input  wire [9:0] ufo_y,

    input  wire       hazard_enable,
    input  wire       hazard_force_spawn_pulse,
    input  wire       hazard_burst_enable,
    input  wire       hazard_pattern_override,
    input  wire [2:0] hazard_pattern_id,
    input  wire       drop_pulse,

    output reg        blk0_active,
    output reg [9:0]  blk0_x,
    output reg [9:0]  blk0_y,

    output reg        blk1_active,
    output reg [9:0]  blk1_x,
    output reg [9:0]  blk1_y,

    output reg        blk2_active,
    output reg [9:0]  blk2_x,
    output reg [9:0]  blk2_y,

    output reg        blk3_active,
    output reg [9:0]  blk3_x,
    output reg [9:0]  blk3_y,

    output reg        blk4_active,
    output reg [9:0]  blk4_x,
    output reg [9:0]  blk4_y,

    output reg        blk5_active,
    output reg [9:0]  blk5_x,
    output reg [9:0]  blk5_y,

    output reg        blk6_active,
    output reg [9:0]  blk6_x,
    output reg [9:0]  blk6_y,

    output reg        blk7_active,
    output reg [9:0]  blk7_x,
    output reg [9:0]  blk7_y,

    output reg        blk8_active,
    output reg [9:0]  blk8_x,
    output reg [9:0]  blk8_y,

    output reg        blk9_active,
    output reg [9:0]  blk9_x,
    output reg [9:0]  blk9_y,

    output reg        blk10_active,
    output reg [9:0]  blk10_x,
    output reg [9:0]  blk10_y,

    output reg        blk11_active,
    output reg [9:0]  blk11_x,
    output reg [9:0]  blk11_y,

    output reg        blk12_active,
    output reg [9:0]  blk12_x,
    output reg [9:0]  blk12_y,

    output reg        blk13_active,
    output reg [9:0]  blk13_x,
    output reg [9:0]  blk13_y,

    output reg        blk14_active,
    output reg [9:0]  blk14_x,
    output reg [9:0]  blk14_y,

    output reg        blk15_active,
    output reg [9:0]  blk15_x,
    output reg [9:0]  blk15_y
);

    localparam [9:0] SCREEN_H    = 10'd480;
    localparam [9:0] START_Y_OFF = 10'd20;

    reg [9:0] blk0_vy,  blk1_vy,  blk2_vy,  blk3_vy;
    reg [9:0] blk4_vy,  blk5_vy,  blk6_vy,  blk7_vy;
    reg [9:0] blk8_vy,  blk9_vy,  blk10_vy, blk11_vy;
    reg [9:0] blk12_vy, blk13_vy, blk14_vy, blk15_vy;

    reg [7:0] lfsr;
    wire lfsr_feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    reg [5:0] spawn_timer;
    reg [1:0] burst_left;

    reg [2:0] pattern_id;
    reg [1:0] pattern_step;
    reg [1:0] pattern_len;

    wire [2:0] active_pattern_id;
    assign active_pattern_id = hazard_pattern_override ? hazard_pattern_id : pattern_id;

    function [9:0] clamp_x;
        input signed [10:0] x_in;
        begin
            if (x_in < 0)
                clamp_x = 10'd0;
            else if (x_in > 11'sd639)
                clamp_x = 10'd639;
            else
                clamp_x = x_in[9:0];
        end
    endfunction

    // lane selector:
    // 00 = far left
    // 01 = left
    // 10 = right
    // 11 = far right
    function [9:0] lane_to_x;
        input [1:0] lane;
        input [9:0] ufox;
        begin
            case (lane)
                2'b00: lane_to_x = clamp_x($signed({1'b0, ufox}) - 11'sd48);
                2'b01: lane_to_x = clamp_x($signed({1'b0, ufox}) - 11'sd16);
                2'b10: lane_to_x = clamp_x($signed({1'b0, ufox}) + 11'sd16);
                default: lane_to_x = clamp_x($signed({1'b0, ufox}) + 11'sd48);
            endcase
        end
    endfunction

    function [9:0] pick_speed;
        input [1:0] sel;
        begin
            case (sel)
                2'b00: pick_speed = 10'd5;
                2'b01: pick_speed = 10'd6;
                2'b10: pick_speed = 10'd7;
                default: pick_speed = 10'd8;
            endcase
        end
    endfunction

    function [5:0] pick_spawn_delay;
        input [2:0] sel;
        begin
            case (sel)
                3'b000: pick_spawn_delay = 6'd3;
                3'b001: pick_spawn_delay = 6'd4;
                3'b010: pick_spawn_delay = 6'd5;
                3'b011: pick_spawn_delay = 6'd6;
                3'b100: pick_spawn_delay = 6'd8;
                3'b101: pick_spawn_delay = 6'd10;
                3'b110: pick_spawn_delay = 6'd12;
                default: pick_spawn_delay = 6'd14;
            endcase
        end
    endfunction

    // choose lane from current pattern + step
    function [1:0] pattern_lane;
        input [2:0] pid;
        input [1:0] pstep;
        begin
            case (pid)
                // Pattern 0: far left -> left -> right -> far right
                3'd0: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b00;
                        2'd1: pattern_lane = 2'b01;
                        2'd2: pattern_lane = 2'b10;
                        default: pattern_lane = 2'b11;
                    endcase
                end

                // Pattern 1: far right -> right -> left -> far left
                3'd1: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b11;
                        2'd1: pattern_lane = 2'b10;
                        2'd2: pattern_lane = 2'b01;
                        default: pattern_lane = 2'b00;
                    endcase
                end

                // Pattern 2: center-heavy
                3'd2: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b01;
                        2'd1: pattern_lane = 2'b10;
                        2'd2: pattern_lane = 2'b01;
                        default: pattern_lane = 2'b10;
                    endcase
                end

                // Pattern 3: outer edges
                3'd3: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b00;
                        2'd1: pattern_lane = 2'b11;
                        2'd2: pattern_lane = 2'b00;
                        default: pattern_lane = 2'b11;
                    endcase
                end

                // Pattern 4: zig-zag
                3'd4: begin
                    case (pstep)
                        2'd0: pattern_lane = 2'b00;
                        2'd1: pattern_lane = 2'b10;
                        2'd2: pattern_lane = 2'b01;
                        default: pattern_lane = 2'b11;
                    endcase
                end

                default: pattern_lane = 2'b01;
            endcase
        end
    endfunction

    // small random x jitter around chosen lane, centered on UFO-based lane
    function [9:0] spawn_x_with_jitter;
        input [1:0] lane;
        input [9:0] ufox;
        input [2:0] jitter_bits;
        reg signed [10:0] base_x;
        reg signed [10:0] jitter;
        begin
            base_x = $signed({1'b0, lane_to_x(lane, ufox)});
            jitter = $signed({8'b0, jitter_bits}) - 11'sd4; // -4 .. +3
            spawn_x_with_jitter = clamp_x(base_x + jitter);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            blk0_active  <= 1'b0; blk0_x  <= 10'd0; blk0_y  <= 10'd0; blk0_vy  <= 10'd5;
            blk1_active  <= 1'b0; blk1_x  <= 10'd0; blk1_y  <= 10'd0; blk1_vy  <= 10'd5;
            blk2_active  <= 1'b0; blk2_x  <= 10'd0; blk2_y  <= 10'd0; blk2_vy  <= 10'd5;
            blk3_active  <= 1'b0; blk3_x  <= 10'd0; blk3_y  <= 10'd0; blk3_vy  <= 10'd5;
            blk4_active  <= 1'b0; blk4_x  <= 10'd0; blk4_y  <= 10'd0; blk4_vy  <= 10'd5;
            blk5_active  <= 1'b0; blk5_x  <= 10'd0; blk5_y  <= 10'd0; blk5_vy  <= 10'd5;
            blk6_active  <= 1'b0; blk6_x  <= 10'd0; blk6_y  <= 10'd0; blk6_vy  <= 10'd5;
            blk7_active  <= 1'b0; blk7_x  <= 10'd0; blk7_y  <= 10'd0; blk7_vy  <= 10'd5;
            blk8_active  <= 1'b0; blk8_x  <= 10'd0; blk8_y  <= 10'd0; blk8_vy  <= 10'd5;
            blk9_active  <= 1'b0; blk9_x  <= 10'd0; blk9_y  <= 10'd0; blk9_vy  <= 10'd5;
            blk10_active <= 1'b0; blk10_x <= 10'd0; blk10_y <= 10'd0; blk10_vy <= 10'd5;
            blk11_active <= 1'b0; blk11_x <= 10'd0; blk11_y <= 10'd0; blk11_vy <= 10'd5;
            blk12_active <= 1'b0; blk12_x <= 10'd0; blk12_y <= 10'd0; blk12_vy <= 10'd5;
            blk13_active <= 1'b0; blk13_x <= 10'd0; blk13_y <= 10'd0; blk13_vy <= 10'd5;
            blk14_active <= 1'b0; blk14_x <= 10'd0; blk14_y <= 10'd0; blk14_vy <= 10'd5;
            blk15_active <= 1'b0; blk15_x <= 10'd0; blk15_y <= 10'd0; blk15_vy <= 10'd5;

            lfsr        <= 8'hA7;
            spawn_timer <= 6'd8;
            burst_left  <= 2'd0;

            pattern_id   <= 3'd0;
            pattern_step <= 2'd0;
            pattern_len  <= 2'd3;
        end
        else if (game_tick) begin
            lfsr <= {lfsr[6:0], lfsr_feedback};

            // move active blocks
            if (blk0_active) begin
                if (blk0_y >= (SCREEN_H - blk0_vy)) blk0_active <= 1'b0;
                else blk0_y <= blk0_y + blk0_vy;
            end

            if (blk1_active) begin
                if (blk1_y >= (SCREEN_H - blk1_vy)) blk1_active <= 1'b0;
                else blk1_y <= blk1_y + blk1_vy;
            end

            if (blk2_active) begin
                if (blk2_y >= (SCREEN_H - blk2_vy)) blk2_active <= 1'b0;
                else blk2_y <= blk2_y + blk2_vy;
            end

            if (blk3_active) begin
                if (blk3_y >= (SCREEN_H - blk3_vy)) blk3_active <= 1'b0;
                else blk3_y <= blk3_y + blk3_vy;
            end

            if (blk4_active) begin
                if (blk4_y >= (SCREEN_H - blk4_vy)) blk4_active <= 1'b0;
                else blk4_y <= blk4_y + blk4_vy;
            end

            if (blk5_active) begin
                if (blk5_y >= (SCREEN_H - blk5_vy)) blk5_active <= 1'b0;
                else blk5_y <= blk5_y + blk5_vy;
            end

            if (blk6_active) begin
                if (blk6_y >= (SCREEN_H - blk6_vy)) blk6_active <= 1'b0;
                else blk6_y <= blk6_y + blk6_vy;
            end

            if (blk7_active) begin
                if (blk7_y >= (SCREEN_H - blk7_vy)) blk7_active <= 1'b0;
                else blk7_y <= blk7_y + blk7_vy;
            end

            if (blk8_active) begin
                if (blk8_y >= (SCREEN_H - blk8_vy)) blk8_active <= 1'b0;
                else blk8_y <= blk8_y + blk8_vy;
            end

            if (blk9_active) begin
                if (blk9_y >= (SCREEN_H - blk9_vy)) blk9_active <= 1'b0;
                else blk9_y <= blk9_y + blk9_vy;
            end

            if (blk10_active) begin
                if (blk10_y >= (SCREEN_H - blk10_vy)) blk10_active <= 1'b0;
                else blk10_y <= blk10_y + blk10_vy;
            end

            if (blk11_active) begin
                if (blk11_y >= (SCREEN_H - blk11_vy)) blk11_active <= 1'b0;
                else blk11_y <= blk11_y + blk11_vy;
            end

            if (blk12_active) begin
                if (blk12_y >= (SCREEN_H - blk12_vy)) blk12_active <= 1'b0;
                else blk12_y <= blk12_y + blk12_vy;
            end

            if (blk13_active) begin
                if (blk13_y >= (SCREEN_H - blk13_vy)) blk13_active <= 1'b0;
                else blk13_y <= blk13_y + blk13_vy;
            end

            if (blk14_active) begin
                if (blk14_y >= (SCREEN_H - blk14_vy)) blk14_active <= 1'b0;
                else blk14_y <= blk14_y + blk14_vy;
            end

            if (blk15_active) begin
                if (blk15_y >= (SCREEN_H - blk15_vy)) blk15_active <= 1'b0;
                else blk15_y <= blk15_y + blk15_vy;
            end

            if (!hazard_enable) begin
                // spawning paused, active bullets still move
            end
            else if (spawn_timer != 0 && !hazard_force_spawn_pulse) begin
                spawn_timer <= spawn_timer - 1'b1;
            end
            else begin
                // spawn using current pattern lane into first free slot
                if (!blk0_active) begin
                    blk0_active <= 1'b1;
                    blk0_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, lfsr[2:0]);
                    blk0_y      <= ufo_y + START_Y_OFF;
                    blk0_vy     <= pick_speed(lfsr[1:0]);
                end
                else if (!blk1_active) begin
                    blk1_active <= 1'b1;
                    blk1_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, lfsr[4:2]);
                    blk1_y      <= ufo_y + START_Y_OFF;
                    blk1_vy     <= pick_speed(lfsr[3:2]);
                end
                else if (!blk2_active) begin
                    blk2_active <= 1'b1;
                    blk2_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, lfsr[6:4]);
                    blk2_y      <= ufo_y + START_Y_OFF;
                    blk2_vy     <= pick_speed(lfsr[5:4]);
                end
                else if (!blk3_active) begin
                    blk3_active <= 1'b1;
                    blk3_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[7], lfsr[1:0]});
                    blk3_y      <= ufo_y + START_Y_OFF;
                    blk3_vy     <= pick_speed(lfsr[7:6]);
                end
                else if (!blk4_active) begin
                    blk4_active <= 1'b1;
                    blk4_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[0], lfsr[7:6]});
                    blk4_y      <= ufo_y + START_Y_OFF;
                    blk4_vy     <= pick_speed({lfsr[0], lfsr[7]});
                end
                else if (!blk5_active) begin
                    blk5_active <= 1'b1;
                    blk5_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[2], lfsr[5:4]});
                    blk5_y      <= ufo_y + START_Y_OFF;
                    blk5_vy     <= pick_speed({lfsr[2], lfsr[1]});
                end
                else if (!blk6_active) begin
                    blk6_active <= 1'b1;
                    blk6_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[4], lfsr[3:2]});
                    blk6_y      <= ufo_y + START_Y_OFF;
                    blk6_vy     <= pick_speed({lfsr[4], lfsr[3]});
                end
                else if (!blk7_active) begin
                    blk7_active <= 1'b1;
                    blk7_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[6], lfsr[5:4]});
                    blk7_y      <= ufo_y + START_Y_OFF;
                    blk7_vy     <= pick_speed({lfsr[6], lfsr[5]});
                end
                else if (!blk8_active) begin
                    blk8_active <= 1'b1;
                    blk8_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, lfsr[2:0]);
                    blk8_y      <= ufo_y + START_Y_OFF;
                    blk8_vy     <= pick_speed(lfsr[1:0]);
                end
                else if (!blk9_active) begin
                    blk9_active <= 1'b1;
                    blk9_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, lfsr[4:2]);
                    blk9_y      <= ufo_y + START_Y_OFF;
                    blk9_vy     <= pick_speed(lfsr[3:2]);
                end
                else if (!blk10_active) begin
                    blk10_active <= 1'b1;
                    blk10_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, lfsr[6:4]);
                    blk10_y      <= ufo_y + START_Y_OFF;
                    blk10_vy     <= pick_speed(lfsr[5:4]);
                end
                else if (!blk11_active) begin
                    blk11_active <= 1'b1;
                    blk11_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[7], lfsr[1:0]});
                    blk11_y      <= ufo_y + START_Y_OFF;
                    blk11_vy     <= pick_speed(lfsr[7:6]);
                end
                else if (!blk12_active) begin
                    blk12_active <= 1'b1;
                    blk12_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[0], lfsr[7:6]});
                    blk12_y      <= ufo_y + START_Y_OFF;
                    blk12_vy     <= pick_speed({lfsr[0], lfsr[7]});
                end
                else if (!blk13_active) begin
                    blk13_active <= 1'b1;
                    blk13_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[2], lfsr[5:4]});
                    blk13_y      <= ufo_y + START_Y_OFF;
                    blk13_vy     <= pick_speed({lfsr[2], lfsr[1]});
                end
                else if (!blk14_active) begin
                    blk14_active <= 1'b1;
                    blk14_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[4], lfsr[3:2]});
                    blk14_y      <= ufo_y + START_Y_OFF;
                    blk14_vy     <= pick_speed({lfsr[4], lfsr[3]});
                end
                else if (!blk15_active) begin
                    blk15_active <= 1'b1;
                    blk15_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step), ufo_x, {lfsr[6], lfsr[5:4]});
                    blk15_y      <= ufo_y + START_Y_OFF;
                    blk15_vy     <= pick_speed({lfsr[6], lfsr[5]});
                end

                // extra carpet-bomb spawn in same cycle if burst mode is enabled
                if (hazard_burst_enable && (burst_left != 0)) begin
                    if (!blk0_active) begin
                        blk0_active <= 1'b1;
                        blk0_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, lfsr[4:2]);
                        blk0_y      <= ufo_y + START_Y_OFF;
                        blk0_vy     <= pick_speed(lfsr[3:2]);
                    end
                    else if (!blk1_active) begin
                        blk1_active <= 1'b1;
                        blk1_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, lfsr[6:4]);
                        blk1_y      <= ufo_y + START_Y_OFF;
                        blk1_vy     <= pick_speed(lfsr[5:4]);
                    end
                    else if (!blk2_active) begin
                        blk2_active <= 1'b1;
                        blk2_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[7], lfsr[1:0]});
                        blk2_y      <= ufo_y + START_Y_OFF;
                        blk2_vy     <= pick_speed(lfsr[7:6]);
                    end
                    else if (!blk3_active) begin
                        blk3_active <= 1'b1;
                        blk3_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[0], lfsr[7:6]});
                        blk3_y      <= ufo_y + START_Y_OFF;
                        blk3_vy     <= pick_speed({lfsr[0], lfsr[7]});
                    end
                    else if (!blk4_active) begin
                        blk4_active <= 1'b1;
                        blk4_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[2], lfsr[5:4]});
                        blk4_y      <= ufo_y + START_Y_OFF;
                        blk4_vy     <= pick_speed({lfsr[2], lfsr[1]});
                    end
                    else if (!blk5_active) begin
                        blk5_active <= 1'b1;
                        blk5_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[4], lfsr[3:2]});
                        blk5_y      <= ufo_y + START_Y_OFF;
                        blk5_vy     <= pick_speed({lfsr[4], lfsr[3]});
                    end
                    else if (!blk6_active) begin
                        blk6_active <= 1'b1;
                        blk6_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[6], lfsr[5:4]});
                        blk6_y      <= ufo_y + START_Y_OFF;
                        blk6_vy     <= pick_speed({lfsr[6], lfsr[5]});
                    end
                    else if (!blk7_active) begin
                        blk7_active <= 1'b1;
                        blk7_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, lfsr[1:0]);
                        blk7_y      <= ufo_y + START_Y_OFF;
                        blk7_vy     <= pick_speed(lfsr[1:0]);
                    end
                    else if (!blk8_active) begin
                        blk8_active <= 1'b1;
                        blk8_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, lfsr[4:2]);
                        blk8_y      <= ufo_y + START_Y_OFF;
                        blk8_vy     <= pick_speed(lfsr[3:2]);
                    end
                    else if (!blk9_active) begin
                        blk9_active <= 1'b1;
                        blk9_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, lfsr[6:4]);
                        blk9_y      <= ufo_y + START_Y_OFF;
                        blk9_vy     <= pick_speed(lfsr[5:4]);
                    end
                    else if (!blk10_active) begin
                        blk10_active <= 1'b1;
                        blk10_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[7], lfsr[1:0]});
                        blk10_y      <= ufo_y + START_Y_OFF;
                        blk10_vy     <= pick_speed(lfsr[7:6]);
                    end
                    else if (!blk11_active) begin
                        blk11_active <= 1'b1;
                        blk11_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[0], lfsr[7:6]});
                        blk11_y      <= ufo_y + START_Y_OFF;
                        blk11_vy     <= pick_speed({lfsr[0], lfsr[7]});
                    end
                    else if (!blk12_active) begin
                        blk12_active <= 1'b1;
                        blk12_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[2], lfsr[5:4]});
                        blk12_y      <= ufo_y + START_Y_OFF;
                        blk12_vy     <= pick_speed({lfsr[2], lfsr[1]});
                    end
                    else if (!blk13_active) begin
                        blk13_active <= 1'b1;
                        blk13_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[4], lfsr[3:2]});
                        blk13_y      <= ufo_y + START_Y_OFF;
                        blk13_vy     <= pick_speed({lfsr[4], lfsr[3]});
                    end
                    else if (!blk14_active) begin
                        blk14_active <= 1'b1;
                        blk14_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, {lfsr[6], lfsr[5:4]});
                        blk14_y      <= ufo_y + START_Y_OFF;
                        blk14_vy     <= pick_speed({lfsr[6], lfsr[5]});
                    end
                    else if (!blk15_active) begin
                        blk15_active <= 1'b1;
                        blk15_x      <= spawn_x_with_jitter(pattern_lane(active_pattern_id, pattern_step + 1'b1), ufo_x, lfsr[1:0]);
                        blk15_y      <= ufo_y + START_Y_OFF;
                        blk15_vy     <= pick_speed(lfsr[1:0]);
                    end
                end

                // advance pattern step or pick new pattern
                if (pattern_step >= pattern_len) begin
                    if (!hazard_pattern_override)
                        pattern_id <= lfsr[2:0] % 5;
                    pattern_step <= 2'd0;
                    pattern_len  <= 2'd3;
                end
                else begin
                    pattern_step <= pattern_step + 1'b1;
                end

                // timing logic
                if (hazard_burst_enable && (burst_left != 0)) begin
                    burst_left  <= burst_left - 1'b1;
                    spawn_timer <= 6'd2;
                end
                else if (hazard_burst_enable && (lfsr[7:5] == 3'b111)) begin
                    burst_left  <= 2'd3;
                    spawn_timer <= 6'd2;
                end
                else begin
                    spawn_timer <= pick_spawn_delay(lfsr[6:4]);
                end
            end
        end
    end

endmodule