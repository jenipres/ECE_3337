`timescale 1ns / 1ps
module UFO #(
    parameter [9:0] UFO_Y = 10'd120,
    parameter [9:0] UFO_HALF_W = 10'd64   // 128-wide sprite => half width = 64
)(
    input  wire       pixel_clk,
    input  wire       game_tick,
    input  wire       reset,

    output reg  [9:0] ufo_x,
    output wire [9:0] ufo_y,

    output reg        drop_pulse,
    output reg  [9:0] drop_x,

    output reg  [9:0] fall_step,
    output reg  [9:0] side_step
);
    assign ufo_y = UFO_Y;

    // 16-bit LFSR
    reg [15:0] lfsr = 16'hACE1;
    wire fb = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

    // 5-second ramp (300 ticks @ 60Hz)
    reg [8:0] sec5_cnt = 9'd0;
    reg [3:0] lvl = 4'd0;

    // drop timer
    reg [9:0] drop_cnt = 10'd0;

    // normal travel direction
    reg dir = 1'b1; // 1=right, 0=left

    // burst movement
    reg       burst_active = 1'b0;
    reg       burst_dir    = 1'b0;   // 1=right, 0=left
    reg [3:0] burst_ticks  = 4'd0;

    function [9:0] drop_period;
    input [3:0] L;
    begin
        if (L >= 4'd12) drop_period = 10'd4;
        else if (L >= 4'd8) drop_period = 10'd6;
        else if (L >= 4'd4) drop_period = 10'd8;
        else drop_period = 10'd12;
    end
endfunction

    function [2:0] ufo_step;
        input [3:0] L;
        begin
            if (L >= 4'd10) ufo_step = 3'd6;
            else if (L >= 4'd6) ufo_step = 3'd5;
            else if (L >= 4'd3) ufo_step = 3'd4;
            else ufo_step = 3'd3;
        end
    endfunction

    function [3:0] burst_speed;
        input [3:0] L;
        begin
            if (L >= 4'd10) burst_speed = 4'd14;
            else if (L >= 4'd6) burst_speed = 4'd12;
            else burst_speed = 4'd10;
        end
    endfunction

    function [1:0] jitter_amt;
        input [1:0] r;
        begin
            case (r)
                2'b00: jitter_amt = 2'd0;
                2'b01: jitter_amt = 2'd1;
                2'b10: jitter_amt = 2'd2;
                default: jitter_amt = 2'd1;
            endcase
        end
    endfunction

    always @(posedge pixel_clk) begin
        if (reset) begin
            ufo_x <= 10'd200;
            dir <= 1'b1;
            lfsr <= 16'hACE1;

            sec5_cnt <= 9'd0;
            lvl <= 4'd0;

            drop_cnt <= 10'd0;
            drop_pulse <= 1'b0;
            drop_x <= 10'd200;

            fall_step <= 10'd6;
            side_step <= 10'd6;

            burst_active <= 1'b0;
            burst_dir    <= 1'b0;
            burst_ticks  <= 4'd0;
        end else begin
            drop_pulse <= 1'b0;

            if (game_tick) begin
                lfsr <= {lfsr[14:0], fb};

                // difficulty ramp
                if (sec5_cnt == 9'd299) begin
                    sec5_cnt <= 9'd0;
                    if (lvl != 4'hF) lvl <= lvl + 1'b1;
                end else begin
                    sec5_cnt <= sec5_cnt + 1'b1;
                end

                // exported step outputs for other hazards
                if (lvl >= 4'd10) fall_step <= 10'd16;
                else fall_step <= 10'd6 + {6'd0, lvl};

                if (lvl >= 4'd8) side_step <= 10'd16;
                else side_step <= 10'd8 + {6'd0, lvl};

                // -----------------------------------
                // Occasionally start a burst
                // -----------------------------------
                if (!burst_active && (lfsr[15:13] == 3'b111)) begin
                    burst_active <= 1'b1;
                    burst_dir    <= lfsr[0];
                    burst_ticks  <= 4'd4 + {2'd0, lfsr[2:1]}; // 4..7 ticks
                end

                // -----------------------------------
                // UFO movement
                // -----------------------------------
                if (burst_active) begin
                    if (burst_dir) begin
                        if (ufo_x + UFO_HALF_W + burst_speed(lvl) >= 10'd639) begin
                            ufo_x <= 10'd639 - UFO_HALF_W;
                            burst_active <= 1'b0;
                            dir <= 1'b0;
                        end else begin
                            ufo_x <= ufo_x + burst_speed(lvl);
                            if (burst_ticks == 0) burst_active <= 1'b0;
                            else burst_ticks <= burst_ticks - 1'b1;
                        end
                    end else begin
                        if (ufo_x <= UFO_HALF_W + burst_speed(lvl)) begin
                            ufo_x <= UFO_HALF_W;
                            burst_active <= 1'b0;
                            dir <= 1'b1;
                        end else begin
                            ufo_x <= ufo_x - burst_speed(lvl);
                            if (burst_ticks == 0) burst_active <= 1'b0;
                            else burst_ticks <= burst_ticks - 1'b1;
                        end
                    end
                end else begin
                    // normal sweep + tiny jitter
                    if (dir) begin
                        if (ufo_x + UFO_HALF_W + ufo_step(lvl) + jitter_amt(lfsr[1:0]) >= 10'd639) begin
                            dir <= 1'b0;
                            ufo_x <= 10'd639 - UFO_HALF_W;
                        end else begin
                            ufo_x <= ufo_x + ufo_step(lvl) + jitter_amt(lfsr[1:0]);
                        end
                    end else begin
                        if (ufo_x <= UFO_HALF_W + ufo_step(lvl) + jitter_amt(lfsr[3:2])) begin
                            dir <= 1'b1;
                            ufo_x <= UFO_HALF_W;
                        end else begin
                            ufo_x <= ufo_x - ufo_step(lvl) - jitter_amt(lfsr[3:2]);
                        end
                    end
                end

                // -----------------------------------
                // Drop timing
                // -----------------------------------
                if (drop_cnt >= drop_period(lvl) || burst_active) begin
                    drop_cnt <= 10'd0;

                    begin : DROP
                        reg signed [10:0] jitter;
                        reg signed [10:0] xcalc;

                        // drop around UFO center with +-32 jitter
                        jitter = $signed({1'b0, lfsr[5:0]}) - 11'sd32;
                        xcalc  = $signed({1'b0, ufo_x}) + jitter;

                        if (xcalc < 0) drop_x <= 10'd0;
                        else if (xcalc > 639) drop_x <= 10'd639;
                        else drop_x <= xcalc[9:0];
                    end

                    drop_pulse <= 1'b1;
                end else begin
                    drop_cnt <= drop_cnt + 1'b1;
                end
            end
        end
    end

endmodule