`timescale 1ns / 1ps

module score_system #(
    parameter integer FPS = 60,
    parameter integer MAX_SCORE = 9999
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       game_tick,
    input  wire       in_game,
    input  wire       game_over,

    output reg [13:0] live_score  = 14'd0,
    output reg [13:0] final_score = 14'd0
);

    reg [6:0] sec_count   = 7'd0;
    reg       game_over_d = 1'b0;

    wire death_pulse = game_over & ~game_over_d;

    always @(posedge clk) begin
        if (reset) begin
            sec_count   <= 7'd0;
            live_score  <= 14'd0;
            final_score <= 14'd0;
            game_over_d <= 1'b0;
        end
        else begin
            game_over_d <= game_over;

            // Reset live counter when not actively in GAME
            if (!in_game) begin
                sec_count  <= 7'd0;
                live_score <= 14'd0;
            end
            else if (game_tick && !game_over) begin
                if (sec_count == FPS - 1) begin
                    sec_count <= 7'd0;

                    if (live_score < MAX_SCORE)
                        live_score <= live_score + 14'd1;
                end
                else begin
                    sec_count <= sec_count + 7'd1;
                end
            end

            // Latch final score once on death edge
            if (death_pulse) begin
                final_score <= live_score;
            end
        end
    end

endmodule