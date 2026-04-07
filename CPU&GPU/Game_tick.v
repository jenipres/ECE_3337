`timescale 1ns / 1ps
module Game_tick #(
    parameter integer UPDATE_DIV = 4   // 1=60Hz, 2=30Hz, 4=15Hz, etc.
)(
    input  wire pixel_clk,     // 25 MHz
    input  wire new_frame,      // 1 pulse per VGA frame
    output reg  game_tick = 1'b0
);

    reg [3:0] frame_cnt = 0;

    always @(posedge pixel_clk) begin
        game_tick <= 1'b0;   // default

        if (new_frame) begin
            if (frame_cnt == UPDATE_DIV-1) begin
                frame_cnt <= 0;
                game_tick <= 1'b1;  // ? GAME UPDATE PULSE
            end else begin
                frame_cnt <= frame_cnt + 1;
            end
        end
    end

endmodule

