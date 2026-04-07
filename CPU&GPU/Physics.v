`timescale 1ns / 1ps
module Physics #(
    parameter [9:0] HALF      = 10'd20,
    parameter [9:0] X_INIT    = 10'd320,
    parameter [9:0] GROUND_Y  = 10'd440,
    parameter [9:0] MOVE_STEP = 2,
    parameter integer JUMP_V0 = -15,
    parameter integer GRAVITY = 1
)(
    input  wire       pixel_clk,
    input  wire       game_over,
    input  wire       logic_tick,
    input  wire       btnL,
    input  wire       btnR,
    input  wire       btnU,
    input  wire       reset_btn,

    output reg  [9:0] player_x = X_INIT,
    output reg        moving   = 1'b0,
    output reg        in_air   = 1'b0,
    output reg  [9:0] player_y = GROUND_Y
);

    integer y_pos = GROUND_Y;
    integer vy    = 0;
    reg on_ground = 1'b1;

    integer x_next;
    integer y_next;
    integer vy_next;
    reg ground_next;
    reg moving_next;

    always @(posedge pixel_clk) begin
        if (reset_btn) begin
            player_x   <= X_INIT;
            y_pos      <= GROUND_Y;
            vy         <= 0;
            on_ground  <= 1'b1;
            player_y   <= GROUND_Y;
            moving     <= 1'b0;
            in_air     <= 1'b0;
        end
        else if (logic_tick && !game_over) begin
            // defaults
            x_next      = player_x;
            y_next      = y_pos;
            vy_next     = vy;
            ground_next = on_ground;
            moving_next = 1'b0;

            // ---- Horizontal movement ----
            if (btnL && !btnR) begin
                moving_next = 1'b1;
                if (player_x > (HALF + MOVE_STEP))
                    x_next = player_x - MOVE_STEP;
                else
                    x_next = HALF;
            end
            else if (btnR && !btnL) begin
                moving_next = 1'b1;
                if (player_x < (10'd639 - HALF - MOVE_STEP))
                    x_next = player_x + MOVE_STEP;
                else
                    x_next = (10'd639 - HALF);
            end

            // ---- Jump start ----
            if (ground_next && btnU) begin
                vy_next     = JUMP_V0;
                ground_next = 1'b0;
            end

            // ---- Vertical physics ----
            if (!ground_next) begin
                vy_next = vy_next + GRAVITY;
                y_next  = y_next + vy_next;

                if (y_next >= GROUND_Y) begin
                    y_next      = GROUND_Y;
                    vy_next     = 0;
                    ground_next = 1'b1;
                end
            end

            // ---- Commit state ----
            player_x  <= x_next[9:0];
            y_pos     <= y_next;
            vy        <= vy_next;
            on_ground <= ground_next;

            player_y  <= y_next[9:0];
            in_air    <= !ground_next;
            moving    <= moving_next;
        end
    end

endmodule