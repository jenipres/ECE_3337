`timescale 1ns / 1ps

module Anim_Pose #(
    parameter integer TOGGLE_TICKS = 3
)(
    input  wire       pixel_clk,
    input  wire       game_tick,
    input  wire       reset_btn,
    input  wire       moving,
    input  wire       in_air,
    input  wire       crouch,
    output reg  [2:0] pose = 3'b000
);

    reg walk_phase = 1'b0;
    integer cnt = 0;

    localparam [2:0] IDLE   = 3'b000;
    localparam [2:0] WALK_A = 3'b001;
    localparam [2:0] WALK_B = 3'b010;
    localparam [2:0] JUMP   = 3'b011;
    localparam [2:0] CROUCH = 3'b100;

    always @(posedge pixel_clk) begin
        if (reset_btn) begin
            cnt        <= 0;
            walk_phase <= 1'b0;
            pose       <= IDLE;
        end else if (game_tick) begin
            if (in_air) begin
                pose       <= JUMP;
                cnt        <= 0;
                walk_phase <= 1'b0;
            end else if (crouch) begin
                pose       <= CROUCH;
                cnt        <= 0;
                walk_phase <= 1'b0;
            end else if (moving) begin
                if (cnt >= (TOGGLE_TICKS-1)) begin
                    cnt        <= 0;
                    walk_phase <= ~walk_phase;
                end else begin
                    cnt <= cnt + 1;
                end

                pose <= (walk_phase ? WALK_B : WALK_A);
            end else begin
                pose       <= IDLE;
                cnt        <= 0;
                walk_phase <= 1'b0;
            end
        end
    end

endmodule